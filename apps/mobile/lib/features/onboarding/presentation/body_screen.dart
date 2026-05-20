import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        TextField(
          keyboardType: TextInputType.number,
          onChanged: ref.read(onboardingControllerProvider.notifier).updateWeight,
          decoration: InputDecoration(
            labelText: draft.unitSystem == 'metric' ? 'Current weight kg' : 'Current weight lb',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: ref.read(onboardingControllerProvider.notifier).updateTargetWeight,
          decoration: InputDecoration(
            labelText: draft.unitSystem == 'metric' ? 'Target weight kg' : 'Target weight lb',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: ref.read(onboardingControllerProvider.notifier).updateHeight,
          decoration: InputDecoration(
            labelText: draft.unitSystem == 'metric' ? 'Height cm' : 'Height inches',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: draft.activityLevel,
          decoration: const InputDecoration(labelText: 'Activity level'),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
            DropdownMenuItem(value: 'high', child: Text('High')),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(onboardingControllerProvider.notifier).updateActivityLevel(value);
            }
          },
        ),
      ],
    );
  }
}
