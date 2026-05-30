import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'upload_image_policy.dart';

class ProcessedImageFile {
  final String localPath;
  final int sizeInBytes;
  final UploadImagePolicy policy;

  const ProcessedImageFile({
    required this.localPath,
    required this.sizeInBytes,
    required this.policy,
  });

  File get file => File(localPath);
}

enum ImageSourceChoice { camera, gallery }

class ImageUploadService {
  ImageUploadService({
    ImagePicker? picker,
    FirebaseStorage? storage,
  })  : _picker = picker ?? ImagePicker(),
        _storage = storage ?? FirebaseStorage.instance;

  final ImagePicker _picker;
  final FirebaseStorage _storage;

  Future<ImageSourceChoice?> chooseImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSourceChoice>(
      context: context,
      backgroundColor: const Color(0xFFFFF8EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ambil foto langsung dari kamera atau pilih dari galeri.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF5C635E),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                _SourceTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Kamera',
                  subtitle: 'Ambil foto realtime sekarang',
                  onTap: () => Navigator.pop(context, ImageSourceChoice.camera),
                ),
                const SizedBox(height: 12),
                _SourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Galeri',
                  subtitle: 'Pilih foto yang sudah ada',
                  onTap: () => Navigator.pop(context, ImageSourceChoice.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<ProcessedImageFile?> pickSingleImageFromSource({
    required UploadImagePolicy policy,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;
    return sanitizeImage(picked, policy);
  }

  Future<List<ProcessedImageFile>> pickMultipleImages({
    required UploadImagePolicy policy,
    required int remainingSlots,
  }) async {
    final picked = await _picker.pickMultiImage(limit: remainingSlots);
    if (picked.isEmpty) return const [];

    final files = <ProcessedImageFile>[];
    for (final file in picked.take(remainingSlots)) {
      final sanitized = await sanitizeImage(file, policy);
      if (sanitized != null) {
        files.add(sanitized);
      }
    }
    return files;
  }

  Future<ProcessedImageFile?> sanitizeImage(
    XFile picked,
    UploadImagePolicy policy,
  ) async {
    final originalBytes = await picked.length();

    // Web does not support flutter_image_compress or getTemporaryDirectory
    if (kIsWeb) {
      return ProcessedImageFile(
        localPath: picked.path,
        sizeInBytes: originalBytes,
        policy: policy,
      );
    }

    final tempDir = await getTemporaryDirectory();
    var quality = policy.initialQuality;
    ProcessedImageFile? candidate;

    while (quality >= policy.minimumQuality) {
      final targetPath =
          '${tempDir.path}\\${DateTime.now().microsecondsSinceEpoch}_q$quality.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        minWidth: policy.targetLongestSide,
        minHeight: policy.targetLongestSide,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) break;

      final bytes = await result.length();
      candidate = ProcessedImageFile(
        localPath: result.path,
        sizeInBytes: bytes,
        policy: policy,
      );

      if (policy.isWithinLimit(bytes)) {
        return candidate;
      }
      quality -= 8;
    }

    if (candidate != null && candidate.sizeInBytes < originalBytes) {
      return candidate;
    }
    if (policy.isWithinLimit(originalBytes)) {
      return ProcessedImageFile(
        localPath: picked.path,
        sizeInBytes: originalBytes,
        policy: policy,
      );
    }
    return null;
  }

  Future<String> uploadProcessedImage({
    required ProcessedImageFile processed,
    required String storagePath,
  }) async {
    final ref = _storage.ref().child(storagePath);
    final task = await ref.putFile(
      File(processed.localPath),
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'kind': processed.policy.kind.name,
          'sanitized': 'true',
          'source': 'mobile-app',
        },
      ),
    );
    return task.ref.getDownloadURL();
  }

  String buildUserAvatarStoragePath(String userId) {
    return 'users/$userId/profile/avatar.jpg';
  }

  String buildItemPhotoStoragePath({
    required String itemId,
    required int index,
    int? timestamp,
  }) {
    final safeTimestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    return 'items/$itemId/photos/${safeTimestamp}_$index.jpg';
  }

  ImageProvider buildImageProvider(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) {
      throw ArgumentError('Path or URL must not be empty');
    }
    final trimmed = pathOrUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }
    return FileImage(File(trimmed));
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF012D1D)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF5C635E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF012D1D),
            ),
          ],
        ),
      ),
    );
  }
}

String safeImageError(Object error) {
  if (kDebugMode) {
    return error.toString();
  }
  return 'Terjadi kendala saat memproses gambar.';
}
