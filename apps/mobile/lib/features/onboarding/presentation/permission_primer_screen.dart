import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';

class OnboardingPermissionPrimerScreen extends ConsumerWidget {
  const OnboardingPermissionPrimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        Text('Camera stays in your control',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Text(
          'SnapGrub asks for camera access only when you use capture. Text and manual logging stay available.',
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: ref.watch(onboardingControllerProvider).cameraPrimerSeen,
          onChanged: (_) => ref
              .read(onboardingControllerProvider.notifier)
              .markCameraPrimerSeen(),
          title: const Text('Got it'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: ref.watch(onboardingControllerProvider).notificationPreference,
          onChanged: (value) {
            ref
                .read(onboardingControllerProvider.notifier)
                .updateNotificationPreference(value ?? false);
          },
          title: const Text('Remind me to log meals'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}
