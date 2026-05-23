import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/feature_flags/feature_flags.dart';
import 'package:snapgrub/data/repositories/analytics_repository.dart';
import 'package:snapgrub/features/capture/application/camera_controller_adapter.dart';
import 'package:snapgrub/features/capture/data/capture_asset_repository.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/capture/domain/capture_state.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

final cameraControllerAdapterProvider =
    Provider<CameraControllerAdapter>((ref) {
  final adapter = CameraControllerAdapter();
  ref.onDispose(() {
    adapter.dispose();
  });
  return adapter;
});

final captureControllerProvider =
    NotifierProvider<CaptureController, CaptureState>(
  CaptureController.new,
);

class CaptureController extends Notifier<CaptureState> {
  CameraControllerAdapter get _camera =>
      ref.read(cameraControllerAdapterProvider);
  AnalyticsRepository get _analytics => ref.read(analyticsRepositoryProvider);
  CaptureAssetRepository get _assets =>
      ref.read(captureAssetRepositoryProvider);

  @override
  CaptureState build() {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final flags = FeatureFlags(profile?.featureFlags ?? const {});
    if (!flags.isEnabled(FeatureFlag.snapstrip)) {
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

  Future<void> initializeIfPermitted() async {
    if (state.status == CaptureStatus.featureDisabled ||
        state.status == CaptureStatus.cameraReady) {
      return;
    }
    final granted = await _camera.refreshPermissionStatus();
    if (!granted) {
      state = const CaptureState(status: CaptureStatus.permissionNeeded);
      return;
    }
    await initializePreview();
  }

  Future<void> initializePreview() async {
    if (state.status == CaptureStatus.featureDisabled) {
      return;
    }
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
      state =
          CaptureState(status: CaptureStatus.error, message: error.toString());
    }
  }

  Future<void> pausePreview() async {
    await _camera.pause();
    if (state.status == CaptureStatus.cameraReady) {
      state = const CaptureState(status: CaptureStatus.cameraPaused);
    }
  }

  Future<void> resumePreview() async {
    if (!_camera.hasPermission ||
        state.status == CaptureStatus.featureDisabled) {
      return;
    }
    await _camera.resume();
    state = const CaptureState(status: CaptureStatus.cameraReady);
  }

  Future<CaptureAsset?> capture({required String userId}) async {
    await _analytics.track('snapstrip_capture_tapped');
    if (!_flagEnabled(FeatureFlag.photoAnalysis)) return null;
    if (!state.canCapture) return null;
    state = const CaptureState(status: CaptureStatus.captureInProgress);
    try {
      final file = await _camera.takePicture();
      final asset = await _assets.createFromCapture(userId: userId, file: file);
      state = const CaptureState(status: CaptureStatus.cameraReady);
      return asset;
    } catch (error) {
      state =
          CaptureState(status: CaptureStatus.error, message: error.toString());
      return null;
    }
  }

  Future<void> trackAction(String eventName) {
    final requiredFlag = switch (eventName) {
      'snapstrip_barcode_tapped' => FeatureFlag.barcode,
      'snapstrip_voice_tapped' => FeatureFlag.voiceCapture,
      'snapstrip_text_tapped' => FeatureFlag.ocrAssist,
      _ => null,
    };
    if (requiredFlag != null && !_flagEnabled(requiredFlag)) {
      return Future<void>.value();
    }
    return _analytics.track(eventName);
  }

  bool _flagEnabled(FeatureFlag key) {
    final profile = ref.read(profileControllerProvider).valueOrNull;
    return FeatureFlags(profile?.featureFlags ?? const {}).isEnabled(key);
  }
}
