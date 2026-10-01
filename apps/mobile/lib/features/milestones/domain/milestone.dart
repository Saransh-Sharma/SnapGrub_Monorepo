import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/tokens.dart';
import 'package:snapgrub/features/progress/domain/weight_trend.dart';

/// Medal finish. Holo is gold under a holographic foil layer.
enum MilestoneTier {
  silver(SgMetal.silver, 'Silver'),
  copper(SgMetal.copper, 'Copper'),
  gold(SgMetal.gold, 'Gold'),
  titanium(SgMetal.titanium, 'Titanium'),
  holo(SgMetal.gold, 'Holographic');

  const MilestoneTier(this.metal, this.label);
  final SgMetal metal;
  final String label;
}

enum MilestoneGroup {
  streak('Streaks'),
  logging('Logging'),
  body('Body'),
  library('Library');

  const MilestoneGroup(this.label);
  final String label;
}

@immutable
class MilestoneDefinition {
  const MilestoneDefinition({
    required this.id,
    required this.title,
    required this.howTo,
    required this.tier,
    required this.group,
    required this.icon,
    this.threshold = 1,
  });

  /// Stable id; used for persistence. Never rename.
  final String id;
  final String title;

  /// What earns it, written as an invitation.
  final String howTo;
  final MilestoneTier tier;
  final MilestoneGroup group;
  final IconData icon;
  final num threshold;
}

/// Every milestone, in gallery order. Goal-weight milestones measure progress
/// toward the target weight (on the smoothed trend), never daily adherence.
const List<MilestoneDefinition> kMilestones = [
  MilestoneDefinition(
    id: 'streak_3',
    title: '3-day streak',
    howTo: 'Log 3 days in a row.',
    tier: MilestoneTier.silver,
    group: MilestoneGroup.streak,
    icon: Icons.local_fire_department_rounded,
    threshold: 3,
  ),
  MilestoneDefinition(
    id: 'streak_7',
    title: '7-day streak',
    howTo: 'Log 7 days in a row.',
    tier: MilestoneTier.copper,
    group: MilestoneGroup.streak,
    icon: Icons.local_fire_department_rounded,
    threshold: 7,
  ),
  MilestoneDefinition(
    id: 'streak_30',
    title: '30-day streak',
    howTo: 'Log 30 days in a row.',
    tier: MilestoneTier.gold,
    group: MilestoneGroup.streak,
    icon: Icons.local_fire_department_rounded,
    threshold: 30,
  ),
  MilestoneDefinition(
    id: 'streak_100',
    title: '100-day streak',
    howTo: 'Log 100 days in a row.',
    tier: MilestoneTier.holo,
    group: MilestoneGroup.streak,
    icon: Icons.local_fire_department_rounded,
    threshold: 100,
  ),
  MilestoneDefinition(
    id: 'first_meal',
    title: 'First meal',
    howTo: 'Log your first meal.',
    tier: MilestoneTier.silver,
    group: MilestoneGroup.logging,
    icon: Icons.restaurant_rounded,
  ),
  MilestoneDefinition(
    id: 'meals_50',
    title: '50 meals',
    howTo: 'Log 50 meals.',
    tier: MilestoneTier.copper,
    group: MilestoneGroup.logging,
    icon: Icons.grid_view_rounded,
    threshold: 50,
  ),
  MilestoneDefinition(
    id: 'meals_250',
    title: '250 meals',
    howTo: 'Log 250 meals.',
    tier: MilestoneTier.gold,
    group: MilestoneGroup.logging,
    icon: Icons.auto_awesome_mosaic_rounded,
    threshold: 250,
  ),
  MilestoneDefinition(
    id: 'first_weight',
    title: 'First weigh-in',
    howTo: 'Log your weight.',
    tier: MilestoneTier.silver,
    group: MilestoneGroup.body,
    icon: Icons.monitor_weight_rounded,
  ),
  MilestoneDefinition(
    id: 'goal_25',
    title: 'A quarter of the way',
    howTo: 'Get 25% of the way to your goal weight.',
    tier: MilestoneTier.silver,
    group: MilestoneGroup.body,
    icon: Icons.flag_rounded,
    threshold: .25,
  ),
  MilestoneDefinition(
    id: 'goal_50',
    title: 'Halfway there',
    howTo: 'Get 50% of the way to your goal weight.',
    tier: MilestoneTier.copper,
    group: MilestoneGroup.body,
    icon: Icons.flag_rounded,
    threshold: .5,
  ),
  MilestoneDefinition(
    id: 'goal_75',
    title: 'Three quarters',
    howTo: 'Get 75% of the way to your goal weight.',
    tier: MilestoneTier.gold,
    group: MilestoneGroup.body,
    icon: Icons.flag_rounded,
    threshold: .75,
  ),
  MilestoneDefinition(
    id: 'goal_100',
    title: 'Goal reached',
    howTo: 'Reach your goal weight.',
    tier: MilestoneTier.holo,
    group: MilestoneGroup.body,
    icon: Icons.emoji_events_rounded,
    threshold: 1,
  ),
  MilestoneDefinition(
    id: 'first_template',
    title: 'First saved meal',
    howTo: 'Save a meal.',
    tier: MilestoneTier.titanium,
    group: MilestoneGroup.library,
    icon: Icons.bookmark_rounded,
  ),
];

MilestoneDefinition? milestoneById(String id) {
  for (final m in kMilestones) {
    if (m.id == id) return m;
  }
  return null;
}

/// Raw data the milestone rules look at.
@immutable
class MilestoneFacts {
  const MilestoneFacts({
    this.mealTimes = const [],
    this.loggedDays = const {},
    this.weights = const [],
    this.goalWeightKg,
    this.templateCount = 0,
    this.firstTemplateAt,
  });

  /// `loggedAt` of every non-deleted meal (any order).
  final List<DateTime> mealTimes;

  /// Days (date-only) with at least one meal.
  final Set<DateTime> loggedDays;
  final List<WeightSample> weights;
  final double? goalWeightKg;
  final int templateCount;
  final DateTime? firstTemplateAt;
}

@immutable
class MilestoneStatus {
  const MilestoneStatus({
    required this.definition,
    required this.earned,
    this.earnedAt,
    this.progress = 0,
    this.progressLabel,
  });

  final MilestoneDefinition definition;
  final bool earned;

  /// When the milestone was (first) earned, when known.
  final DateTime? earnedAt;

  /// 0..1 progress toward earning it.
  final double progress;

  /// Short progress text for locked medals ("4 of 7 days").
  final String? progressLabel;

  String get id => definition.id;
}

/// The first date on which a logging run reached each length in [targets].
///
/// Mirrors the "best streak" rule of `computeStreak`: consecutive days extend
/// a run, and a single missed day is bridged by the automatic freeze.
Map<int, DateTime> streakReachedDates(
    Set<DateTime> loggedDays, List<int> targets) {
  final days = {
    for (final d in loggedDays) DateTime(d.year, d.month, d.day),
  }.toList()
    ..sort();
  final result = <int, DateTime>{};
  var run = 0;
  DateTime? prev;
  for (final day in days) {
    final gap = prev == null ? 0 : day.difference(prev).inDays;
    run = (gap == 1 || gap == 2) ? run + 1 : 1;
    for (final t in targets) {
      if (run >= t) result.putIfAbsent(t, () => day);
    }
    prev = day;
  }
  return result;
}

int bestStreakRun(Set<DateTime> loggedDays) {
  final days = {
    for (final d in loggedDays) DateTime(d.year, d.month, d.day),
  }.toList()
    ..sort();
  var best = 0;
  var run = 0;
  DateTime? prev;
  for (final day in days) {
    final gap = prev == null ? 0 : day.difference(prev).inDays;
    run = (gap == 1 || gap == 2) ? run + 1 : 1;
    if (run > best) best = run;
    prev = day;
  }
  return best;
}

/// Evaluates every milestone against [facts]. Earned state is derived purely
/// from data, so it survives reinstalls and a broken streak keeps its medal.
List<MilestoneStatus> evaluateMilestones(MilestoneFacts facts) {
  final meals = [...facts.mealTimes]..sort();
  final streakTargets = [3, 7, 30, 100];
  final streakDates = streakReachedDates(facts.loggedDays, streakTargets);
  final best = bestStreakRun(facts.loggedDays);
  final weights = [...facts.weights]..sort((a, b) => a.at.compareTo(b.at));

  // Goal progress is measured on the EMA trend so one light morning can't
  // award a medal that the next heavy one would take back.
  final goal = facts.goalWeightKg;
  final trend = computeWeightTrend(weights, goalKg: goal);
  final goalDates = <double, DateTime>{};
  var goalFraction = 0.0;
  if (goal != null && trend.points.length >= 2) {
    final start = trend.points.first.raw;
    for (final p in trend.points.skip(1)) {
      final f = goalProgress(startKg: start, currentKg: p.trend, goalKg: goal);
      if (f > goalFraction) goalFraction = f;
      for (final t in const [.25, .5, .75, 1.0]) {
        if (f >= t - 1e-9) goalDates.putIfAbsent(t, () => p.day);
      }
    }
  }

  MilestoneStatus status(MilestoneDefinition def) {
    switch (def.id) {
      case 'first_meal':
        return MilestoneStatus(
          definition: def,
          earned: meals.isNotEmpty,
          earnedAt: meals.isEmpty ? null : meals.first,
          progress: meals.isEmpty ? 0 : 1,
        );
      case 'meals_50':
      case 'meals_250':
        final n = def.threshold.toInt();
        final earned = meals.length >= n;
        return MilestoneStatus(
          definition: def,
          earned: earned,
          earnedAt: earned ? meals[n - 1] : null,
          progress: (meals.length / n).clamp(0.0, 1.0),
          progressLabel: '${meals.length.clamp(0, n)} of $n meals',
        );
      case 'streak_3':
      case 'streak_7':
      case 'streak_30':
      case 'streak_100':
        final n = def.threshold.toInt();
        final at = streakDates[n];
        return MilestoneStatus(
          definition: def,
          earned: at != null,
          earnedAt: at,
          progress: (best / n).clamp(0.0, 1.0),
          progressLabel: 'Best: ${best.clamp(0, n)} of $n days',
        );
      case 'first_weight':
        return MilestoneStatus(
          definition: def,
          earned: weights.isNotEmpty,
          earnedAt: weights.isEmpty ? null : weights.first.at,
          progress: weights.isEmpty ? 0 : 1,
        );
      case 'goal_25':
      case 'goal_50':
      case 'goal_75':
      case 'goal_100':
        final t = def.threshold.toDouble();
        final at = goalDates[t];
        return MilestoneStatus(
          definition: def,
          earned: at != null,
          earnedAt: at,
          progress: goal == null ? 0 : (goalFraction / t).clamp(0.0, 1.0),
          progressLabel: goal == null
              ? 'Set a goal weight to start'
              : '${(goalFraction * 100).round()}% there',
        );
      case 'first_template':
        final earned = facts.templateCount > 0;
        return MilestoneStatus(
          definition: def,
          earned: earned,
          earnedAt: earned ? facts.firstTemplateAt : null,
          progress: earned ? 1 : 0,
        );
    }
    return MilestoneStatus(definition: def, earned: false);
  }

  return [for (final def in kMilestones) status(def)];
}

/// Earned milestones that have not been celebrated yet, oldest first.
List<MilestoneStatus> newlyEarned(
  List<MilestoneStatus> statuses,
  Set<String> celebrated,
) {
  final fresh = [
    for (final s in statuses)
      if (s.earned && !celebrated.contains(s.id)) s,
  ];
  fresh.sort((a, b) {
    final at = a.earnedAt;
    final bt = b.earnedAt;
    if (at == null || bt == null) return 0;
    return at.compareTo(bt);
  });
  return fresh;
}
