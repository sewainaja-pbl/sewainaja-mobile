import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'rental_deadline_screen.dart';
import 'image_upload_service.dart';
import 'upload_image_policy.dart';

class UploadEvidenceScreen extends StatefulWidget {
  final Map<String, String> itemData;

  const UploadEvidenceScreen({super.key, required this.itemData});

  @override
  State<UploadEvidenceScreen> createState() => _UploadEvidenceScreenState();
}

class _UploadEvidenceScreenState extends State<UploadEvidenceScreen> {
  final List<ProcessedImageFile> _photos = [];
  final ImageUploadService _imageUploadService = ImageUploadService();
  final int _maxPhotos = 10;

  Future<void> _pickImage() async {
    final remainingSlots = _maxPhotos - _photos.length;
    if (remainingSlots <= 0) return;

    try {
      final sourceChoice = await _imageUploadService.chooseImageSource(context);
      if (sourceChoice == null) return;

      if (sourceChoice == ImageSourceChoice.camera) {
        final picked = await _imageUploadService.pickSingleImageFromSource(
          policy: UploadImagePolicy.product, // Reuse product policy for image compression constraints
          source: ImageSource.camera,
        );
        if (picked == null || !mounted) return;
        setState(() {
          _photos.add(picked);
        });
        return;
      }

      final picked = await _imageUploadService.pickMultipleImages(
        policy: UploadImagePolicy.product,
        remainingSlots: remainingSlots,
      );
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _photos.addAll(picked.take(remainingSlots));
      });
    } catch (error) {
      debugPrint('Error picking image: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(safeImageError(error))),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _submit() {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap unggah minimal 1 foto bukti kondisi barang.'),
          backgroundColor: Color(0xFFF04438),
        ),
      );
      return;
    }

    // Tampilkan snackbar sukses
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bukti berhasil diunggah! Masa sewa telah dimulai.'),
        backgroundColor: Color(0xFF1B4332),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Lanjut ke RentalDeadlineScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RentalDeadlineScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF012D1D),
          ),
        ),
        title: const Text(
          'Serah Terima',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26, // Disesuaikan agar pas di layar
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4332),
          ),
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
            const SizedBox(height: 24),
            
            // 1. RENTAL ITEM CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.asset(
                      widget.itemData['image'] ?? 'assets/images/camera_sony.jpg',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemData['title'] ?? 'Sony Camera a6000',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.itemData['owner'] ?? 'Pemilik: Han so Hee',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.itemData['date'] ?? '8 Jan - 10 Jan 2025',
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

            const SizedBox(height: 32),

            // 2. UPLOAD GALLERY SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload Foto',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: [
                        // List Photos
                        ...List.generate(_photos.length, (index) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC1ECD4),
                                  borderRadius: BorderRadius.circular(12.0),
                                  image: DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(_photos[index].localPath) as ImageProvider
                                        : FileImage(File(_photos[index].localPath)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),

                        // Add Button (if less than 20)
                        if (_photos.length < _maxPhotos)
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: const Color(0xFF012D1D),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add,
                                  size: 28,
                                  color: Color(0xFF012D1D),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. INSTRUCTION TEXT
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Kirimkan bukti kondisi barang sebelum peminjaman',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF000000),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. WARNING BANNER
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: const Color(0xFFFF0000),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF0000),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Foto wajib diunggah sebelum transaksi dimulai. Foto ini akan menjadi bukti sah jika terdapat klaim kerusakan di akhir masa sewa',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF000000),
                        height: 1.83,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // 5. SUBMIT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Konfirmasi & Mulai Sewa',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
