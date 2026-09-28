import 'package:camera/camera.dart';
import 'package:snapgrub/features/capture/domain/capture_exception.dart';

class CameraControllerAdapter {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _hasPermission = false;

  bool get hasPermission => _hasPermission;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  CameraController? get controller => _controller;

  Future<bool> refreshPermissionStatus() async {
    return _hasPermission || isInitialized;
  }

  Future<bool> requestPermission() async {
    try {
      await initialize();
      return true;
    } on CameraException catch (error) {
      if (error.code == 'CameraAccessDenied' ||
          error.code == 'CameraAccessDeniedWithoutPrompt' ||
          error.code == 'CameraAccessRestricted') {
        _hasPermission = false;
        return false;
      }
      rethrow;
    }
  }

  Future<void> initialize() async {
    if (isInitialized) return;
    _cameras ??= await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw const CaptureException('No camera found on this device.');
    }
    final camera = _cameras!.firstWhere(
      (description) => description.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );
    final previous = _controller;
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await previous?.dispose();
    await _controller!.initialize();
    _hasPermission = true;
  }

  Future<void> pause() async {
    await _controller?.dispose();
    _controller = null;
  }

  Future<void> resume() async {
    if (_hasPermission && !isInitialized) await initialize();
  }

  Future<XFile> takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CaptureException('Camera isn’t ready yet.');
    }
    return controller.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
