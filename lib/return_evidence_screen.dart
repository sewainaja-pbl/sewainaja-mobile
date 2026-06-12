import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'image_upload_service.dart';
import 'upload_image_policy.dart';
import 'dispute_form_screen.dart';
import 'api_config.dart';
import 'auth_session_service.dart';
import 'main_navigation_screen.dart';

class ReturnEvidenceScreen extends StatefulWidget {
  final String? transactionId;
  final String? itemName;
  final bool isForced;
  final bool isRoot;
  const ReturnEvidenceScreen({
    super.key,
    this.transactionId,
    this.itemName,
    this.isForced = true,
    this.isRoot = false,
  });

  @override
  State<ReturnEvidenceScreen> createState() => _ReturnEvidenceScreenState();
}

class _ReturnEvidenceScreenState extends State<ReturnEvidenceScreen> {
  final List<ProcessedImageFile> _selectedImages = [];
  Map<String, dynamic>? _transactionData;
  List<dynamic> _details = [];
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _savePendingRatingState();
    _fetchTransactionDetails();
  }

  Future<void> _savePendingRatingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_rating_id', widget.transactionId ?? '');
      await prefs.setString('pending_rating_item_name', widget.itemName ?? '');
      await prefs.setString('pending_rating_role', 'renter');
    } catch (e) {
      debugPrint('Error saving pending rating state: $e');
    }
  }

  Future<void> _clearPendingRatingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_rating_id');
      await prefs.remove('pending_rating_item_name');
      await prefs.remove('pending_rating_role');
    } catch (e) {
      debugPrint('Error clearing pending rating state: $e');
    }
  }

  Future<void> _fetchTransactionDetails() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) return;

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _transactionData = body['data'] as Map<String, dynamic>;
            _details = _transactionData!['details'] as List? ?? [];
          });
          return;
        }
      }
    } catch (_) {
      // Keep mock values if request fails
    }
  }

  String _formatDateRange() {
    if (_details.isEmpty) return '8 Jan - 10 Jan 2025';
    final detail = _details[0];
    final start = detail['startDate'];
    final end = detail['endDate'];
    if (start == null || end == null) return '8 Jan - 10 Jan 2025';
    
    final sDt = _parseTimestamp(start);
    final eDt = _parseTimestamp(end);
    if (sDt == null || eDt == null) return '8 Jan - 10 Jan 2025';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${sDt.day} ${months[sDt.month - 1]} - ${eDt.day} ${months[eDt.month - 1]} ${eDt.year}';
  }

  DateTime? _parseTimestamp(dynamic ts) {
    if (ts == null) return null;
    if (ts is Map) {
      final sec = ts['_seconds'] ?? ts['seconds'];
      if (sec is int) {
        return DateTime.fromMillisecondsSinceEpoch(sec * 1000).toLocal();
      }
    } else if (ts is String) {
      return DateTime.tryParse(ts)?.toLocal();
    }
    return null;
  }

  ImageProvider _getImageProvider() {
    if (_details.isNotEmpty) {
      final url = _details[0]['itemPhotoUrlSnapshot']?.toString();
      if (url != null && url.isNotEmpty) {
        if (url.startsWith('http')) {
          return NetworkImage(url);
        } else if (url.startsWith('assets/')) {
          return AssetImage(url);
        }
      }
    }
    return const AssetImage('assets/images/Iklan.jpg');
  }
  final ImageUploadService _imageService = ImageUploadService();
  final int _maxPhotos = 10;
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    final remainingSlots = _maxPhotos - _selectedImages.length;
    if (remainingSlots <= 0) return;

    try {
      // Kamera saja (Camera Only) untuk validasi keaslian
      final picked = await _imageService.pickSingleImageFromSource(
        policy: UploadImagePolicy.product,
        source: ImageSource.camera,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _selectedImages.add(picked);
      });
    } catch (error) {
      debugPrint('Error picking image: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(safeImageError(error))),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitData() {
    // Validasi minimal 2 foto bukti kondisi barang setelah sewa
    if (_selectedImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap unggah minimal 2 foto bukti kondisi barang (tampak keseluruhan dan detail).'),
          backgroundColor: Color(0xFFF04438),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap berikan rating untuk pemilik barang.'),
          backgroundColor: Color(0xFFF04438),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_rating <= 2) {
      _showDisputeRecommendationDialog();
    } else {
      _executeSubmit();
    }
  }

  Future<void> _executeSubmit() async {
    final tId = widget.transactionId;

    if (tId == null || tId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Transaksi tidak valid.'),
          backgroundColor: Color(0xFFF04438),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B4332)),
      ),
    );

    try {
      final idToken = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      };

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // 1. Upload semua foto ke Storage & kirim ke API evidences (type: 'after')
      for (int i = 0; i < _selectedImages.length; i++) {
        final storagePath = 'transactions/$tId/evidences/after_${timestamp}_$i.jpg';
        final downloadUrl = await _imageService.uploadProcessedImage(
          processed: _selectedImages[i],
          storagePath: storagePath,
        );

        final evidenceResp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/transactions/$tId/evidences'),
          headers: headers,
          body: jsonEncode({
            'type': 'after',
            'mediaUrl': downloadUrl,
            'mediaType': 'photo',
          }),
        );

        if (evidenceResp.statusCode != 200) {
          final body = jsonDecode(evidenceResp.body);
          throw Exception(body['error']?['message'] ?? body['message'] ?? 'Gagal mengunggah foto bukti pengembalian ke API.');
        }
      }

      // 2. Kirim rating ke API
      final ratingResp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/ratings'),
        headers: headers,
        body: jsonEncode({
          'transactionId': tId,
          'ratedAs': 'owner',
          'score': _rating,
          'comment': _reviewController.text.trim(),
        }),
      );

      // Tutup loading dialog
      if (mounted) Navigator.pop(context);

      if (ratingResp.statusCode == 200) {
        final ratingBody = jsonDecode(ratingResp.body);
        if (ratingBody['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bukti pengembalian dan rating berhasil dikirim!'),
                backgroundColor: Color(0xFF1B4332),
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() {
              _canPop = true;
            });
            await _clearPendingRatingState();
            if (mounted) {
              if (widget.isRoot) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                );
              } else {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            }
          }
        } else {
          throw Exception(ratingBody['error']?['message'] ?? ratingBody['message'] ?? 'Gagal mengirim rating.');
        }
      } else {
        final ratingBody = jsonDecode(ratingResp.body);
        throw Exception(ratingBody['error']?['message'] ?? ratingBody['message'] ?? 'Gagal mengirim rating.');
      }
    } catch (e) {
      // Tutup loading dialog jika masih tampil
      if (mounted && _isSubmitting) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: const Color(0xFFF04438),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showDisputeRecommendationDialog() {
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
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF4DB),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.gpp_maybe,
                      color: Color(0xFF9A6700),
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kendala Transaksi?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012D1D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Apakah Anda mengalami kendala fisik/finansial yang serius dengan barang ini? Anda dapat mengajukan sengketa resmi agar admin kami membantu mediasi.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF5C635E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisputeFormScreen(
                            transactionId: widget.transactionId ?? '',
                            category: 'checkout_damage',
                            itemName: widget.itemName ?? 'Sony Camera a6000',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF012D1D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Ajukan Sengketa Resmi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      _executeSubmit(); // proceed with normal submit
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF012D1D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF012D1D), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Kirim Rating Saja',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Keluar dari Halaman?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Color(0xFF012D1D),
          ),
        ),
        content: const Text(
          'Anda belum menyelesaikan pengisian bukti serah terima/pengembalian dan rating. Jika Anda keluar sekarang, data bukti sewa Anda tidak akan tersimpan secara lengkap. Yakin ingin keluar?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF414844),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4332),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Keluar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isForced ? false : _canPop,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (widget.isForced) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda wajib memberikan rating untuk menyelesaikan transaksi.'),
              backgroundColor: Color(0xFFF04438),
            ),
          );
          return;
        }
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop) {
          setState(() {
            _canPop = true;
          });
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF9F4),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFDF9F4),
          centerTitle: true,
          automaticallyImplyLeading: !widget.isForced,
          title: const Text(
            'Serah Terima',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4332),
            ),
          ),
          leading: widget.isForced
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
                  onPressed: () => Navigator.pop(context),
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF012D1D)),
              onPressed: _fetchTransactionDetails,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: const Color(0xFFC1C8C2),
              height: 1.0,
            ),
          ),
        ),
      body: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF012D1D)),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. RENTAL ITEM CARD ---
                  Container(
                    margin: const EdgeInsets.only(top: 24.0, left: 20.0, right: 20.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            final imageUrl = _details.isNotEmpty ? _details[0]['itemPhotoUrlSnapshot']?.toString() : null;
                            final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.grey.shade200,
                                image: hasImage
                                    ? DecorationImage(
                                        image: imageUrl.startsWith('http')
                                            ? NetworkImage(imageUrl)
                                            : AssetImage(imageUrl) as ImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: !hasImage
                                  ? const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFF828282),
                                        size: 24,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Row(
                                 children: [
                                   Expanded(
                                     child: Text(
                                       _details.isNotEmpty
                                           ? _details[0]['itemNameSnapshot']?.toString() ?? widget.itemName ?? 'Barang Sewaan'
                                           : widget.itemName ?? 'Sony Camera a6000',
                                       style: const TextStyle(
                                         fontFamily: 'Poppins',
                                         fontSize: 16,
                                         fontWeight: FontWeight.w600,
                                         color: Color(0xFF414844),
                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                              const SizedBox(height: 6),
                              Text(
                                _transactionData != null
                                    ? 'Pemilik: ${_transactionData!['ownerName'] ?? 'Owner'}'
                                    : 'Pemilik: Han so Hee',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF414844),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDateRange(),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF414844),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- 2. UPLOAD GALLERY SECTION (MAX 10) ---
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0, left: 20.0, right: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kirimkan bukti kondisi barang setelah peminjaman. Wajib ambil minimal 2 foto (1 tampak keseluruhan, 1 tampak detail/close-up).',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF000000),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Upload Foto (Kamera Saja)',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(26.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Wrap(
                            spacing: 12.0,
                            runSpacing: 12.0,
                            children: [
                              ...List.generate(_selectedImages.length, (index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(11.0),
                                      child: kIsWeb
                                          ? Image.network(
                                              _selectedImages[index].localPath,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(_selectedImages[index].localPath),
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              if (_selectedImages.length < 10)
                                GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(11.0),
                                      border: Border.all(color: const Color(0xFF1B4332), width: 1.0),
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: Color(0xFF012D1D),
                                      size: 28,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- 3. RATING SECTION ---
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0, left: 20.0, right: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rating Pemilik',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rating = index + 1;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 40,
                                        color: index < _rating ? const Color(0xFFF8BD00) : const Color(0xFFEFEFEF),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEFEF),
                                  borderRadius: BorderRadius.circular(11.0),
                                ),
                                child: TextField(
                                  controller: _reviewController,
                                  minLines: 5,
                                  maxLines: 8,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Color(0xFF000000),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Berikan ulasan anda disini...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF717973),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- 4. WARNING BANNER ---
                  Container(
                    margin: const EdgeInsets.only(top: 32.0, bottom: 24.0, left: 20.0, right: 20.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      border: Border.all(color: const Color(0xFFFF0000), width: 1.0),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFF0000), size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Foto wajib diambil menggunakan kamera langsung di lokasi serah terima. Foto ini akan menjadi bukti sah jika terdapat klaim kerusakan di akhir masa sewa.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF000000),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- 5. SUBMIT BUTTON ---
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submitData,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8.0, bottom: 40.0, left: 20.0, right: 20.0),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF012D1D),
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                      child: const Center(
                        child: Text(
                          'Konfirmasi',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFDF9F4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
