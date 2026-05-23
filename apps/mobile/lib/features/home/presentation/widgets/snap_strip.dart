import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_data.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/core/feature_flags/feature_flags.dart';
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
    final flags = FeatureFlags(
      ref.watch(profileControllerProvider).valueOrNull?.featureFlags ??
          const <String, Object?>{},
    );
    final isE2e = ref.watch(appConfigProvider).isE2e;
    final photoEnabled = isE2e || flags.isEnabled(FeatureFlag.photoAnalysis);
    final barcodeEnabled = isE2e || flags.isEnabled(FeatureFlag.barcode);
    final voiceEnabled = isE2e || flags.isEnabled(FeatureFlag.voiceCapture);
    final textEnabled = isE2e || flags.isEnabled(FeatureFlag.ocrAssist);
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
                E2eId(
                  id: 'snapstrip.barcode',
                  child: IconButton(
                    tooltip: 'Barcode',
                    onPressed: barcodeEnabled
                        ? () async {
                            await controller
                                .trackAction('snapstrip_barcode_tapped');
                            if (context.mounted) context.go('/barcode');
                          }
                        : null,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                ),
                E2eId(
                  id: 'snapstrip.capture',
                  child: IconButton.filled(
                    tooltip: 'Capture',
                    onPressed: photoEnabled &&
                            capture.canCapture &&
                            userContext != null
                        ? () async {
                            final asset = await controller.capture(
                                userId: userContext.userId);
                            if (asset != null && context.mounted) {
                              context.go('/photo-analysis', extra: asset);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.camera_alt),
                  ),
                ),
                E2eId(
                  id: 'snapstrip.text',
                  child: IconButton(
                    tooltip: 'Text',
                    onPressed: textEnabled
                        ? () async {
                            await controller
                                .trackAction('snapstrip_text_tapped');
                            if (context.mounted) context.go('/text-entry');
                          }
                        : null,
                    icon: const Icon(Icons.keyboard),
                  ),
                ),
                E2eId(
                  id: 'snapstrip.voice',
                  child: IconButton(
                    tooltip: 'Voice',
                    onPressed: voiceEnabled
                        ? () async {
                            await controller
                                .trackAction('snapstrip_voice_tapped');
                            if (context.mounted) context.go('/voice-entry');
                          }
                        : null,
                    icon: const Icon(Icons.mic_none),
                  ),
                ),
              ],
            ),
            if (isE2e && userContext != null) ...[
              const SizedBox(height: 8),
              E2eId(
                id: 'snapstrip.fixture_photo',
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final asset =
                        await E2eData.fixtureAsset(userContext.userId);
                    if (context.mounted) {
                      context.go('/photo-analysis', extra: asset);
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('E2E photo fixture'),
                ),
              ),
            ],
            if (capture.status == CaptureStatus.permissionNeeded) ...[
              const SizedBox(height: 8),
              E2eId(
                id: 'snapstrip.enable_camera',
                child: FilledButton(
                  onPressed: controller.requestPermission,
                  child: const Text('Enable camera'),
                ),
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
