import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_config.dart';
import 'app_feedback.dart';
import 'auth_session_service.dart';
import 'image_upload_service.dart';
import 'upload_image_policy.dart';
import 'widgets/custom_app_bar.dart';
import 'profile_sync_service.dart';

class KtpUploadScreen extends StatefulWidget {
  final VoidCallback? onVerificationCompleted;
  const KtpUploadScreen({super.key, this.onVerificationCompleted});

  @override
  State<KtpUploadScreen> createState() => _KtpUploadScreenState();
}

class _KtpUploadScreenState extends State<KtpUploadScreen> {
  final ImageUploadService _imageUploadService = ImageUploadService();
  final AuthSessionService _authSessionService = const AuthSessionService();
  final ProfileSyncService _profileSyncService = const ProfileSyncService();

  int _currentStep = 0; // 0: Onboarding, 1: Capture, 2: Under Review
  ProcessedImageFile? _ktpFile;
  ProcessedImageFile? _selfieFile;
  bool _isSubmitting = false;
  String _userStatus = 'unverified';
  String _rejectionReason = '';

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    try {
      final cached = await _profileSyncService.readCachedProfile();
      if (mounted) {
        setState(() {
          _userStatus = cached.status.toLowerCase();
          _rejectionReason = cached.rejectionReason;
          if (_userStatus == 'pending') {
            _currentStep = 2; // Jump to under review if already submitted
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickKtpPhoto() async {
    try {
      final choice = await _imageUploadService.chooseImageSource(context);
      if (choice == null) return;
      final picked = await _imageUploadService.pickSingleImageFromSource(
        policy: UploadImagePolicy.kyc,
        source: choice == ImageSourceChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _ktpFile = picked;
      });
    } catch (e) {
      if (mounted) {
        showAppErrorSnack(context, 'Gagal mengambil foto KTP: ${e.toString()}');
      }
    }
  }

  Future<void> _pickSelfiePhoto() async {
    try {
      final choice = await _imageUploadService.chooseImageSource(context);
      if (choice == null) return;
      final picked = await _imageUploadService.pickSingleImageFromSource(
        policy: UploadImagePolicy.kyc,
        source: choice == ImageSourceChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _selfieFile = picked;
      });
    } catch (e) {
      if (mounted) {
        showAppErrorSnack(context, 'Gagal mengambil foto selfie: ${e.toString()}');
      }
    }
  }

  Future<void> _submitVerification() async {
    if (_ktpFile == null || _selfieFile == null) {
      showAppErrorSnack(context, 'Harap unggah kedua foto (KTP & Selfie)');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _authSessionService.getValidIdToken(forceRefresh: true);
      final cached = await _profileSyncService.readCachedProfile();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';

      // 1. Upload KTP Photo
      String ktpUrl = '';
      try {
        ktpUrl = await _imageUploadService.uploadProcessedImage(
          processed: _ktpFile!,
          storagePath: 'users/$currentUserId/kyc/ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (uploadError) {
        if (!kDebugMode) {
          rethrow;
        }
        debugPrint('Firebase Storage upload failed: $uploadError. Using mock URL for dev.');
        ktpUrl = 'https://mock.storage/users/$currentUserId/kyc/ktp.jpg';
      }

      // 2. Upload Selfie Photo
      String selfieUrl = '';
      try {
        selfieUrl = await _imageUploadService.uploadProcessedImage(
          processed: _selfieFile!,
          storagePath: 'users/$currentUserId/kyc/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (uploadError) {
        if (!kDebugMode) {
          rethrow;
        }
        debugPrint('Firebase Storage upload failed: $uploadError. Using mock URL for dev.');
        selfieUrl = 'https://mock.storage/users/$currentUserId/kyc/selfie.jpg';
      }

      // 3. Post to `/auth/upload-kyc` API
      if (token != null && token.isNotEmpty) {
        try {
          http.Response? response;
          int retryCount = 0;
          while (retryCount < 3) {
            try {
              response = await http.post(
                Uri.parse('${ApiConfig.baseUrl}/auth/upload-kyc'),
                headers: {
                  'Content-Type': 'application/json',
                  'Connection': 'close',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                  'ktpPhotoUrl': ktpUrl,
                  'selfiePhotoUrl': selfieUrl,
                }),
              );
              break;
            } catch (e) {
              retryCount++;
              if (retryCount >= 3) {
                rethrow;
              }
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            }
          }
          
          if (response == null || (response.statusCode != 200 && response.statusCode != 201)) {
            throw Exception('Gagal menyimpan berkas KYC ke server (Status ${response?.statusCode}).');
          }
          debugPrint('KYC upload status response: ${response.statusCode}');
        } catch (apiError) {
          if (!kDebugMode) {
            rethrow;
          }
          debugPrint('Backend KYC upload endpoint failed: $apiError. Proceeding with simulated status update.');
        }
      }

      // 4. Update local profile status to pending
      final updatedProfile = CachedUserProfile(
        name: cached.name,
        email: cached.email,
        phone: cached.phone,
        profilePhotoUrl: cached.profilePhotoUrl,
        status: 'pending',
      );
      await _profileSyncService.saveProfileToCache(updatedProfile, notify: true);

      // Also set SharedPreferences manually
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_status', 'pending');

      if (mounted) {
        setState(() {
          _userStatus = 'pending';
          _currentStep = 2;
        });
        showAppSuccessSnack(context, 'Dokumen KYC berhasil dikirim ke Admin!');
      }
    } catch (e) {
      if (mounted) {
        showAppErrorSnack(context, 'Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: const CustomAppBar(
        title: 'Verifikasi KTP (KYC)',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_userStatus == 'rejected') {
      return _buildRejectedStep();
    }
    if (_currentStep == 0) {
      return _buildOnboardingStep();
    } else if (_currentStep == 1) {
      return _buildCaptureStep();
    } else {
      return _buildUnderReviewStep();
    }
  }

  Widget _buildRejectedStep() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Verifikasi Ditolak',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mohon maaf, berkas KYC yang Anda unggah sebelumnya ditolak oleh admin SewainAja. Silakan periksa alasan penolakan di bawah ini dan unggah ulang berkas Anda.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF5C635E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          // Rejection Reason Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF5B7B1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFB42318), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ALASAN PENOLAKAN ADMIN',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB42318),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _rejectionReason.isNotEmpty 
                      ? _rejectionReason 
                      : 'Berkas KTP atau Selfie yang diunggah tidak jelas atau tidak sesuai ketentuan.',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7B241C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Start Re-verification Button
          GestureDetector(
            onTap: () {
              setState(() {
                _userStatus = 'unverified';
                _currentStep = 1; // Direct to capture step
              });
            },
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF012D1D),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF012D1D).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Mulai Verifikasi Ulang',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Close Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF012D1D)),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text(
                  'Kembali ke Menu Utama',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF012D1D),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- STEP 0: ONBOARDING ---
  Widget _buildOnboardingStep() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Kenapa Harus Verifikasi?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SewainAja adalah komunitas rental tepercaya. Verifikasi identitas Anda diperlukan demi keamanan bersama sebelum Anda menyewa atau memposting barang.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF5C635E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          // Checklist requirements
          _buildRequirementRow(
            icon: Icons.credit_card_rounded,
            title: 'Foto KTP Asli',
            desc: 'Siapkan KTP fisik Anda. Pastikan foto dan teks terbaca jelas, tidak buram, dan tidak terpotong.',
          ),
          const SizedBox(height: 20),
          _buildRequirementRow(
            icon: Icons.face_rounded,
            title: 'Foto Selfie',
            desc: 'Ambil foto wajah Anda sendiri (Selfie) untuk dicocokkan dengan foto pada KTP Anda.',
          ),
          const SizedBox(height: 20),
          _buildRequirementRow(
            icon: Icons.gpp_good_rounded,
            title: 'Data Anda Terjamin',
            desc: 'Informasi KTP Anda dienkripsi secara aman dan hanya digunakan untuk proses validasi akun oleh admin.',
          ),
          
          const SizedBox(height: 32),
          
          // Action Button
          GestureDetector(
            onTap: () {
              setState(() {
                _currentStep = 1;
              });
            },
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF012D1D),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF012D1D).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Mulai Verifikasi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRequirementRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFC1ECD4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF012D1D),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B4332),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF717973),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- STEP 1: CAPTURE ---
  Widget _buildCaptureStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unggah Dokumen Anda',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 16),
        
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KTP Card Selector
                const Text(
                  '1. Foto KTP Asli',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickKtpPhoto,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _ktpFile != null ? const Color(0xFF1B4332) : const Color(0xFFC1C8C2),
                        width: _ktpFile != null ? 2 : 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _ktpFile != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image(
                                  image: _imageUploadService.buildProcessedImageProvider(_ktpFile!),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _ktpFile = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.credit_card_rounded,
                                    size: 40,
                                    color: const Color(0xFF012D1D).withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Posisikan KTP di sini',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF012D1D),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Ketuk untuk membuka kamera/galeri',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Color(0xFF717973),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 2. Selfie Face Selector
                const Text(
                  '2. Foto Selfie Anda',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickSelfiePhoto,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selfieFile != null ? const Color(0xFF1B4332) : const Color(0xFFC1C8C2),
                        width: _selfieFile != null ? 2 : 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _selfieFile != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image(
                                  image: _imageUploadService.buildProcessedImageProvider(_selfieFile!),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selfieFile = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.face_rounded,
                                    size: 40,
                                    color: const Color(0xFF012D1D).withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Ambil Foto Selfie',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF012D1D),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Posisikan wajah Anda tegak lurus',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Color(0xFF717973),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        
        // Action Button: Submit Verification
        GestureDetector(
          onTap: (_isSubmitting || _ktpFile == null || _selfieFile == null)
              ? null
              : _submitVerification,
          child: Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: (_ktpFile != null && _selfieFile != null)
                  ? const Color(0xFF012D1D)
                  : const Color(0xFFC1C8C2),
              borderRadius: BorderRadius.circular(28),
              boxShadow: (_ktpFile != null && _selfieFile != null)
                  ? [
                      BoxShadow(
                        color: const Color(0xFF012D1D).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Kirim Verifikasi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- STEP 2: UNDER REVIEW ---
  Widget _buildUnderReviewStep() {
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            
            // Large Clock/Review Icon
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4DB),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF9A6700),
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dalam Proses Peninjauan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF012D1D),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Berkas verifikasi KTP Anda berhasil dikirim ke Admin SewainAja. Proses pemeriksaan memakan waktu maksimal 1x24 jam.\nKami akan mengirimkan notifikasi setelah status akun Anda diperbarui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF5C635E),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Close Button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF012D1D)),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text(
                    'Kembali ke Menu Utama',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
