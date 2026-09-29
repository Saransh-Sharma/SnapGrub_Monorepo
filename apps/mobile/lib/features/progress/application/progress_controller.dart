import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/progress/data/body_measurement_repository.dart';
import 'package:snapgrub/features/progress/data/goal_weight_store.dart';
import 'package:snapgrub/features/progress/domain/intake_summary.dart';
import 'package:snapgrub/features/progress/domain/weight_trend.dart';

export 'package:snapgrub/features/progress/domain/intake_summary.dart'
    show ProgressRange;

/// Selected Progress range (7 / 30 / 90 days). Defaults to 30 days.
final progressRangeProvider =
    StateProvider<ProgressRange>((ref) => ProgressRange.month);

/// Whether the user prefers imperial units (lb) for body weight.
final prefersImperialProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileControllerProvider).valueOrNull?.profile;
  return profile?.unitSystem == 'imperial';
});

/// The user's active targets, or null while loading / signed out.
final progressTargetsProvider = Provider<ProgressTargets?>((ref) {
  final user = ref.watch(homeUserContextProvider).valueOrNull;
  if (user == null) return null;
  return ProgressTargets(
    kcal: user.calorieGoal,
    proteinG: user.proteinGoal,
    carbsG: user.carbsGoal,
    fatG: user.fatGoal,
  );
});

/// Dense per-day intake for a range, ending today (user timezone).
final intakeSummaryProvider =
    StreamProvider.family<IntakeSummary, ProgressRange>((ref, range) async* {
  final user = await ref.watch(homeUserContextProvider.future);
  if (user == null) {
    yield const IntakeSummary(days: []);
    return;
  }
  final today = ref.watch(userDayTickProvider(user.timezone));
  final start =
      DateTime(today.year, today.month, today.day - (range.days - 1));
  yield* ref
      .watch(mealRepositoryProvider)
      .watchRollupsBetween(user.userId, start, today)
      .map((rollups) =>
          summarizeIntake(rollups, end: today, days: range.days));
});

/// The EMA weight trend over the full history (so the line is warm at the
/// start of any range), with the goal weight folded in for direction.
final weightTrendProvider = Provider<AsyncValue<WeightTrend>>((ref) {
  final entries = ref.watch(weightEntriesProvider);
  final goal = ref.watch(goalWeightProvider);
  if (entries.hasError) {
    return AsyncError(entries.error!, entries.stackTrace!);
  }
  final list = entries.valueOrNull;
  if (list == null || goal.isLoading) return const AsyncLoading();
  return AsyncData(computeWeightTrend(
    [for (final e in list) WeightSample(at: e.measuredAt, kg: e.weightKg)],
    goalKg: goal.valueOrNull,
  ));
});

/// Projection of the goal date at the current trend pace.
final goalProjectionProvider = Provider<GoalProjection?>((ref) {
  final trend = ref.watch(weightTrendProvider).valueOrNull;
  if (trend == null) return null;
  return projectGoal(trend, ref.watch(goalWeightProvider).valueOrNull);
});
