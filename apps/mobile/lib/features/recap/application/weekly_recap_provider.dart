import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/time/user_day.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/milestones/application/streak_provider.dart';
import 'package:snapgrub/features/recap/domain/weekly_recap.dart';

/// The last seven user-days (ending today) as a story-ready recap.
final weeklyRecapProvider = Provider<AsyncValue<WeeklyRecap?>>((ref) {
  final userAsync = ref.watch(homeUserContextProvider);
  final mealsAsync = ref.watch(allMealsProvider);
  if (userAsync.hasError) {
    return AsyncError(userAsync.error!, userAsync.stackTrace!);
  }
  if (mealsAsync.hasError) {
    return AsyncError(mealsAsync.error!, mealsAsync.stackTrace!);
  }
  if (!userAsync.hasValue || !mealsAsync.hasValue) return const AsyncLoading();
  final user = userAsync.requireValue;
  if (user == null) return const AsyncData(null);
  final today = ref.watch(userDayTickProvider(user.timezone));
  return AsyncData(buildWeeklyRecap(
    meals: mealsAsync.requireValue,
    today: today,
    streak: ref.watch(streakProvider),
    proteinTargetG: user.proteinGoal,
    dayOf: (loggedAt) => userDayFor(loggedAt, user.timezone).day,
  ));
});
