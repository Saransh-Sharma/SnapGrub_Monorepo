import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraControllerAdapter {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _hasPermission = false;

  bool get hasPermission => _hasPermission;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  CameraController? get controller => _controller;

  Future<bool> refreshPermissionStatus() async {
    final status = await Permission.camera.status;
    _hasPermission = status.isGranted || status.isLimited;
    return _hasPermission;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    _hasPermission = status.isGranted || status.isLimited;
    return _hasPermission;
  }

  Future<void> initialize() async {
    await refreshPermissionStatus();
    if (!_hasPermission) return;
    _cameras ??= await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw StateError('No camera is available on this device.');
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
      throw StateError('Camera preview is not ready.');
    }
    return controller.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
