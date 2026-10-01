import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/features/milestones/data/milestone_store.dart';
import 'package:snapgrub/features/milestones/domain/milestone.dart';
import 'package:snapgrub/features/progress/domain/weight_trend.dart';

MilestoneStatus byId(List<MilestoneStatus> all, String id) =>
    all.firstWhere((s) => s.id == id);

Set<DateTime> run(DateTime start, int days) => {
      for (var i = 0; i < days; i++)
        DateTime(start.year, start.month, start.day + i)
    };

void main() {
  test('every definition has a unique id and is evaluated', () {
    final ids = kMilestones.map((m) => m.id).toSet();
    expect(ids, hasLength(kMilestones.length));
    final all = evaluateMilestones(const MilestoneFacts());
    expect(all.map((s) => s.id), kMilestones.map((m) => m.id));
    expect(all.where((s) => s.earned), isEmpty);
  });

  test('first meal earns with the earliest meal time', () {
    final all = evaluateMilestones(MilestoneFacts(mealTimes: [
      DateTime(2026, 9, 3, 12),
      DateTime(2026, 9, 1, 8),
    ]));
    final m = byId(all, 'first_meal');
    expect(m.earned, isTrue);
    expect(m.earnedAt, DateTime(2026, 9, 1, 8));
  });

  test('meal count milestones use the Nth meal as the earned date', () {
    final times = [
      for (var i = 0; i < 60; i++)
        DateTime(2026, 6, 1).add(Duration(hours: i * 8)),
    ];
    final all = evaluateMilestones(MilestoneFacts(mealTimes: times));
    final fifty = byId(all, 'meals_50');
    expect(fifty.earned, isTrue);
    expect(fifty.earnedAt, times[49]);
    final big = byId(all, 'meals_250');
    expect(big.earned, isFalse);
    expect(big.progress, closeTo(60 / 250, 1e-9));
    expect(big.progressLabel, '60 of 250 meals');
  });

  group('streaks', () {
    test('3 and 7 day streaks earn on the day the run reaches them', () {
      final days = run(DateTime(2026, 9, 1), 8);
      final all = evaluateMilestones(MilestoneFacts(loggedDays: days));
      expect(byId(all, 'streak_3').earnedAt, DateTime(2026, 9, 3));
      expect(byId(all, 'streak_7').earnedAt, DateTime(2026, 9, 7));
      expect(byId(all, 'streak_30').earned, isFalse);
      expect(byId(all, 'streak_30').progress, closeTo(8 / 30, 1e-9));
      expect(byId(all, 'streak_30').progressLabel, 'Best: 8 of 30 days');
    });

    test('a single missed day is bridged by the freeze', () {
      final days = {
        ...run(DateTime(2026, 9, 1), 2),
        // 3 Sep missed
        ...run(DateTime(2026, 9, 4), 1),
      };
      expect(bestStreakRun(days), 3);
      final all = evaluateMilestones(MilestoneFacts(loggedDays: days));
      expect(byId(all, 'streak_3').earned, isTrue);
    });

    test('two missed days break the run', () {
      final days = {
        ...run(DateTime(2026, 9, 1), 2),
        ...run(DateTime(2026, 9, 5), 1)
      };
      expect(bestStreakRun(days), 2);
    });

    test('a broken streak keeps its medal (earned from history)', () {
      final days = {
        ...run(DateTime(2026, 8, 1), 7),
        ...run(DateTime(2026, 9, 1), 1),
      };
      final all = evaluateMilestones(MilestoneFacts(loggedDays: days));
      expect(byId(all, 'streak_7').earned, isTrue);
    });
  });

  test('first weight', () {
    final all = evaluateMilestones(MilestoneFacts(weights: [
      WeightSample(at: DateTime(2026, 9, 2), kg: 80),
    ]));
    expect(byId(all, 'first_weight').earnedAt, DateTime(2026, 9, 2));
  });

  group('goal weight milestones', () {
    test('need a goal', () {
      final all = evaluateMilestones(MilestoneFacts(weights: [
        for (var i = 0; i < 30; i++)
          WeightSample(at: DateTime(2026, 8, 1 + i), kg: 90 - i * .5),
      ]));
      expect(byId(all, 'goal_25').earned, isFalse);
      expect(byId(all, 'goal_25').progressLabel, 'Set a goal weight to start');
    });

    test('earn 25/50% on the smoothed trend, not a single light day', () {
      final weights = [
        for (var i = 0; i < 60; i++)
          WeightSample(
              at: DateTime(2026, 6, 1).add(Duration(days: i)), kg: 90 - i * .1),
      ];
      final all = evaluateMilestones(
          MilestoneFacts(weights: weights, goalWeightKg: 80));
      // Raw reaches 84.1 (59%) but the lagging trend sits a little higher.
      expect(byId(all, 'goal_25').earned, isTrue);
      expect(byId(all, 'goal_50').earned, isTrue);
      expect(byId(all, 'goal_75').earned, isFalse);
      expect(byId(all, 'goal_100').earned, isFalse);
      expect(
          byId(all, 'goal_25')
              .earnedAt!
              .isBefore(byId(all, 'goal_50').earnedAt!),
          isTrue);
      expect(
          byId(all, 'goal_75').progressLabel, matches(RegExp(r'^\d+% there$')));
    });

    test('one outlier weigh-in does not award a milestone', () {
      final all = evaluateMilestones(MilestoneFacts(weights: [
        WeightSample(at: DateTime(2026, 6, 1), kg: 90),
        WeightSample(at: DateTime(2026, 6, 2), kg: 90),
        WeightSample(at: DateTime(2026, 6, 3), kg: 84),
      ], goalWeightKg: 80));
      expect(byId(all, 'goal_25').earned, isFalse);
    });

    test('works for gain goals too', () {
      final weights = [
        for (var i = 0; i < 90; i++)
          WeightSample(
              at: DateTime(2026, 6, 1).add(Duration(days: i)), kg: 60 + i * .1),
      ];
      final all = evaluateMilestones(
          MilestoneFacts(weights: weights, goalWeightKg: 66));
      expect(byId(all, 'goal_100').earned, isTrue);
    });
  });

  test('first template uses the first created date', () {
    final all = evaluateMilestones(MilestoneFacts(
      templateCount: 2,
      firstTemplateAt: DateTime(2026, 9, 9),
    ));
    expect(byId(all, 'first_template').earnedAt, DateTime(2026, 9, 9));
  });

  group('newlyEarned', () {
    final facts = MilestoneFacts(
      mealTimes: [DateTime(2026, 9, 1)],
      loggedDays: run(DateTime(2026, 9, 1), 3),
      weights: [WeightSample(at: DateTime(2026, 8, 20), kg: 80)],
    );

    test('returns earned milestones not yet celebrated, oldest first', () {
      final fresh = newlyEarned(evaluateMilestones(facts), {});
      expect(
          fresh.map((s) => s.id), ['first_weight', 'first_meal', 'streak_3']);
    });

    test('excludes celebrated ones', () {
      final fresh = newlyEarned(
          evaluateMilestones(facts), {'first_meal', 'first_weight'});
      expect(fresh.map((s) => s.id), ['streak_3']);
    });

    test('fires once: marking all leaves nothing new', () {
      final all = evaluateMilestones(facts);
      final celebrated = {for (final s in newlyEarned(all, {})) s.id};
      expect(newlyEarned(all, celebrated), isEmpty);
    });
  });

  group('MilestoneStore', () {
    test('null before first evaluation, then persists marks', () async {
      SharedPreferences.setMockInitialValues({});
      const store = MilestoneStore();
      expect(await store.celebrated('u1'), isNull);
      await store.markCelebrated('u1', ['first_meal']);
      await store.markCelebrated('u1', ['streak_3', 'first_meal']);
      expect(await store.celebrated('u1'), {'first_meal', 'streak_3'});
      expect(await store.celebrated('u2'), isNull);
    });

    test('empty mark initialises the key (silent seed)', () async {
      SharedPreferences.setMockInitialValues({});
      const store = MilestoneStore();
      await store.markCelebrated('u1', const []);
      expect(await store.celebrated('u1'), isEmpty);
    });
  });

  test('copy: ids stay stable while titles and how-tos stay terse', () {
    expect(milestoneById('streak_30')!.title, '30-day streak');
    expect(milestoneById('streak_100')!.howTo, 'Log 100 days in a row.');
    expect(milestoneById('meals_50')!.howTo, 'Log 50 meals.');
    expect(milestoneById('first_template')!.title, 'First saved meal');
    expect(milestoneById('first_template')!.howTo, 'Save a meal.');
  });
}
