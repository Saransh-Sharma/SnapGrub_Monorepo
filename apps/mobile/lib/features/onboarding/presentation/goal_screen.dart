import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';

class OnboardingGoalScreen extends ConsumerWidget {
  const OnboardingGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    return ListView(
      children: [
        Text('Goal', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'lose', label: Text('Lose')),
            ButtonSegment(value: 'maintain', label: Text('Maintain')),
            ButtonSegment(value: 'gain', label: Text('Gain')),
            ButtonSegment(value: 'custom', label: Text('Custom')),
          ],
          selected: {draft.goalType},
          onSelectionChanged: (value) {
            ref
                .read(onboardingControllerProvider.notifier)
                .updateGoal(value.single);
          },
        ),
        const SizedBox(height: 24),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'metric', label: Text('Metric')),
            ButtonSegment(value: 'imperial', label: Text('Imperial')),
          ],
          selected: {draft.unitSystem},
          onSelectionChanged: (value) {
            ref
                .read(onboardingControllerProvider.notifier)
                .updateUnitSystem(value.single);
          },
        ),
      ],
    );
  }
}
