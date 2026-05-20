import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/repositories/analytics_repository.dart';
import 'package:snapgrub/features/capture/application/camera_controller_adapter.dart';
import 'package:snapgrub/features/capture/domain/capture_state.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

final cameraControllerAdapterProvider = Provider<CameraControllerAdapter>((ref) {
  final adapter = CameraControllerAdapter();
  ref.onDispose(() {
    adapter.dispose();
  });
  return adapter;
});

final captureControllerProvider = NotifierProvider<CaptureController, CaptureState>(
  CaptureController.new,
);

class CaptureController extends Notifier<CaptureState> {
  CameraControllerAdapter get _camera => ref.read(cameraControllerAdapterProvider);
  AnalyticsRepository get _analytics => ref.read(analyticsRepositoryProvider);

  @override
  CaptureState build() {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final enabled = profile?.featureFlags['snapstrip.enabled'];
    if (enabled == false) {
      return const CaptureState(status: CaptureStatus.featureDisabled);
    }
    return const CaptureState(status: CaptureStatus.permissionNeeded);
  }

  Future<void> requestPermission() async {
    await _analytics.track('snapstrip_permission_requested');
    state = const CaptureState(status: CaptureStatus.loading);
    final granted = await _camera.requestPermission();
    if (!granted) {
      await _analytics.track('snapstrip_permission_denied');
      state = const CaptureState(status: CaptureStatus.permissionNeeded);
      return;
    }
    await initializePreview();
  }

  Future<void> initializePreview() async {
    if (state.status == CaptureStatus.featureDisabled) return;
    if (!_camera.hasPermission) {
      state = const CaptureState(status: CaptureStatus.permissionNeeded);
      return;
    }
    state = const CaptureState(status: CaptureStatus.loading);
    try {
      await _camera.initialize();
      await _analytics.track('snapstrip_preview_started');
      state = const CaptureState(status: CaptureStatus.cameraReady);
    } catch (error) {
      state = CaptureState(status: CaptureStatus.error, message: error.toString());
    }
  }

  Future<void> pausePreview() async {
    await _camera.pause();
    if (state.status == CaptureStatus.cameraReady) {
      state = const CaptureState(status: CaptureStatus.cameraPaused);
    }
  }

  Future<void> resumePreview() async {
    if (!_camera.hasPermission || state.status == CaptureStatus.featureDisabled) return;
    await _camera.resume();
    state = const CaptureState(status: CaptureStatus.cameraReady);
  }

  Future<void> capture() async {
    await _analytics.track('snapstrip_capture_tapped');
    if (!state.canCapture) return;
    state = const CaptureState(status: CaptureStatus.captureInProgress);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    state = const CaptureState(status: CaptureStatus.cameraReady);
  }

  Future<void> trackAction(String eventName) => _analytics.track(eventName);
}
