import 'package:flutter/foundation.dart' show immutable;
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

/// Time window the Progress tab summarises.
enum ProgressRange {
  week(7, '7D', '7 days'),
  month(30, '30D', '30 days'),
  quarter(90, '90D', '90 days');

  const ProgressRange(this.days, this.short, this.label);
  final int days;
  final String short;
  final String label;
}

/// One calendar day of intake (zeros when nothing was logged).
@immutable
class DayIntake {
  const DayIntake({
    required this.day,
    this.kcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.mealCount = 0,
  });

  final DateTime day;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int mealCount;

  bool get logged => mealCount > 0 || kcal > 0;
}

@immutable
class IntakeSummary {
  const IntakeSummary({required this.days});

  /// Every day in the window, oldest first, including unlogged days.
  final List<DayIntake> days;

  List<DayIntake> get loggedDays => [
        for (final d in days)
          if (d.logged) d
      ];
  int get daysLogged => loggedDays.length;

  /// Averages are over *logged* days only — an unlogged day is missing data,
  /// not a zero-calorie day.
  double get avgKcal => _avg((d) => d.kcal);
  double get avgProteinG => _avg((d) => d.proteinG);
  double get avgCarbsG => _avg((d) => d.carbsG);
  double get avgFatG => _avg((d) => d.fatG);

  double _avg(double Function(DayIntake) pick) {
    final logged = loggedDays;
    if (logged.isEmpty) return 0;
    return logged.map(pick).reduce((a, b) => a + b) / logged.length;
  }
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// Lays [rollups] onto a dense list of [days] days ending on [end] (inclusive).
IntakeSummary summarizeIntake(
  List<DailyRollup> rollups, {
  required DateTime end,
  required int days,
}) {
  final byDay = {for (final r in rollups) _day(r.day): r};
  final last = _day(end);
  return IntakeSummary(
    days: [
      for (var i = days - 1; i >= 0; i--)
        () {
          final day = DateTime(last.year, last.month, last.day - i);
          final r = byDay[day];
          return r == null
              ? DayIntake(day: day)
              : DayIntake(
                  day: day,
                  kcal: r.caloriesKcal,
                  proteinG: r.proteinG,
                  carbsG: r.carbsG,
                  fatG: r.fatG,
                  mealCount: r.mealCount,
                );
        }(),
    ],
  );
}

/// The user's active daily targets. Any value may be missing — the UI then
/// asks the user to set targets instead of silently inventing defaults.
@immutable
class ProgressTargets {
  const ProgressTargets({this.kcal, this.proteinG, this.carbsG, this.fatG});

  final double? kcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  static double? _valid(double? v) => v == null || v <= 0 ? null : v;

  double? get validKcal => _valid(kcal);
  bool get hasMacros =>
      _valid(proteinG) != null &&
      _valid(carbsG) != null &&
      _valid(fatG) != null;
  bool get isEmpty => validKcal == null && !hasMacros;
}
