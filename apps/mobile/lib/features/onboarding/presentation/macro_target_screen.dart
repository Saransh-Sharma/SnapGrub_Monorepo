import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';

class OnboardingMacroTargetScreen extends ConsumerWidget {
  const OnboardingMacroTargetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    return ListView(
      children: [
        Text('Daily target', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Text(
            'Start with this target, then adjust it from Settings anytime.'),
        const SizedBox(height: 24),
        _NumberField(
          id: 'onboarding.calories',
          label: 'Calories',
          value: draft.caloriesKcal,
          onChanged:
              ref.read(onboardingControllerProvider.notifier).updateCalories,
        ),
        _NumberField(
          id: 'onboarding.protein',
          label: 'Protein g',
          value: draft.proteinG,
          onChanged:
              ref.read(onboardingControllerProvider.notifier).updateProtein,
        ),
        _NumberField(
          id: 'onboarding.carbs',
          label: 'Carbs g',
          value: draft.carbsG,
          onChanged:
              ref.read(onboardingControllerProvider.notifier).updateCarbs,
        ),
        _NumberField(
          id: 'onboarding.fat',
          label: 'Fat g',
          value: draft.fatG,
          onChanged: ref.read(onboardingControllerProvider.notifier).updateFat,
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String id;
  final String label;
  final double value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: E2eId(
        id: id,
        child: TextField(
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
              labelText: label, hintText: value.toStringAsFixed(0)),
        ),
      ),
    );
  }
}
