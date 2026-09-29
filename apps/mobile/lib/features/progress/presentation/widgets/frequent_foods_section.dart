import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/insights/domain/food_portion.dart';
import 'package:snapgrub/features/insights/domain/weekly_insight.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

/// Builds an editable review draft from a frequent-food default. Nothing is
/// saved until the user confirms in Meal Review.
MealDraft draftFromFoodDefault(
  UserFoodDefault item, {
  required String userId,
  required String timezone,
  required MealType mealType,
}) {
  return MealDraft(
    userId: userId,
    timezone: timezone,
    title: item.foodName,
    mealType: mealType,
    source: MealSource.duplicate,
    items: [
      MealDraftItem(
        name: item.foodName,
        foodRefKind: item.foodRefKind,
        canonicalFoodId:
            item.foodRefKind == 'canonical' ? item.foodRefId : null,
        brandedProductId: item.foodRefKind == 'branded' ? item.foodRefId : null,
        customFoodId: item.foodRefKind == 'custom' ? item.foodRefId : null,
        quantity: item.preferredQuantity,
        unit: item.preferredUnit,
        gramsEstimated: item.preferredGrams,
        caloriesKcal: item.caloriesKcal,
        proteinG: item.proteinG,
        carbsG: item.carbsG,
        fatG: item.fatG,
        sourceType: 'user_food_default',
        sourceId: item.id,
      ),
    ],
  );
}

/// Frequent foods (used when go-to foods are off). Tapping opens Review.
class FrequentMealsSection extends StatelessWidget {
  const FrequentMealsSection({
    required this.defaults,
    required this.contextData,
    required this.mealType,
    super.key,
  });

  final List<UserFoodDefault> defaults;
  final HomeUserContext contextData;
  final MealType mealType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (defaults.isEmpty) {
      return const SgCard(
        child: EmptyState(
          compact: true,
          illustration: SgIllustrationKind.notebook,
          title: 'Frequent foods',
          message: 'Foods you log often show up here.',
        ),
      );
    }
    return SgCard(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      // ListTile ink needs a Material above SgCard's decorated background.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Text('Frequent foods', style: theme.textTheme.titleMedium),
            ),
            for (final item in defaults.take(6))
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(item.foodName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${foodPortionLabel(item.preferredQuantity, item.preferredUnit)}'
                  ' · ${Labels.kcal(item.caloriesKcal)} · ${item.useCount}×',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // "Log" still opens Review; nothing saves until confirmed.
                trailing: TextButton(
                  onPressed: () => _review(context, item),
                  child: const Text('Log'),
                ),
                onTap: () => _review(context, item),
              ),
          ],
        ),
      ),
    );
  }

  void _review(BuildContext context, UserFoodDefault item) {
    SgHaptics.tap();
    context.push(
      '/meal-editor',
      extra: draftFromFoodDefault(
        item,
        userId: contextData.userId,
        timezone: contextData.timezone,
        mealType: mealType,
      ),
    );
  }
}
