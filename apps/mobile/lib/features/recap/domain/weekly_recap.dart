import 'package:flutter/foundation.dart' show immutable;
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/milestones/domain/streak.dart';

/// A day counts as "protein hit" at 90% of the target or more — close enough
/// to be a win, and consistent with the "near target" wording elsewhere.
const double kProteinHitRatio = .9;

@immutable
class RecapFood {
  const RecapFood({required this.name, required this.count});

  final String name;
  final int count;
}

@immutable
class WeeklyRecap {
  const WeeklyRecap({
    required this.start,
    required this.end,
    required this.dailyKcal,
    required this.daysLogged,
    required this.mealCount,
    required this.avgKcal,
    required this.streak,
    this.topMeal,
    this.mostLogged,
    this.proteinTargetG,
    this.proteinDaysHit,
  });

  /// First and last day of the recap window (date-only, inclusive).
  final DateTime start;
  final DateTime end;

  /// Calories per day in the window, oldest first (7 values).
  final List<double> dailyKcal;
  final int daysLogged;
  final int mealCount;

  /// Average over logged days only.
  final double avgKcal;
  final StreakSummary streak;

  /// Hero meal: the biggest meal that has a photo, else the biggest meal.
  final Meal? topMeal;

  /// Most repeated food, when something was logged at least twice.
  final RecapFood? mostLogged;
  final double? proteinTargetG;

  /// Logged days that reached [kProteinHitRatio] of the protein target.
  /// Null when there is no protein target.
  final int? proteinDaysHit;

  bool get isEmpty => mealCount == 0;
}

DateTime _date(DateTime t) => DateTime(t.year, t.month, t.day);

/// Aggregates the 7 days ending on [today] (inclusive) into a recap.
///
/// [dayOf] maps a meal's `loggedAt` to its calendar day; it defaults to the
/// device-local date. Pass a user-timezone mapping in production.
WeeklyRecap buildWeeklyRecap({
  required List<Meal> meals,
  required DateTime today,
  required StreakSummary streak,
  double? proteinTargetG,
  DateTime Function(DateTime loggedAt)? dayOf,
}) {
  final toDay = dayOf ?? (DateTime t) => _date(t.toLocal());
  final end = _date(today);
  final start = DateTime(end.year, end.month, end.day - 6);
  final inWeek = [
    for (final m in meals)
      if (!m.isDeleted &&
          !toDay(m.loggedAt).isBefore(start) &&
          !toDay(m.loggedAt).isAfter(end))
        m,
  ];

  final kcalByDay = <DateTime, double>{};
  final proteinByDay = <DateTime, double>{};
  for (final m in inWeek) {
    final d = _date(toDay(m.loggedAt));
    kcalByDay[d] = (kcalByDay[d] ?? 0) + m.caloriesKcal;
    proteinByDay[d] = (proteinByDay[d] ?? 0) + m.proteinG;
  }
  final daily = [
    for (var i = 0; i < 7; i++)
      kcalByDay[DateTime(start.year, start.month, start.day + i)] ?? 0.0,
  ];
  final daysLogged = kcalByDay.length;
  final avg = daysLogged == 0
      ? 0.0
      : kcalByDay.values.reduce((a, b) => a + b) / daysLogged;

  Meal? top;
  final withPhoto = [
    for (final m in inWeek)
      if (m.photoAssetId != null) m
  ];
  final pool = withPhoto.isNotEmpty ? withPhoto : inWeek;
  for (final m in pool) {
    if (top == null || m.caloriesKcal > top.caloriesKcal) top = m;
  }

  int? proteinHit;
  final target = proteinTargetG;
  if (target != null && target > 0) {
    proteinHit =
        proteinByDay.values.where((p) => p >= target * kProteinHitRatio).length;
  }

  return WeeklyRecap(
    start: start,
    end: end,
    dailyKcal: daily,
    daysLogged: daysLogged,
    mealCount: inWeek.length,
    avgKcal: avg,
    streak: streak,
    topMeal: top,
    mostLogged: _mostLogged(inWeek),
    proteinTargetG: target != null && target > 0 ? target : null,
    proteinDaysHit: proteinHit,
  );
}

/// Most frequent food by item name (case-insensitive); falls back to meal
/// titles for meals logged without items. Ties go to the most recent.
RecapFood? _mostLogged(List<Meal> meals) {
  RecapFood? pick(Iterable<(String, DateTime)> names) {
    final counts = <String, int>{};
    final display = <String, String>{};
    final latest = <String, DateTime>{};
    for (final (name, at) in names) {
      final key = name.trim().toLowerCase();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      final seen = latest[key];
      if (seen == null || at.isAfter(seen)) {
        latest[key] = at;
        display[key] = name.trim();
      }
    }
    String? best;
    for (final key in counts.keys) {
      if (best == null ||
          counts[key]! > counts[best]! ||
          (counts[key] == counts[best] &&
              latest[key]!.isAfter(latest[best]!))) {
        best = key;
      }
    }
    if (best == null || counts[best]! < 2) return null;
    return RecapFood(name: display[best]!, count: counts[best]!);
  }

  return pick([
        for (final m in meals)
          for (final item in m.items) (item.name, m.loggedAt),
      ]) ??
      pick([for (final m in meals) (m.title, m.loggedAt)]);
}
