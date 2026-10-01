import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_repository.dart';
import 'package:snapgrub/features/custom_foods/domain/custom_food.dart';
import 'package:snapgrub/features/meal_editor/data/local_food_search.dart';
import 'package:snapgrub/features/meal_editor/data/meal_draft_mapper.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

import '../../../helpers/mobile_test_harness.dart';

void main() {
  test('finds My foods and past meal items by name, one row per food',
      () async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final custom =
        await harness.container.read(customFoodRepositoryProvider).save(
              testUserId,
              CustomFoodDraft(
                name: 'Dal makhani',
                servingQuantity: 1,
                servingUnit: 'katori',
                servingGrams: 180,
                caloriesKcal: 288,
                proteinG: 12.6,
                carbsG: 32.4,
                fatG: 12.6,
              ),
            );
    final meals = harness.container.read(mealRepositoryProvider);
    // The same food logged twice must come back once.
    await meals.saveDraft(testMealDraft(title: 'Lunch'));
    await meals.saveDraft(testMealDraft(title: 'Dinner'));

    final search = harness.container.read(localFoodSearchProvider);
    final results = await search.search(userId: testUserId, query: 'DAL');

    expect(results.map((food) => food.name), ['Dal makhani', 'Dal']);
    expect(results.first.resultType, 'custom');
    expect(results.last.resultType, 'recent');
    expect(results.last.caloriesKcal, 420);

    // A picked "My food" keeps its link; a past entry is a plain item.
    final picked = mealItemFromFoodResult(results.first);
    expect(picked.foodRefKind, 'custom');
    expect(picked.customFoodId, custom.id);
    expect(mealItemFromFoodResult(results.last).foodRefKind, 'manual');
  });

  test('returns nothing for another user or a blank query', () async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await harness.container
        .read(mealRepositoryProvider)
        .saveDraft(testMealDraft(title: 'Lunch'));
    final search = harness.container.read(localFoodSearchProvider);

    expect(await search.search(userId: 'someone-else', query: 'dal'), isEmpty);
    expect(await search.search(userId: testUserId, query: '  '), isEmpty);
    expect(await search.search(userId: testUserId, query: '%'), isEmpty);
  });

  test('MealDraftItem defaults stay out of results', () async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final search = harness.container.read(localFoodSearchProvider);
    expect(MealDraftItem().name, isEmpty);
    expect(await search.search(userId: testUserId, query: 'roti'), isEmpty);
  });
}
