import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/features/capture/application/capture_controller.dart';
import 'package:snapgrub/features/capture/domain/capture_state.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

class SnapStrip extends ConsumerWidget {
  const SnapStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capture = ref.watch(captureControllerProvider);
    final controller = ref.read(captureControllerProvider.notifier);
    final camera = ref.read(cameraControllerAdapterProvider).controller;
    final userContext = ref.watch(homeUserContextProvider).valueOrNull;
    final flags = ref.watch(profileControllerProvider).valueOrNull?.featureFlags ?? const <String, Object?>{};
    final photoEnabled = _flagEnabled(flags, 'photo_analysis.enabled');
    final barcodeEnabled = _flagEnabled(flags, 'barcode.enabled');
    final voiceEnabled = _flagEnabled(flags, 'voice_capture.enabled');
    final textEnabled = _flagEnabled(flags, 'ocr_assist.enabled');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: _PreviewState(capture, camera)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Barcode',
                  onPressed: barcodeEnabled
                      ? () async {
                          await controller.trackAction('snapstrip_barcode_tapped');
                          if (context.mounted) context.go('/barcode');
                        }
                      : null,
                  icon: const Icon(Icons.qr_code_scanner),
                ),
                IconButton.filled(
                  tooltip: 'Capture',
                  onPressed: photoEnabled && capture.canCapture && userContext != null
                      ? () async {
                          final asset = await controller.capture(userId: userContext.userId);
                          if (asset != null && context.mounted) {
                            context.go('/photo-analysis', extra: asset);
                          }
                        }
                      : null,
                  icon: const Icon(Icons.camera_alt),
                ),
                IconButton(
                  tooltip: 'Text',
                  onPressed: textEnabled
                      ? () async {
                          await controller.trackAction('snapstrip_text_tapped');
                          if (context.mounted) context.go('/text-entry');
                        }
                      : null,
                  icon: const Icon(Icons.keyboard),
                ),
                IconButton(
                  tooltip: 'Voice',
                  onPressed: voiceEnabled
                      ? () async {
                          await controller.trackAction('snapstrip_voice_tapped');
                          if (context.mounted) context.go('/voice-entry');
                        }
                      : null,
                  icon: const Icon(Icons.mic_none),
                ),
              ],
            ),
            if (capture.status == CaptureStatus.permissionNeeded) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: controller.requestPermission,
                child: const Text('Enable camera'),
              ),
            ],
            if (capture.status == CaptureStatus.error) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: controller.initializePreview,
                child: const Text('Retry camera'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _flagEnabled(Map<String, Object?> flags, String key) {
  final value = flags[key];
  return value is bool ? value : true;
}

class _PreviewState extends StatelessWidget {
  const _PreviewState(this.state, this.camera);

  final CaptureState state;
  final CameraController? camera;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      CaptureStatus.loading => const CircularProgressIndicator(),
      CaptureStatus.permissionNeeded => const Text('Camera permission needed'),
      CaptureStatus.cameraReady => camera != null && camera!.value.isInitialized
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CameraPreview(camera!),
            )
          : const Icon(Icons.camera_alt, size: 48),
      CaptureStatus.cameraPaused => const Text('Camera paused'),
      CaptureStatus.captureInProgress => const Text('Capturing...'),
      CaptureStatus.analysisInProgress => const Text('Preparing...'),
      CaptureStatus.error => Text(state.message ?? 'Camera unavailable'),
      CaptureStatus.featureDisabled => const Text('SnapStrip is disabled'),
    };
  }
}
