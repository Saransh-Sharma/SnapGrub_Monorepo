import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/capture/application/capture_controller.dart';
import 'package:snapgrub/features/capture/domain/capture_state.dart';

class SnapStrip extends ConsumerWidget {
  const SnapStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capture = ref.watch(captureControllerProvider);
    final controller = ref.read(captureControllerProvider.notifier);
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
                child: Center(child: _PreviewState(capture)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Barcode',
                  onPressed: () => controller.trackAction('snapstrip_barcode_tapped'),
                  icon: const Icon(Icons.qr_code_scanner),
                ),
                IconButton.filled(
                  tooltip: 'Capture',
                  onPressed: capture.canCapture ? controller.capture : null,
                  icon: const Icon(Icons.camera_alt),
                ),
                IconButton(
                  tooltip: 'Text',
                  onPressed: () => controller.trackAction('snapstrip_text_tapped'),
                  icon: const Icon(Icons.keyboard),
                ),
                IconButton(
                  tooltip: 'Voice',
                  onPressed: () => controller.trackAction('snapstrip_voice_tapped'),
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

class _PreviewState extends StatelessWidget {
  const _PreviewState(this.state);

  final CaptureState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      CaptureStatus.loading => const CircularProgressIndicator(),
      CaptureStatus.permissionNeeded => const Text('Camera permission needed'),
      CaptureStatus.cameraReady => const Icon(Icons.camera_alt, size: 48),
      CaptureStatus.cameraPaused => const Text('Camera paused'),
      CaptureStatus.captureInProgress => const Text('Capturing...'),
      CaptureStatus.analysisInProgress => const Text('Preparing...'),
      CaptureStatus.error => Text(state.message ?? 'Camera unavailable'),
      CaptureStatus.featureDisabled => const Text('SnapStrip is disabled'),
    };
  }
}
