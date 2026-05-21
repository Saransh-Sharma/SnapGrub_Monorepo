import 'package:flutter/material.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class MacroSummaryCard extends StatelessWidget {
  const MacroSummaryCard({
    required this.rollup,
    required this.contextData,
    super.key,
  });

  final DailyRollup rollup;
  final HomeUserContext contextData;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Macro(label: 'Protein', value: rollup.proteinG, goal: contextData.proteinGoal),
            _Macro(label: 'Carbs', value: rollup.carbsG, goal: contextData.carbsGoal),
            _Macro(label: 'Fat', value: rollup.fatG, goal: contextData.fatGoal),
          ],
        ),
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value, this.goal});

  final String label;
  final double value;
  final double? goal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text('${value.round()}g', style: Theme.of(context).textTheme.titleMedium),
        if (goal != null) Text('/ ${goal!.round()}g'),
      ],
    );
  }
}
