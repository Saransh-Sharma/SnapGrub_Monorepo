import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/features/insights/application/smart_food_suggestions.dart';
import 'package:snapgrub/features/insights/data/insights_repository.dart';
import 'package:snapgrub/features/insights/domain/smart_food_suggestion.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  const ranker = SmartFoodSuggestionRanker();
  final now = DateTime(2026, 6, 1, 12);

  test('meal type match outranks otherwise similar suggestions', () {
    final suggestions = [
      _suggestion('breakfast', mealType: MealType.breakfast, useCount: 8),
      _suggestion('lunch', mealType: MealType.lunch, useCount: 2),
    ];

    final ranked = ranker.rank(
      suggestions: suggestions,
      currentMealType: MealType.lunch,
      now: now,
    );

    expect(ranked.first.title, 'lunch');
    expect(ranked.first.reasonLabel, 'Often at lunch');
  });

  test('use count affects frequent default ordering', () {
    final ranked = ranker.rank(
      suggestions: [
        _suggestion('Paneer', useCount: 2),
        _suggestion('Dal', useCount: 6),
      ],
      currentMealType: MealType.snack,
      now: now,
    );

    expect(ranked.first.title, 'Dal');
    expect(ranked.first.reasonLabel, 'Used 6 times');
  });

  test('recent and template suggestions are included and scored', () {
    final ranked = ranker.rank(
      suggestions: [
        _suggestion(
          'Recent dal',
          origin: SmartFoodSuggestionOrigin.recentMeal,
          lastUsedAt: now.subtract(const Duration(days: 2)),
        ),
        _suggestion(
          'Template oats',
          origin: SmartFoodSuggestionOrigin.template,
        ),
      ],
      currentMealType: MealType.snack,
      now: now,
    );

    expect(ranked.map((item) => item.title),
        containsAll(['Recent dal', 'Template oats']));
    expect(ranked.first.title, 'Recent dal');
  });

  test('duplicates collapse to the highest scoring suggestion', () {
    final ranked = ranker.rank(
      suggestions: [
        _suggestion('Dal Bowl', useCount: 1),
        _suggestion('dal  bowl', useCount: 6),
      ],
      currentMealType: MealType.snack,
      now: now,
    );

    expect(ranked, hasLength(1));
    expect(ranked.single.useCount, 6);
  });

  test('ranker returns at most eight suggestions', () {
    final ranked = ranker.rank(
      suggestions: [
        for (var i = 0; i < 12; i++) _suggestion('Food $i', useCount: i + 1),
      ],
      currentMealType: MealType.snack,
      now: now,
    );

    expect(ranked, hasLength(8));
  });

  test('repository recent window follows the user timezone', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    const userId = 'user-la';
    const timezone = 'America/Los_Angeles';
    final previousUserDayMeal = DateTime.utc(2026, 6, 1, 6, 30);

    await db.into(db.mealsLocal).insert(
          MealsLocalCompanion.insert(
            id: 'meal-previous-user-day',
            userId: userId,
            clientId: 'client-meal-previous-user-day',
            title: 'Late dinner',
            mealType: MealType.dinner.name,
            source: MealSource.manual.name,
            loggedAt: previousUserDayMeal,
            timezone: timezone,
            caloriesKcal: const Value(520),
            proteinG: const Value(32),
            carbsG: const Value(48),
            fatG: const Value(18),
          ),
        );
    await db.into(db.mealItemsLocal).insert(
          MealItemsLocalCompanion.insert(
            id: 'item-previous-user-day',
            mealId: 'meal-previous-user-day',
            userId: userId,
            clientId: 'client-item-previous-user-day',
            position: 0,
            name: 'Late dinner',
            quantity: 1,
            unit: 'plate',
            caloriesKcal: const Value(520),
            proteinG: const Value(32),
            carbsG: const Value(48),
            fatG: const Value(18),
          ),
        );

    final suggestions = await InsightsRepository(db)
        .watchSmartFoodSuggestions(
          userId: userId,
          currentMealType: MealType.breakfast,
          timezone: timezone,
          now: DateTime.utc(2026, 6, 1, 7, 15),
        )
        .first;

    expect(suggestions.map((item) => item.title), contains('Late dinner'));
  });
}

SmartFoodSuggestion _suggestion(
  String title, {
  MealType? mealType,
  int useCount = 1,
  DateTime? lastUsedAt,
  SmartFoodSuggestionOrigin origin = SmartFoodSuggestionOrigin.frequentDefault,
}) {
  return SmartFoodSuggestion(
    id: 'suggestion-$title',
    title: title,
    subtitle: '1 serving',
    caloriesKcal: 220,
    proteinG: 12,
    carbsG: 30,
    fatG: 6,
    mealTypeHint: mealType,
    origin: origin,
    score: useCount.toDouble(),
    reasonLabel: 'Used $useCount times',
    lastUsedAt: lastUsedAt,
    useCount: useCount,
    items: [
      SmartFoodSuggestionItem(
        name: title,
        quantity: 1,
        unit: 'serving',
        caloriesKcal: 220,
        proteinG: 12,
        carbsG: 30,
        fatG: 6,
      ),
    ],
  );
}
