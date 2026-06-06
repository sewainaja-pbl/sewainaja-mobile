import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'image_upload_service.dart';
import 'upload_image_policy.dart';
import 'dispute_form_screen.dart';

class ReturnEvidenceScreen extends StatefulWidget {
  final String? transactionId;
  final String? itemName;
  const ReturnEvidenceScreen({super.key, this.transactionId, this.itemName});

  @override
  State<ReturnEvidenceScreen> createState() => _ReturnEvidenceScreenState();
}

class _ReturnEvidenceScreenState extends State<ReturnEvidenceScreen> {
  final List<ProcessedImageFile> _selectedImages = [];
  final ImageUploadService _imageService = ImageUploadService();
  final int _maxPhotos = 10;
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  Future<void> _pickImages() async {
    final remainingSlots = _maxPhotos - _selectedImages.length;
    if (remainingSlots <= 0) return;

    try {
      final sourceChoice = await _imageService.chooseImageSource(context);
      if (sourceChoice == null) return;

      if (sourceChoice == ImageSourceChoice.camera) {
        final picked = await _imageService.pickSingleImageFromSource(
          policy: UploadImagePolicy.product,
          source: ImageSource.camera,
        );
        if (picked == null || !mounted) return;
        setState(() {
          _selectedImages.add(picked);
        });
        return;
      }

      final picked = await _imageService.pickMultipleImages(
        policy: UploadImagePolicy.product,
        remainingSlots: remainingSlots,
      );
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _selectedImages.addAll(picked.take(remainingSlots));
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
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap unggah minimal 1 foto bukti kondisi barang.')),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap berikan rating untuk pemilik barang.')),
      );
      return;
    }

    if (_rating <= 2) {
      _showDisputeRecommendationDialog();
    } else {
      _executeSubmit();
    }
  }

  void _executeSubmit() {
    // Tampilkan pesan sukses dan kembali ke awal (misalnya layar beranda)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bukti pengembalian dan rating berhasil dikirim!')),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
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
                            transactionId: widget.transactionId ?? 'dummy_trans_123',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFDF9F4),
        centerTitle: true,
        title: const Text(
          'Serah Terima',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4332),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFC1C8C2),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFC107), width: 1),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 16),
                          SizedBox(height: 2),
                          Text(
                            'DUMMY\n(NO API)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF856404),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemName ?? 'Sony Camera a6000',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pemilik: Han so Hee',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const Text(
                          '8 Jan - 10 Jan 2025',
                          style: TextStyle(
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
                    'Kirimkan bukti kondisi barang setelah peminjaman',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload Foto',
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
                                Icons.add,
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF0000), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Foto wajib diunggah setelah transaksi selesai. Foto ini akan menjadi bukti sah jika terdapat klaim kerusakan di akhir masa sewa',
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
              onTap: _submitData,
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
    );
  }
}
