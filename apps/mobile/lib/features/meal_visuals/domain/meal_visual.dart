enum MealVisualStatus { queued, generating, ready, failed }

class MealVisual {
  const MealVisual({
    required this.id,
    required this.mealId,
    required this.userId,
    required this.promptSignature,
    required this.styleVersion,
    required this.status,
    this.localPath,
    this.remotePath,
    this.thumbRemotePath,
    this.dominantColor,
  });

  final String id;
  final String mealId;
  final String userId;
  final String promptSignature;
  final String styleVersion;
  final MealVisualStatus status;
  final String? localPath;
  final String? remotePath;
  final String? thumbRemotePath;
  final String? dominantColor;
}
