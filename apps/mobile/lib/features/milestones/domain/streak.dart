import 'package:flutter/material.dart' show DateUtils, immutable;
import 'package:snapgrub/core/design_system/tokens.dart';

/// Medal tier for a logging streak. Streaks count days *logged*, never days
/// "on target" (adherence-neutral).
enum StreakTier {
  none(0, null),
  silver(3, SgMetal.silver),
  copper(7, SgMetal.copper),
  gold(30, SgMetal.gold),
  holo(100, SgMetal.gold);

  const StreakTier(this.minDays, this.metal);
  final int minDays;
  final SgMetal? metal;

  static StreakTier forDays(int days) {
    var tier = StreakTier.none;
    for (final t in StreakTier.values) {
      if (days >= t.minDays) tier = t;
    }
    return tier;
  }
}

@immutable
class StreakSummary {
  const StreakSummary({
    required this.current,
    required this.best,
    required this.loggedToday,
    required this.frozenDays,
  });

  static const empty = StreakSummary(
      current: 0, best: 0, loggedToday: false, frozenDays: <DateTime>{});

  final int current;
  final int best;
  final bool loggedToday;

  /// Days bridged by the automatic weekly freeze.
  final Set<DateTime> frozenDays;

  StreakTier get tier => StreakTier.forDays(current);
}

/// Computes a logging streak from the set of days that have at least one meal.
///
/// Rules:
/// * Today not being logged *yet* never breaks the streak.
/// * One missed day per ISO week is bridged automatically (a "freeze").
StreakSummary computeStreak(Set<DateTime> loggedDays, DateTime today) {
  final days = {for (final d in loggedDays) DateUtils.dateOnly(d)};
  final t = DateUtils.dateOnly(today);
  final loggedToday = days.contains(t);

  int run(DateTime start, Set<DateTime> frozen) {
    var count = 0;
    var cursor = start;
    final freezesByWeek = <int>{};
    while (true) {
      if (days.contains(cursor)) {
        count++;
      } else {
        final week = _isoWeekKey(cursor);
        final previous = cursor.subtract(const Duration(days: 1));
        // A freeze only bridges a single gap between logged days.
        if (!freezesByWeek.contains(week) && days.contains(previous) && count > 0) {
          freezesByWeek.add(week);
          frozen.add(cursor);
        } else {
          break;
        }
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  final frozen = <DateTime>{};
  final start = loggedToday ? t : t.subtract(const Duration(days: 1));
  final current = run(start, frozen);

  var best = current;
  final sorted = days.toList()..sort();
  var streak = 0;
  DateTime? prev;
  for (final day in sorted) {
    if (prev != null && day.difference(prev).inDays == 1) {
      streak++;
    } else if (prev != null && day.difference(prev).inDays == 2) {
      streak += 1; // freeze-bridged gap
    } else {
      streak = 1;
    }
    if (streak > best) best = streak;
    prev = day;
  }

  return StreakSummary(
    current: current,
    best: best,
    loggedToday: loggedToday,
    frozenDays: frozen,
  );
}

int _isoWeekKey(DateTime day) {
  final monday = day.subtract(Duration(days: day.weekday - 1));
  return monday.year * 1000 + monday.difference(DateTime(monday.year)).inDays;
}
