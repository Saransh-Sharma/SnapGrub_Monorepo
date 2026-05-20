class CaptureAsset {
  const CaptureAsset({
    required this.id,
    required this.createdAt,
    this.localPath,
    this.sha256,
  });

  final String id;
  final DateTime createdAt;
  final String? localPath;
  final String? sha256;
}
