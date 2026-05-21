class CaptureAsset {
  const CaptureAsset({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.localPath,
    required this.storageBucket,
    required this.storagePath,
    required this.sha256,
    required this.mimeType,
    required this.sizeBytes,
    this.thumbLocalPath,
    this.thumbStoragePath,
    this.width,
    this.height,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final String localPath;
  final String storageBucket;
  final String storagePath;
  final String sha256;
  final String mimeType;
  final int sizeBytes;
  final String? thumbLocalPath;
  final String? thumbStoragePath;
  final int? width;
  final int? height;
}
