import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/milestones/application/streak_provider.dart';
import 'package:snapgrub/features/milestones/data/milestone_store.dart';
import 'package:snapgrub/features/milestones/domain/milestone.dart';
import 'package:snapgrub/features/progress/data/body_measurement_repository.dart';
import 'package:snapgrub/features/progress/data/goal_weight_store.dart';
import 'package:snapgrub/features/progress/domain/weight_trend.dart';

final templateStatsProvider = StreamProvider<TemplateStats>((ref) async* {
  final user = await ref.watch(homeUserContextProvider.future);
  if (user == null) {
    yield (count: 0, firstCreatedAt: null);
    return;
  }
  yield* watchTemplateStats(ref.watch(appDatabaseProvider), user.userId);
});

/// Everything the milestone rules need, loaded together. Stays loading until
/// every source has produced data so milestones are never judged on a
/// half-loaded picture (which would mis-detect "newly earned").
final milestoneFactsProvider = Provider<AsyncValue<MilestoneFacts>>((ref) {
  final meals = ref.watch(allMealsProvider);
  final weights = ref.watch(weightEntriesProvider);
  final goal = ref.watch(goalWeightProvider);
  final templates = ref.watch(templateStatsProvider);
  for (final value in [meals, weights, goal, templates]) {
    if (value.hasError) return AsyncError(value.error!, value.stackTrace!);
  }
  if (!meals.hasValue ||
      !weights.hasValue ||
      !goal.hasValue ||
      !templates.hasValue) {
    return const AsyncLoading();
  }
  final live = [
    for (final m in meals.requireValue)
      if (!m.isDeleted) m
  ];
  return AsyncData(MilestoneFacts(
    mealTimes: [for (final m in live) m.loggedAt.toLocal()],
    loggedDays: ref.watch(loggedDaysProvider),
    weights: [
      for (final w in weights.requireValue)
        WeightSample(at: w.measuredAt, kg: w.weightKg),
    ],
    goalWeightKg: goal.requireValue,
    templateCount: templates.requireValue.count,
    firstTemplateAt: templates.requireValue.firstCreatedAt,
  ));
});

/// Every milestone with its earned state, in gallery order.
final milestonesProvider = Provider<AsyncValue<List<MilestoneStatus>>>((ref) {
  return ref.watch(milestoneFactsProvider).whenData(evaluateMilestones);
});

/// Earned milestones, most recent first (for the Progress shelf).
final earnedMilestonesProvider = Provider<List<MilestoneStatus>>((ref) {
  final all = ref.watch(milestonesProvider).valueOrNull ?? const [];
  final earned = [
    for (final m in all)
      if (m.earned) m
  ];
  earned.sort((a, b) {
    final at = a.earnedAt;
    final bt = b.earnedAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });
  return earned;
});

/// Celebrated-milestone ids for the signed-in user. `null` inside the data
/// means "never evaluated on this install".
final celebratedMilestonesProvider =
    AsyncNotifierProvider<CelebratedMilestones, Set<String>?>(
  CelebratedMilestones.new,
);

class CelebratedMilestones extends AsyncNotifier<Set<String>?> {
  String? _userId;

  @override
  Future<Set<String>?> build() async {
    final user = await ref.watch(homeUserContextProvider.future);
    _userId = user?.userId;
    if (_userId == null) return <String>{};
    return ref.watch(milestoneStoreProvider).celebrated(_userId!);
  }

  /// Marks [ids] as celebrated (persisted before any animation plays, so a
  /// milestone fires exactly once even if the app is killed mid-toast).
  Future<void> mark(Iterable<String> ids) async {
    final userId = _userId;
    if (userId == null) return;
    final next =
        await ref.read(milestoneStoreProvider).markCelebrated(userId, ids);
    state = AsyncData(next);
  }
}

/// Milestones earned but not yet celebrated. Empty until both the facts and
/// the celebrated set are loaded, and empty on a never-evaluated install
/// (the celebrator seeds that case silently).
final pendingMilestoneCelebrationsProvider =
    Provider<List<MilestoneStatus>>((ref) {
  final statuses = ref.watch(milestonesProvider).valueOrNull;
  final celebrated = ref.watch(celebratedMilestonesProvider);
  if (statuses == null || !celebrated.hasValue) return const [];
  final set = celebrated.requireValue;
  if (set == null) return const [];
  return newlyEarned(statuses, set);
});
