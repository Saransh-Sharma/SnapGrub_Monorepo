import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(todayMealsProvider);
    return AppScaffold(
      title: 'Journal',
      actions: [
        IconButton(
          tooltip: 'Add meal',
          onPressed: () => context.go('/meal-editor'),
          icon: const Icon(Icons.add),
        ),
      ],
      child: meals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(error.toString()),
        data: (items) {
          if (items.isEmpty) return const Text('No meals logged today.');
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _MealCard(meal: items[index]),
          );
        },
      ),
    );
  }
}

class _MealCard extends ConsumerWidget {
  const _MealCard({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(meal.title, style: Theme.of(context).textTheme.titleMedium),
                ),
                Chip(label: Text(meal.syncStatus.name)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${meal.caloriesKcal.round()} kcal · P ${meal.proteinG.round()}g · C ${meal.carbsG.round()}g · F ${meal.fatG.round()}g'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => context.go('/meal-editor?id=${meal.id}'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(mealRepositoryProvider).duplicateMeal(meal);
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Duplicate'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(mealRepositoryProvider).deleteMeal(meal);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
