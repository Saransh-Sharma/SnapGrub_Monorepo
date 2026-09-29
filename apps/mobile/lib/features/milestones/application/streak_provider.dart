import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/milestones/domain/streak.dart';

/// Days (user-local, date-only) that have at least one logged meal.
final loggedDaysProvider = Provider<Set<DateTime>>((ref) {
  final meals = ref.watch(allMealsProvider).valueOrNull ?? const [];
  return {
    for (final meal in meals)
      if (!meal.isDeleted) DateUtils.dateOnly(meal.loggedAt.toLocal()),
  };
});

final streakProvider = Provider<StreakSummary>((ref) {
  final user = ref.watch(homeUserContextProvider).valueOrNull;
  if (user == null) return StreakSummary.empty;
  final today = ref.watch(userDayTickProvider(user.timezone));
  return computeStreak(ref.watch(loggedDaysProvider), today);
});
