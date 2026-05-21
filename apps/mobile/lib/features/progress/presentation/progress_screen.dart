import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextData = ref.watch(homeUserContextProvider);
    return AppScaffold(
      title: 'Progress',
      child: contextData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(error.toString()),
        data: (data) {
          if (data == null) return const Text('Sign in to continue.');
          final rollup = ref.watch(todayRollupProvider);
          return rollup.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(error.toString()),
            data: (value) => _ProgressBody(rollup: value, contextData: data),
          );
        },
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.rollup,
    required this.contextData,
  });

  final DailyRollup rollup;
  final HomeUserContext contextData;

  @override
  Widget build(BuildContext context) {
    final calorieGoal = contextData.calorieGoal ?? 2000;
    return ListView(
      children: [
        _ProgressTile(
          label: 'Calories',
          value: rollup.caloriesKcal,
          goal: calorieGoal,
          unit: 'kcal',
        ),
        _ProgressTile(
          label: 'Protein',
          value: rollup.proteinG,
          goal: contextData.proteinGoal ?? 120,
          unit: 'g',
        ),
        _ProgressTile(
          label: 'Carbs',
          value: rollup.carbsG,
          goal: contextData.carbsGoal ?? 200,
          unit: 'g',
        ),
        _ProgressTile(
          label: 'Fat',
          value: rollup.fatG,
          goal: contextData.fatGoal ?? 70,
          unit: 'g',
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: Text('${rollup.mealCount} meals logged'),
            subtitle: Text(rollup.hasPhotoMeal ? 'Includes photo-sourced meals' : 'Manual/template meals today'),
          ),
        ),
      ],
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
  });

  final String label;
  final double value;
  final double goal;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Text('${value.round()} / ${goal.round()} $unit'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}
