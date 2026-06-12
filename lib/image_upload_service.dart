import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import 'upload_image_policy.dart';

class ProcessedImageFile {
  final String localPath;
  final Uint8List bytes;
  final int sizeInBytes;
  final UploadImagePolicy policy;

  const ProcessedImageFile({
    required this.localPath,
    required this.bytes,
    required this.sizeInBytes,
    required this.policy,
  });
}

enum ImageSourceChoice { camera, gallery }

String getSafeImageUrl(String pathOrUrl) {
  final trimmed = pathOrUrl.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final filename = trimmed.split('/').last;
  const productFiles = {
    'airpods_max.png', 'bor_listrik.png', 'camera_canon.jpg', 'camera_nikon.jpg',
    'camera_sony.jpg', 'celana.jpg', 'celana_jeans.jpg', 'gergaji_circular.png',
    'handphone.jpg', 'hp_asus.jpg', 'hp_realme.jpg', 'jaz_abu.jpg', 'jaz_hitam.jpg',
    'kemeja_lengan_panjang.jpg', 'kemeja_warna_putih.jpg', 'kompor_camping.png',
    'lentera_camping.png', 'matras_camping.png', 'mesin_amplas.png',
    'mesin_gerinda.png', 'mesin_serut.png', 'obeng_listrik.png',
    'ps5_controller.png', 'sleeping_bag.png', 'sony_camera.png',
    'tas_carrier.png', 'tenda_camping.png'
  };
  if (productFiles.contains(filename)) {
    return 'https://firebasestorage.googleapis.com/v0/b/sewainaja-b4834.firebasestorage.app/o/items%2Fdummy_assets%2F$filename?alt=media';
  }
  return trimmed;
}

class ImageUploadService {
  ImageUploadService({ImagePicker? picker, FirebaseStorage? storage})
    : _picker = picker ?? ImagePicker(),
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
                  onTap: () =>
                      Navigator.pop(context, ImageSourceChoice.gallery),
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
    if (remainingSlots <= 0) return const [];

    // ImagePicker.pickMultiImage requires a limit of at least 2.
    // If only 1 slot is remaining, fall back to picking a single image from gallery.
    if (remainingSlots == 1) {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return const [];
      final sanitized = await sanitizeImage(file, policy);
      return sanitized != null ? [sanitized] : const [];
    }

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
    final originalData = await picked.readAsBytes();

    // Web does not support flutter_image_compress.
    if (kIsWeb) {
      if (!policy.isWithinLimit(originalBytes)) {
        return null;
      }
      return ProcessedImageFile(
        localPath: picked.path,
        bytes: originalData,
        sizeInBytes: originalBytes,
        policy: policy,
      );
    }

    var quality = policy.initialQuality;
    ProcessedImageFile? candidate;

    while (quality >= policy.minimumQuality) {
      final compressed = await FlutterImageCompress.compressWithFile(
        picked.path,
        minWidth: policy.targetLongestSide,
        minHeight: policy.targetLongestSide,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressed == null || compressed.isEmpty) break;

      candidate = ProcessedImageFile(
        localPath: picked.path,
        bytes: compressed,
        sizeInBytes: compressed.length,
        policy: policy,
      );

      if (policy.isWithinLimit(compressed.length)) {
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
        bytes: originalData,
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
    final task = await ref.putData(
      processed.bytes,
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

  ImageProvider buildImageProvider(String? pathOrUrl, {int? targetWidth}) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) {
      throw ArgumentError('Path or URL must not be empty');
    }
    final safeUrl = getSafeImageUrl(pathOrUrl);
    if (safeUrl.startsWith('http://') || safeUrl.startsWith('https://')) {
      final networkImage = CachedNetworkImageProvider(safeUrl);
      if (targetWidth != null) {
        return ResizeImage(networkImage, width: targetWidth);
      }
      return networkImage;
    }
    if (safeUrl.startsWith('assets/')) {
      final assetImage = AssetImage(safeUrl);
      if (targetWidth != null) {
        return ResizeImage(assetImage, width: targetWidth);
      }
      return assetImage;
    }
    throw ArgumentError(
      'Local file path preview is not supported in this method',
    );
  }

  ImageProvider buildProcessedImageProvider(ProcessedImageFile processed) {
    return MemoryImage(processed.bytes);
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
