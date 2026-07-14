import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/insights/application/smart_food_draft_factory.dart';
import 'package:snapgrub/features/insights/domain/smart_food_suggestion.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

void main() {
  const factory = SmartFoodDraftFactory();

  test('creates review-first draft from frequent default suggestion', () {
    final draft = factory.toDraft(
      suggestion: _suggestion(
        origin: SmartFoodSuggestionOrigin.frequentDefault,
        mealTypeHint: null,
      ),
      userId: 'user-a',
      timezone: 'Asia/Kolkata',
      now: DateTime(2026, 6, 1, 13),
    );

    expect(draft.source, MealSource.duplicate);
    expect(draft.mealType, MealType.lunch);
    expect(draft.items.single.sourceType, 'smart_food_suggestion');
    expect(draft.items.single.sourceId, 'suggestion-a');
    expect(() => draft.validate(), returnsNormally);
  });

  test('preserves item refs and macros for recent meal/template suggestions',
      () {
    final draft = factory.toDraft(
      suggestion: _suggestion(origin: SmartFoodSuggestionOrigin.template),
      userId: 'user-a',
      timezone: 'Asia/Kolkata',
      now: DateTime(2026, 6, 1, 22),
    );

    expect(draft.mealType, MealType.dinner);
    expect(draft.items.single.customFoodId, 'custom-a');
    expect(draft.caloriesKcal, 265);
    expect(draft.proteinG, 18);
  });
}

SmartFoodSuggestion _suggestion({
  required SmartFoodSuggestionOrigin origin,
  MealType? mealTypeHint = MealType.dinner,
}) {
  return SmartFoodSuggestion(
    id: 'suggestion-a',
    title: 'Paneer bowl',
    subtitle: '1 serving',
    caloriesKcal: 265,
    proteinG: 18,
    carbsG: 4,
    fatG: 20,
    mealTypeHint: mealTypeHint,
    origin: origin,
    score: 10,
    reasonLabel: 'From template',
    items: const [
      SmartFoodSuggestionItem(
        name: 'Paneer',
        foodRefKind: 'custom',
        customFoodId: 'custom-a',
        quantity: 1,
        unit: 'serving',
        gramsEstimated: 100,
        caloriesKcal: 265,
        proteinG: 18,
        carbsG: 4,
        fatG: 20,
      ),
    ],
  );
}
