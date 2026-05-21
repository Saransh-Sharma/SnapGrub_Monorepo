import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class RecentMealsCarousel extends StatelessWidget {
  const RecentMealsCarousel({required this.meals, super.key});

  final List<Meal> meals;

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No meals logged today.'),
        ),
      );
    }
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: meals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final meal = meals[index];
          return SizedBox(
            width: 220,
            child: Card(
              child: InkWell(
                onTap: () => context.go('/meal-editor?id=${meal.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text('${meal.caloriesKcal.round()} kcal'),
                      Text(meal.syncStatus.name),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
