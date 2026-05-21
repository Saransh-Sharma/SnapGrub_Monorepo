import 'package:flutter/material.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({
    required this.rollup,
    required this.contextData,
    super.key,
  });

  final DailyRollup rollup;
  final HomeUserContext contextData;

  @override
  Widget build(BuildContext context) {
    final goal = contextData.calorieGoal ?? 2000;
    final progress =
        goal <= 0 ? 0.0 : (rollup.caloriesKcal / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Text('${rollup.caloriesKcal.round()} / ${goal.round()} kcal'),
            Text('${rollup.mealCount} meals logged'),
          ],
        ),
      ),
    );
  }
}
