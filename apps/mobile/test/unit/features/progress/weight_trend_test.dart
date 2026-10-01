import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/progress/domain/intake_summary.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/progress/domain/weight_trend.dart';

WeightSample w(DateTime at, double kg) => WeightSample(at: at, kg: kg);

void main() {
  group('computeWeightTrend (EMA)', () {
    test('empty input gives an empty trend', () {
      final trend = computeWeightTrend(const []);
      expect(trend.isEmpty, isTrue);
      expect(trend.latestTrend, isNull);
    });

    test('first trend value equals the first raw value', () {
      final trend = computeWeightTrend([w(DateTime(2026, 9, 1, 7), 80)]);
      expect(trend.points.single.trend, 80);
      expect(trend.points.single.raw, 80);
    });

    test('daily EMA follows trend += alpha * (raw - trend)', () {
      final trend = computeWeightTrend(
        [
          w(DateTime(2026, 9, 1), 80),
          w(DateTime(2026, 9, 2), 79),
          w(DateTime(2026, 9, 3), 81),
        ],
        alpha: .15,
      );
      final t1 = 80 + .15 * (79 - 80);
      final t2 = t1 + .15 * (81 - t1);
      expect(trend.points[1].trend, closeTo(t1, 1e-9));
      expect(trend.points[2].trend, closeTo(t2, 1e-9));
    });

    test('same-day weigh-ins are averaged first', () {
      final trend = computeWeightTrend([
        w(DateTime(2026, 9, 1, 7), 80),
        w(DateTime(2026, 9, 1, 21), 81),
      ]);
      expect(trend.points, hasLength(1));
      expect(trend.points.single.raw, 80.5);
    });

    test('gaps compound the smoothing factor (time-aware alpha)', () {
      final trend = computeWeightTrend(
        [w(DateTime(2026, 9, 1), 80), w(DateTime(2026, 9, 8), 78)],
        alpha: .15,
      );
      final a = 1 - math.pow(.85, 7);
      expect(trend.points.last.trend, closeTo(80 + a * (78 - 80), 1e-9));
    });

    test('input order does not matter', () {
      final a = computeWeightTrend([
        w(DateTime(2026, 9, 3), 79),
        w(DateTime(2026, 9, 1), 80),
        w(DateTime(2026, 9, 2), 79.5),
      ]);
      expect(a.points.map((p) => p.day.day), [1, 2, 3]);
    });

    test('smooths noise: a single spike barely moves the trend', () {
      final trend = computeWeightTrend([
        for (var i = 0; i < 10; i++) w(DateTime(2026, 9, 1 + i), 80),
        w(DateTime(2026, 9, 11), 83),
      ]);
      expect(trend.latestTrend, lessThan(80.5));
    });

    test('newTrendBest flags a new low while losing', () {
      final trend = computeWeightTrend([
        for (var i = 0; i < 6; i++) w(DateTime(2026, 9, 1 + i), 80 - i * .3),
      ], goalKg: 75);
      expect(trend.direction, TrendDirection.down);
      expect(trend.newTrendBest, isTrue);
    });

    test('newTrendBest is false after a bounce up', () {
      final trend = computeWeightTrend([
        for (var i = 0; i < 6; i++) w(DateTime(2026, 9, 1 + i), 80 - i * .3),
        w(DateTime(2026, 9, 7), 82),
      ], goalKg: 75);
      expect(trend.newTrendBest, isFalse);
    });

    test('direction is up when the goal is above the start', () {
      final trend = computeWeightTrend([
        for (var i = 0; i < 5; i++) w(DateTime(2026, 9, 1 + i), 60 + i * .2),
      ], goalKg: 65);
      expect(trend.direction, TrendDirection.up);
      expect(trend.newTrendBest, isTrue);
    });

    test('slope needs at least five days of span', () {
      final short = computeWeightTrend([
        w(DateTime(2026, 9, 1), 80),
        w(DateTime(2026, 9, 3), 79),
      ]);
      expect(short.slopePerDay, isNull);
    });

    test('slope of a steady decline is negative', () {
      final trend = computeWeightTrend([
        for (var i = 0; i < 21; i++) w(DateTime(2026, 9, 1 + i), 80 - i * .1),
      ]);
      expect(trend.slopePerDay, isNotNull);
      expect(trend.slopePerDay!, lessThan(0));
    });

    test('since() filters by day', () {
      final trend = computeWeightTrend([
        for (var i = 0; i < 10; i++) w(DateTime(2026, 9, 1 + i), 80),
      ]);
      expect(trend.since(DateTime(2026, 9, 8)), hasLength(3));
    });
  });

  group('projectGoal', () {
    WeightTrend losing({int days = 28, double perDay = .1}) =>
        computeWeightTrend([
          for (var i = 0; i < days; i++)
            w(DateTime(2026, 8, 1).add(Duration(days: i)), 90 - i * perDay),
        ], goalKg: 80);

    test('no goal', () {
      expect(projectGoal(losing(), null).status, ProjectionStatus.noGoal);
    });

    test('on pace projects a future date consistent with the slope', () {
      final trend = losing();
      final p = projectGoal(trend, 80);
      expect(p.status, ProjectionStatus.onPace);
      final expectedDays = (80 - trend.latestTrend!) / trend.slopePerDay!;
      expect(
        p.date,
        trend.points.last.day.add(Duration(days: expectedDays.ceil())),
      );
      expect(p.weeklyChangeKg!, lessThan(0));
    });

    test('reached when the trend is within tolerance of the goal', () {
      final trend = computeWeightTrend([
        for (var i = 0; i < 20; i++)
          w(DateTime(2026, 8, 1).add(Duration(days: i)), 80.1),
      ], goalKg: 80);
      expect(projectGoal(trend, 80).status, ProjectionStatus.reached);
    });

    test('flat when the trend barely moves', () {
      final trend = computeWeightTrend([
        for (var i = 0; i < 20; i++)
          w(DateTime(2026, 8, 1).add(Duration(days: i)), 85),
      ], goalKg: 80);
      expect(projectGoal(trend, 80).status, ProjectionStatus.flat);
    });

    test('away from goal when trending the other way', () {
      final trend = computeWeightTrend([
        for (var i = 0; i < 20; i++)
          w(DateTime(2026, 8, 1).add(Duration(days: i)), 85 + i * .1),
      ], goalKg: 80);
      expect(projectGoal(trend, 80).status, ProjectionStatus.awayFromGoal);
    });

    test('too far when more than two years out', () {
      final trend = losing(perDay: .02);
      expect(projectGoal(trend, 40).status, ProjectionStatus.tooFar);
    });

    test('needs data with a single weigh-in', () {
      final trend =
          computeWeightTrend([w(DateTime(2026, 8, 1), 90)], goalKg: 80);
      expect(projectGoal(trend, 80).status, ProjectionStatus.needsData);
    });
  });

  group('goalProgress', () {
    test('fraction of the way from start to goal', () {
      expect(goalProgress(startKg: 90, currentKg: 85, goalKg: 80), .5);
      expect(goalProgress(startKg: 60, currentKg: 62.5, goalKg: 70), .25);
    });

    test('clamps and treats near-goal as complete', () {
      expect(goalProgress(startKg: 90, currentKg: 92, goalKg: 80), 0);
      expect(goalProgress(startKg: 90, currentKg: 80.1, goalKg: 80), 1);
    });
  });

  group('summarizeIntake', () {
    DailyRollup r(DateTime day, double kcal, {double p = 0, int meals = 1}) =>
        DailyRollup(
          userId: 'u',
          day: day,
          caloriesKcal: kcal,
          proteinG: p,
          carbsG: 0,
          fatG: 0,
          mealCount: meals,
          hasPhotoMeal: false,
        );

    test('fills a dense window ending on the end day', () {
      final s = summarizeIntake(
        [r(DateTime(2026, 9, 24), 1800), r(DateTime(2026, 9, 20), 2200)],
        end: DateTime(2026, 9, 25),
        days: 7,
      );
      expect(s.days, hasLength(7));
      expect(s.days.first.day, DateTime(2026, 9, 19));
      expect(s.days.last.day, DateTime(2026, 9, 25));
      expect(s.daysLogged, 2);
    });

    test('averages over logged days only', () {
      final s = summarizeIntake(
        [
          r(DateTime(2026, 9, 24), 1800, p: 100),
          r(DateTime(2026, 9, 25), 2200, p: 120),
        ],
        end: DateTime(2026, 9, 25),
        days: 30,
      );
      expect(s.avgKcal, 2000);
      expect(s.avgProteinG, 110);
    });

    test('empty window averages to zero', () {
      final s = summarizeIntake(const [], end: DateTime(2026, 9, 25), days: 7);
      expect(s.avgKcal, 0);
      expect(s.daysLogged, 0);
    });

    test('ProgressTargets treats missing or zero values as unset', () {
      expect(const ProgressTargets().isEmpty, isTrue);
      expect(const ProgressTargets(kcal: 0).validKcal, isNull);
      expect(
        const ProgressTargets(kcal: 2000, proteinG: 120, carbsG: 200, fatG: 60)
            .hasMacros,
        isTrue,
      );
    });
  });
}
