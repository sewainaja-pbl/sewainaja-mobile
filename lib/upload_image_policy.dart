enum UploadImageKind { profile, product, kyc, chat }

class UploadImagePolicy {
  final UploadImageKind kind;
  final String storageFolder;
  final int maxBytes;
  final int maxImages;
  final int targetLongestSide;
  final int initialQuality;
  final int minimumQuality;

  const UploadImagePolicy({
    required this.kind,
    required this.storageFolder,
    required this.maxBytes,
    required this.maxImages,
    required this.targetLongestSide,
    required this.initialQuality,
    required this.minimumQuality,
  });

  static const profile = UploadImagePolicy(
    kind: UploadImageKind.profile,
    storageFolder: 'users',
    maxBytes: 700 * 1024,
    maxImages: 1,
    targetLongestSide: 1024,
    initialQuality: 84,
    minimumQuality: 60,
  );

  static const product = UploadImagePolicy(
    kind: UploadImageKind.product,
    storageFolder: 'items',
    maxBytes: 2 * 1024 * 1024,
    maxImages: 6,
    targetLongestSide: 1800,
    initialQuality: 88,
    minimumQuality: 66,
  );

  static const kyc = UploadImagePolicy(
    kind: UploadImageKind.kyc,
    storageFolder: 'kyc',
    maxBytes: 3 * 1024 * 1024,
    maxImages: 1,
    targetLongestSide: 1920,
    initialQuality: 85,
    minimumQuality: 60,
  );

  static const chat = UploadImagePolicy(
    kind: UploadImageKind.chat,
    storageFolder: 'chat_media',
    maxBytes: 1500 * 1024,
    maxImages: 1,
    targetLongestSide: 1200,
    initialQuality: 80,
    minimumQuality: 60,
  );

  String get sizeLabelMb => (maxBytes / (1024 * 1024)).toStringAsFixed(
        maxBytes % (1024 * 1024) == 0 ? 0 : 1,
      );

  String get recommendationLabel {
    if (kind == UploadImageKind.profile || kind == UploadImageKind.kyc || kind == UploadImageKind.chat) {
      return 'JPG sampai $sizeLabelMb MB';
    }
    return 'JPG sampai $sizeLabelMb MB, longest side ${targetLongestSide}px';
  }

  bool isWithinLimit(int bytes) => bytes <= maxBytes;
}
