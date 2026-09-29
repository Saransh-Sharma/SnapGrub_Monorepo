import 'package:snapgrub/features/insights/domain/smart_food_suggestion.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class SmartFoodDraftFactory {
  const SmartFoodDraftFactory();

  MealDraft toDraft({
    required SmartFoodSuggestion suggestion,
    required String userId,
    required String timezone,
    required DateTime now,
  }) {
    return MealDraft(
      userId: userId,
      timezone: timezone,
      title: suggestion.title,
      mealType: suggestion.mealTypeHint ?? _mealTypeFor(now),
      source: MealSource.duplicate,
      loggedAt: now,
      items: [
        for (final item in suggestion.items)
          MealDraftItem(
            name: item.name,
            foodRefKind: item.foodRefKind,
            canonicalFoodId: item.canonicalFoodId,
            brandedProductId: item.brandedProductId,
            customFoodId: item.customFoodId,
            quantity: item.quantity,
            unit: item.unit,
            gramsEstimated: item.gramsEstimated,
            caloriesKcal: item.caloriesKcal,
            proteinG: item.proteinG,
            carbsG: item.carbsG,
            fatG: item.fatG,
            confidence: item.confidence,
            sourceType: 'smart_food_suggestion',
            sourceId: suggestion.id,
            notes: item.notes,
          ),
      ],
    );
  }

  MealType _mealTypeFor(DateTime now) {
    if (now.hour < 11) return MealType.breakfast;
    if (now.hour < 16) return MealType.lunch;
    if (now.hour < 21) return MealType.dinner;
    return MealType.snack;
  }
}
