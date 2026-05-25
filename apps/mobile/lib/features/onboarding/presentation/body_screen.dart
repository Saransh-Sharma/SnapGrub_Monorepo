import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';

class OnboardingBodyScreen extends ConsumerWidget {
  const OnboardingBodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    return ListView(
      children: [
        Text('Body details', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Text('These are optional and editable later.'),
        const SizedBox(height: 24),
        E2eId(
          id: 'onboarding.weight',
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged:
                ref.read(onboardingControllerProvider.notifier).updateWeight,
            decoration: InputDecoration(
              labelText: draft.unitSystem == 'metric'
                  ? 'Current weight kg'
                  : 'Current weight lb',
            ),
          ),
        ),
        const SizedBox(height: 12),
        E2eId(
          id: 'onboarding.target_weight',
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged: ref
                .read(onboardingControllerProvider.notifier)
                .updateTargetWeight,
            decoration: InputDecoration(
              labelText: draft.unitSystem == 'metric'
                  ? 'Target weight kg'
                  : 'Target weight lb',
            ),
          ),
        ),
        const SizedBox(height: 12),
        E2eId(
          id: 'onboarding.height',
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged:
                ref.read(onboardingControllerProvider.notifier).updateHeight,
            decoration: InputDecoration(
              labelText:
                  draft.unitSystem == 'metric' ? 'Height cm' : 'Height inches',
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: draft.activityLevel,
          decoration: const InputDecoration(labelText: 'Activity level'),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
            DropdownMenuItem(value: 'high', child: Text('High')),
          ],
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(onboardingControllerProvider.notifier)
                  .updateActivityLevel(value);
            }
          },
        ),
      ],
    );
  }
}
