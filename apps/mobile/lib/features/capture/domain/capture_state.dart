enum CaptureStatus {
  loading,
  permissionNeeded,
  cameraReady,
  cameraPaused,
  captureInProgress,
  analysisInProgress,
  error,
  featureDisabled,
}

class CaptureState {
  const CaptureState({
    required this.status,
    this.message,
  });

  final CaptureStatus status;
  final String? message;

  bool get canCapture => status == CaptureStatus.cameraReady;
}
