import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/milestones/domain/streak.dart';
import 'package:snapgrub/features/recap/domain/weekly_recap.dart';

var _id = 0;

MealItem item(String name) => MealItem(
      id: 'i${_id++}',
      mealId: 'm',
      userId: 'u',
      clientId: 'c',
      position: 0,
      name: name,
      foodRefKind: 'manual',
      quantity: 1,
      unit: 'serving',
      caloriesKcal: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
    );

Meal meal(
  DateTime at, {
  double kcal = 500,
  double protein = 30,
  String title = 'Meal',
  List<String> items = const [],
  String? photo,
  bool deleted = false,
}) =>
    Meal(
      id: 'm${_id++}',
      userId: 'u',
      clientId: 'c',
      title: title,
      mealType: MealType.lunch,
      source: MealSource.manual,
      loggedAt: at,
      timezone: 'UTC',
      caloriesKcal: kcal,
      proteinG: protein,
      carbsG: 0,
      fatG: 0,
      revision: 1,
      syncStatus: MealSyncStatus.synced,
      photoAssetId: photo,
      deletedAt: deleted ? at : null,
      items: [for (final n in items) item(n)],
    );

const _streak = StreakSummary(
    current: 4, best: 9, loggedToday: true, frozenDays: <DateTime>{});

void main() {
  final today = DateTime(2026, 9, 25);

  test('window is the 7 days ending today; older and deleted meals ignored',
      () {
    final recap = buildWeeklyRecap(
      meals: [
        meal(DateTime(2026, 9, 25, 12), kcal: 600),
        meal(DateTime(2026, 9, 19, 8), kcal: 400),
        meal(DateTime(2026, 9, 18, 20), kcal: 9999),
        meal(DateTime(2026, 9, 24, 13), kcal: 9999, deleted: true),
      ],
      today: today,
      streak: _streak,
    );
    expect(recap.start, DateTime(2026, 9, 19));
    expect(recap.end, DateTime(2026, 9, 25));
    expect(recap.mealCount, 2);
    expect(recap.daysLogged, 2);
    expect(recap.dailyKcal, [400, 0, 0, 0, 0, 0, 600]);
  });

  test('average kcal is per logged day', () {
    final recap = buildWeeklyRecap(
      meals: [
        meal(DateTime(2026, 9, 25, 8), kcal: 500),
        meal(DateTime(2026, 9, 25, 13), kcal: 1000),
        meal(DateTime(2026, 9, 23, 13), kcal: 1500),
      ],
      today: today,
      streak: _streak,
    );
    expect(recap.avgKcal, 1500);
  });

  test('protein days hit at 90% of target', () {
    final recap = buildWeeklyRecap(
      meals: [
        meal(DateTime(2026, 9, 25, 8), protein: 60),
        meal(DateTime(2026, 9, 25, 18), protein: 50), // 110 ≥ 108
        meal(DateTime(2026, 9, 24, 8), protein: 100), // < 108
        meal(DateTime(2026, 9, 23, 8), protein: 130),
      ],
      today: today,
      streak: _streak,
      proteinTargetG: 120,
    );
    expect(recap.proteinDaysHit, 2);
    expect(recap.proteinTargetG, 120);
  });

  test('no protein target leaves protein page data null', () {
    final recap = buildWeeklyRecap(
      meals: [meal(DateTime(2026, 9, 25, 8))],
      today: today,
      streak: _streak,
    );
    expect(recap.proteinDaysHit, isNull);
  });

  test('top meal prefers photo meals, then highest kcal', () {
    final photo = meal(DateTime(2026, 9, 22), kcal: 700, photo: 'a1');
    final recap = buildWeeklyRecap(
      meals: [
        meal(DateTime(2026, 9, 21), kcal: 1200),
        photo,
        meal(DateTime(2026, 9, 23), kcal: 300, photo: 'a2'),
      ],
      today: today,
      streak: _streak,
    );
    expect(recap.topMeal, same(photo));
  });

  test('most-logged food counts items case-insensitively', () {
    final recap = buildWeeklyRecap(
      meals: [
        meal(DateTime(2026, 9, 20), items: ['dal', 'Rice']),
        meal(DateTime(2026, 9, 21), items: ['Dal']),
        meal(DateTime(2026, 9, 24), items: ['Dal ', 'rice']),
      ],
      today: today,
      streak: _streak,
    );
    expect(recap.mostLogged!.name, 'Dal');
    expect(recap.mostLogged!.count, 3);
  });

  test('most-logged falls back to meal titles, and needs a repeat', () {
    final titles = buildWeeklyRecap(
      meals: [
        meal(DateTime(2026, 9, 20), title: 'Oats'),
        meal(DateTime(2026, 9, 21), title: 'oats'),
      ],
      today: today,
      streak: _streak,
    );
    expect(titles.mostLogged!.count, 2);

    final once = buildWeeklyRecap(
      meals: [meal(DateTime(2026, 9, 20), title: 'Oats')],
      today: today,
      streak: _streak,
    );
    expect(once.mostLogged, isNull);
  });

  test('empty week', () {
    final recap =
        buildWeeklyRecap(meals: const [], today: today, streak: _streak);
    expect(recap.isEmpty, isTrue);
    expect(recap.avgKcal, 0);
    expect(recap.topMeal, isNull);
  });

  test('dayOf lets callers bucket by user timezone', () {
    final recap = buildWeeklyRecap(
      meals: [meal(DateTime.utc(2026, 9, 25, 23, 30))],
      today: DateTime(2026, 9, 26),
      streak: _streak,
      dayOf: (_) => DateTime(2026, 9, 26),
    );
    expect(recap.dailyKcal.last, 500);
  });
}
