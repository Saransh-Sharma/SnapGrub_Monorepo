import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

/// Daily smoothing factor for the weight trend (exponential moving average).
///
/// 0.15 sits in the commonly used 0.1–0.25 band (Hacker's Diet uses 0.1,
/// Happy Scale ~0.1–0.2): noisy day-to-day water swings barely move the line,
/// but a real change shows up within about a week (half-life ≈ 4.3 days).
///
/// The factor is *time-aware*: for a gap of `g` days between weigh-ins the
/// effective factor is `1 - (1 - alpha)^g`, so a single weigh-in after a
/// week away counts as much as a week of daily weigh-ins would have.
const double kWeightTrendAlpha = 0.15;

/// Minimum trend movement (kg/day) that counts as "moving" for projections.
/// 0.005 kg/day ≈ 35 g/week — below that the trend is effectively flat.
const double kFlatSlopeKgPerDay = 0.005;

/// A single raw weigh-in.
@immutable
class WeightSample {
  const WeightSample({required this.at, required this.kg});

  final DateTime at;
  final double kg;
}

/// One day on the trend: the (averaged) raw weigh-in and the smoothed value.
@immutable
class WeightPoint {
  const WeightPoint({required this.day, required this.raw, required this.trend});

  final DateTime day;
  final double raw;
  final double trend;
}

enum TrendDirection { down, up }

@immutable
class WeightTrend {
  const WeightTrend({
    required this.points,
    required this.slopePerDay,
    required this.newTrendBest,
    required this.direction,
  });

  static const empty = WeightTrend(
    points: [],
    slopePerDay: null,
    newTrendBest: false,
    direction: TrendDirection.down,
  );

  /// One point per day with a weigh-in, oldest first.
  final List<WeightPoint> points;

  /// Trend change per day (kg) from a least-squares fit over recent points.
  /// Null when there is not enough history to say.
  final double? slopePerDay;

  /// True when the latest trend value is the best seen so far in [direction]
  /// (a new low while losing, a new high while gaining).
  final bool newTrendBest;

  /// Which way "progress" points: down unless the goal is above the start.
  final TrendDirection direction;

  bool get isEmpty => points.isEmpty;
  double? get latestTrend => points.isEmpty ? null : points.last.trend;
  double? get latestRaw => points.isEmpty ? null : points.last.raw;
  double? get startRaw => points.isEmpty ? null : points.first.raw;

  /// Points whose day is on or after [from].
  List<WeightPoint> since(DateTime from) =>
      [for (final p in points) if (!p.day.isBefore(from)) p];
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// Builds the EMA trend from raw weigh-ins (any order, any count per day).
///
/// Multiple weigh-ins on the same day are averaged first. The first trend
/// value equals the first raw value. See [kWeightTrendAlpha].
WeightTrend computeWeightTrend(
  List<WeightSample> samples, {
  double alpha = kWeightTrendAlpha,
  double? goalKg,
  int slopeWindowDays = 28,
}) {
  if (samples.isEmpty) return WeightTrend.empty;
  final byDay = <DateTime, List<double>>{};
  for (final s in samples) {
    byDay.putIfAbsent(_day(s.at), () => []).add(s.kg);
  }
  final days = byDay.keys.toList()..sort();
  final points = <WeightPoint>[];
  for (final day in days) {
    final values = byDay[day]!;
    final raw = values.reduce((a, b) => a + b) / values.length;
    if (points.isEmpty) {
      points.add(WeightPoint(day: day, raw: raw, trend: raw));
      continue;
    }
    final prev = points.last;
    final gap = math.max(1, day.difference(prev.day).inDays);
    final a = 1 - math.pow(1 - alpha, gap).toDouble();
    points.add(WeightPoint(
      day: day,
      raw: raw,
      trend: prev.trend + a * (raw - prev.trend),
    ));
  }

  final direction = goalKg != null && goalKg > points.first.raw
      ? TrendDirection.up
      : TrendDirection.down;

  var newBest = false;
  if (points.length >= 3) {
    final latest = points.last.trend;
    final previous = points.sublist(0, points.length - 1).map((p) => p.trend);
    newBest = direction == TrendDirection.down
        ? previous.every((t) => latest < t - 0.01)
        : previous.every((t) => latest > t + 0.01);
  }

  return WeightTrend(
    points: List.unmodifiable(points),
    slopePerDay: _slope(points, slopeWindowDays),
    newTrendBest: newBest,
    direction: direction,
  );
}

/// Least-squares slope of trend vs. day over the last [windowDays]. Needs at
/// least two points spanning five or more days.
double? _slope(List<WeightPoint> points, int windowDays) {
  if (points.length < 2) return null;
  final last = points.last.day;
  final window = [
    for (final p in points)
      if (last.difference(p.day).inDays <= windowDays) p,
  ];
  if (window.length < 2) return null;
  final span = window.last.day.difference(window.first.day).inDays;
  if (span < 5) return null;
  final origin = window.first.day;
  final xs = [for (final p in window) p.day.difference(origin).inDays.toDouble()];
  final ys = [for (final p in window) p.trend];
  final n = xs.length;
  final mx = xs.reduce((a, b) => a + b) / n;
  final my = ys.reduce((a, b) => a + b) / n;
  var num = 0.0;
  var den = 0.0;
  for (var i = 0; i < n; i++) {
    num += (xs[i] - mx) * (ys[i] - my);
    den += (xs[i] - mx) * (xs[i] - mx);
  }
  if (den == 0) return null;
  return num / den;
}

enum ProjectionStatus {
  /// No goal weight set.
  noGoal,

  /// Not enough weigh-ins to estimate a pace.
  needsData,

  /// The trend has reached the goal.
  reached,

  /// Trend is moving toward the goal; [GoalProjection.date] is set.
  onPace,

  /// Trend is holding steady.
  flat,

  /// Trend is currently moving away from the goal.
  awayFromGoal,

  /// At the current pace the goal is more than two years out.
  tooFar,
}

@immutable
class GoalProjection {
  const GoalProjection(this.status, {this.date, this.weeklyChangeKg});

  final ProjectionStatus status;
  final DateTime? date;

  /// Current trend pace in kg per week (signed), when known.
  final double? weeklyChangeKg;
}

/// Tolerance (kg) within which the trend counts as "at goal".
const double kGoalToleranceKg = 0.2;

/// Projects the date the trend reaches [goalKg] at the current pace.
GoalProjection projectGoal(WeightTrend trend, double? goalKg) {
  if (goalKg == null) return const GoalProjection(ProjectionStatus.noGoal);
  final latest = trend.latestTrend;
  if (latest == null) return const GoalProjection(ProjectionStatus.needsData);
  final remaining = goalKg - latest;
  final reached = trend.direction == TrendDirection.down
      ? latest <= goalKg + kGoalToleranceKg
      : latest >= goalKg - kGoalToleranceKg;
  if (reached) return const GoalProjection(ProjectionStatus.reached);
  final slope = trend.slopePerDay;
  if (slope == null) return const GoalProjection(ProjectionStatus.needsData);
  final weekly = slope * 7;
  if (slope.abs() < kFlatSlopeKgPerDay) {
    return GoalProjection(ProjectionStatus.flat, weeklyChangeKg: weekly);
  }
  if (slope.sign != remaining.sign) {
    return GoalProjection(ProjectionStatus.awayFromGoal,
        weeklyChangeKg: weekly);
  }
  final days = remaining / slope;
  if (days > 730) {
    return GoalProjection(ProjectionStatus.tooFar, weeklyChangeKg: weekly);
  }
  return GoalProjection(
    ProjectionStatus.onPace,
    date: trend.points.last.day.add(Duration(days: days.ceil())),
    weeklyChangeKg: weekly,
  );
}

/// Fraction (0..1) of the way from [startKg] to [goalKg] at [currentKg].
/// Within [kGoalToleranceKg] of the goal counts as complete.
double goalProgress({
  required double startKg,
  required double currentKg,
  required double goalKg,
}) {
  if ((goalKg - currentKg).abs() <= kGoalToleranceKg) return 1;
  final total = startKg - goalKg;
  if (total.abs() < 1e-6) return 1;
  return ((startKg - currentKg) / total).clamp(0.0, 1.0);
}
