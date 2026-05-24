import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
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
            ButtonSegment(
                value: 'lose',
                label: E2eId(id: 'onboarding.goal.lose', child: Text('Lose'))),
            ButtonSegment(
                value: 'maintain',
                label: E2eId(
                    id: 'onboarding.goal.maintain', child: Text('Maintain'))),
            ButtonSegment(
                value: 'gain',
                label: E2eId(id: 'onboarding.goal.gain', child: Text('Gain'))),
            ButtonSegment(
                value: 'custom',
                label:
                    E2eId(id: 'onboarding.goal.custom', child: Text('Custom'))),
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
            ButtonSegment(
                value: 'metric',
                label:
                    E2eId(id: 'onboarding.unit.metric', child: Text('Metric'))),
            ButtonSegment(
                value: 'imperial',
                label: E2eId(
                    id: 'onboarding.unit.imperial', child: Text('Imperial'))),
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
