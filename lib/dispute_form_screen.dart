import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_config.dart';
import 'app_feedback.dart';
import 'auth_session_service.dart';
import 'image_upload_service.dart';
import 'upload_image_policy.dart';
import 'widgets/custom_app_bar.dart';

class DisputeFormScreen extends StatefulWidget {
  final String transactionId;
  final String category; // 'handover_rejection' | 'ongoing_damage' | 'checkout_damage'
  final String itemName;
  final String? disputeId; // Optional parameter for rebuttal/sanggahan mode

  const DisputeFormScreen({
    super.key,
    required this.transactionId,
    required this.category,
    required this.itemName,
    this.disputeId,
  });

  @override
  State<DisputeFormScreen> createState() => _DisputeFormScreenState();
}

class _DisputeFormScreenState extends State<DisputeFormScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImageUploadService _imageService = ImageUploadService();
  final List<ProcessedImageFile> _selectedImages = [];
  final int _maxPhotos = 3;

  bool _isDisclaimerAccepted = false;
  bool _isCheckboxChecked = false;
  bool _isSubmitting = false;

  String get _categoryLabel {
    switch (widget.category) {
      case 'handover_rejection':
        return 'Masalah Serah Terima Awal (COD)';
      case 'ongoing_damage':
        return 'Kerusakan Selama Masa Sewa';
      case 'checkout_damage':
        return 'Kerusakan/Kehilangan Pengembalian';
      default:
        return 'Lainnya';
    }
  }

  Future<void> _pickImage() async {
    final remainingSlots = _maxPhotos - _selectedImages.length;
    if (remainingSlots <= 0) return;

    try {
      final sourceChoice = await _imageService.chooseImageSource(context);
      if (sourceChoice == null) return;

      if (sourceChoice == ImageSourceChoice.camera) {
        final picked = await _imageService.pickSingleImageFromSource(
          policy: UploadImagePolicy.dispute,
          source: ImageSource.camera,
        );
        if (picked == null || !mounted) return;
        setState(() {
          _selectedImages.add(picked);
        });
        return;
      }

      final picked = await _imageService.pickMultipleImages(
        policy: UploadImagePolicy.dispute,
        remainingSlots: remainingSlots,
      );
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _selectedImages.addAll(picked.take(remainingSlots));
      });
    } catch (e) {
      showAppErrorSnack(context, 'Gagal memilih gambar.');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitDispute() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      showAppErrorSnack(context, 'Harap tuliskan kronologi kejadian.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await const AuthSessionService().getValidIdToken();
      if (token == null || token.isEmpty) {
        showAppErrorSnack(context, 'Sesi login tidak valid. Silakan login ulang.');
        setState(() => _isSubmitting = false);
        return;
      }

      // Upload all selected images ke Cloudinary via backend
      List<String> uploadedPhotoUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        try {
          final url = await _imageService.uploadProcessedImage(
            processed: _selectedImages[i],
            kind: 'dispute',
          );
          uploadedPhotoUrls.add(url);
        } catch (_) {
          // Lanjutkan meski salah satu foto gagal upload
        }
      }

      final isRebuttal = widget.disputeId != null;
      final url = isRebuttal
          ? '${ApiConfig.baseUrl}/disputes/${widget.disputeId}/respond'
          : '${ApiConfig.baseUrl}/disputes';

      final bodyData = isRebuttal
          ? {
              'description': description,
              'evidenceUrls': uploadedPhotoUrls,
            }
          : {
              'transactionId': widget.transactionId,
              'description': description,
              'category': widget.category,
              'evidenceUrls': uploadedPhotoUrls,
              'evidenceUrl': uploadedPhotoUrls.isNotEmpty ? uploadedPhotoUrls.first : null, // keep legacy field just in case
            };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyData),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        final errorMsg = body['error']?['message'] ?? 'Gagal memproses laporan.';
        if (!mounted) return;
        showAppErrorSnack(context, errorMsg);
      }
    } catch (e) {
      if (mounted) {
        showAppErrorSnack(context, 'Terjadi kesalahan koneksi.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green check icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCDE2D6),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF012D1D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.disputeId != null ? 'Sanggahan Terkirim!' : 'Sengketa Diajukan!',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012D1D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.disputeId != null
                      ? 'Sanggahan dan bukti Anda telah diterima. Admin akan segera meninjau argumen dari kedua belah pihak.'
                      : 'Laporan Anda telah diterima. Transaksi saat ini ditangguhkan dan dana sewa akan ditahan sementara hingga mediasi Admin selesai.',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF717973),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Pop dialog
                      Navigator.pop(context, true); // Pop form screen with success flag
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF012D1D),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kembali ke Detail',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: CustomAppBar(
        title: widget.disputeId != null ? 'Kirim Sanggahan' : 'Ajukan Sengketa',
      ),
      body: !_isDisclaimerAccepted ? _buildDisclaimerView() : _buildFormView(),
    );
  }

  Widget _buildDisclaimerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE2DCD3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: Color(0xFF7B5804),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Disclaimer Mediasi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SewainAja bertindak sebagai penengah independen untuk menahan dana sewa sementara. Kami akan mengambil keputusan berdasarkan bukti foto/video serah-terima (evidence check-in & check-out) yang diunggah di aplikasi.\n\nKeputusan admin hanya berlaku untuk alokasi dana di aplikasi. Jika Anda ingin menempuh jalur hukum resmi, riwayat detail transaksi ini dapat diunduh sebagai bukti sah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.6,
                    color: Color(0xFF414844),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _isCheckboxChecked,
                activeColor: const Color(0xFF012D1D),
                onChanged: (val) {
                  setState(() {
                    _isCheckboxChecked = val ?? false;
                  });
                },
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Saya memahami dan menyetujui ketentuan mediasi SewainAja.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF5C635E),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isCheckboxChecked
                ? () {
                    setState(() {
                      _isDisclaimerAccepted = true;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF012D1D),
              disabledBackgroundColor: const Color(0xFFC1C8C2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Setujui & Lanjutkan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BARANG SENGSARA / TRANSAKSI',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF717973),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.itemName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Jenis Sengketa: $_categoryLabel',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7B5804),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Kronologi Field
          Text(
            widget.disputeId != null ? 'Kronologi Sanggahan Anda' : 'Kronologi Kejadian',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6ECE8)),
            ),
            child: TextField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF012D1D),
              ),
              decoration: InputDecoration(
                hintText: widget.disputeId != null
                    ? 'Ceritakan alasan/sanggahan Anda secara lengkap dan jujur...'
                    : 'Ceritakan kronologi masalah secara lengkap dan jujur...',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF717973),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Upload Bukti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Unggah Bukti Foto',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF012D1D),
                ),
              ),
              Text(
                'Maks $_maxPhotos Foto',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7B5804),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE6ECE8)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...List.generate(_selectedImages.length, (index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImages[index].localPath),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_selectedImages.length < _maxPhotos)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF012D1D), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitDispute,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF012D1D),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.disputeId != null ? 'Kirim Sanggahan' : 'Kirim Laporan Sengketa',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
