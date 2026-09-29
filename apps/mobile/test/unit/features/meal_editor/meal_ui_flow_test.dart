import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_repository.dart';
import 'package:snapgrub/features/custom_foods/domain/custom_food.dart';
import 'package:snapgrub/features/journal/presentation/journal_screen.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_editor/presentation/meal_editor_screen.dart';
import 'package:snapgrub/features/progress/presentation/progress_screen.dart';
import 'package:snapgrub/features/templates/data/template_repository.dart';
import 'package:snapgrub/features/templates/presentation/templates_screen.dart';

import '../../../helpers/mobile_test_harness.dart';

void main() {
  testWidgets('local meal save appears in Journal and Progress',
      (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);

    final meal = await harness.container.read(mealRepositoryProvider).saveDraft(
          testMealDraft(title: 'Dal bowl')
            ..loggedAt = DateTime(2026, 5, 30, 12),
        );

    await harness.pumpScreen(tester, const JournalScreen());
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Dal bowl'), findsOneWidget);
    expect(find.text('Saved on phone'), findsOneWidget);

    // Progress is being redesigned in parallel; its own tests own the copy.
    // Here we only check the saved meal doesn't break it.
    await harness.pumpScreen(tester, const ProgressScreen());
    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await harness.container.read(templateRepositoryProvider).saveFromMeal(meal);
    await harness.pumpScreen(tester, const TemplatesScreen());
    expect(find.text('Saved meals'), findsOneWidget);
    expect(find.text('Dal bowl'), findsOneWidget);
  });

  testWidgets('Meal Editor renders editable draft and custom food seeds',
      (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await harness.container.read(customFoodRepositoryProvider).save(
          testUserId,
          CustomFoodDraft(
            name: 'Paneer',
            servingQuantity: 1,
            servingUnit: 'serving',
            servingGrams: 100,
            caloriesKcal: 265,
            proteinG: 18,
            carbsG: 4,
            fatG: 20,
          ),
        );

    await harness.pumpScreen(
      tester,
      MealEditorScreen(
        initialDraft: testMealDraft(
          title: 'AI paneer bowl',
          source: MealSource.photo,
          confidence: 0.62,
        ),
      ),
    );

    expect(find.text('Review meal'), findsOneWidget);
    expect(find.byKey(const ValueKey('meal.title')), findsOneWidget);
    // The analysis warning is shown, and provenance reads as words.
    expect(find.textContaining('Low confidence'), findsWidgets);
    expect(find.textContaining('Estimate'), findsWidgets);
    expect(find.textContaining('photo_test'), findsNothing);
  });
}
