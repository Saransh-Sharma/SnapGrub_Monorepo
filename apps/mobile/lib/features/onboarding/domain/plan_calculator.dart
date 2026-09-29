import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

enum BiologicalSex { female, male, unspecified }

enum ActivityLevel {
  sedentary('sedentary', 1.2, 'Mostly sitting', 'Desk job, little exercise'),
  light('low', 1.375, 'Lightly active', 'Exercise 1–3 days a week'),
  moderate('moderate', 1.55, 'Active', 'Exercise 3–5 days a week'),
  high('high', 1.725, 'Very active', 'Hard exercise or a physical job daily');

  const ActivityLevel(
      this.storageKey, this.multiplier, this.title, this.detail);

  /// Value persisted in the profile (`activityLevel`).
  final String storageKey;
  final double multiplier;
  final String title;
  final String detail;

  static ActivityLevel fromStorage(String? key) =>
      ActivityLevel.values.firstWhere((level) => level.storageKey == key,
          orElse: () => ActivityLevel.moderate);
}

enum GoalType {
  lose('lose'),
  maintain('maintain'),
  gain('gain');

  const GoalType(this.storageKey);
  final String storageKey;

  static GoalType fromStorage(String? key) =>
      GoalType.values.firstWhere((goal) => goal.storageKey == key,
          orElse: () => GoalType.maintain);
}

@immutable
class PlanInput {
  const PlanInput({
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    this.targetWeightKg,
    this.ageYears,
    this.sex = BiologicalSex.unspecified,
    this.activity = ActivityLevel.moderate,
    this.paceKgPerWeek = .5,
  });

  final double weightKg;
  final double heightCm;
  final GoalType goal;
  final double? targetWeightKg;
  final int? ageYears;
  final BiologicalSex sex;
  final ActivityLevel activity;

  /// Absolute rate of change, kg per week (ignored for maintain).
  final double paceKgPerWeek;
}

@immutable
class NutritionPlan {
  const NutritionPlan({
    required this.bmr,
    required this.tdee,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.weeklyChangeKg,
    required this.paceClamped,
    this.goalDate,
    this.weeksToGoal,
  });

  final double bmr;
  final double tdee;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Signed expected change per week (negative = losing).
  final double weeklyChangeKg;

  /// True when the requested pace was reduced to stay within safe limits.
  final bool paceClamped;
  final DateTime? goalDate;
  final int? weeksToGoal;
}

/// Evidence-based starting targets. Pure and deterministic; unit tested.
///
/// * BMR: Mifflin–St Jeor (sex-averaged constant when unspecified).
/// * TDEE: BMR × activity multiplier.
/// * Pace: 7,700 kcal per kg; losing is capped at 1% body weight/week and
///   gaining at 0.5%/week; calories never go below a safety floor.
/// * Protein: 1.8 g/kg (lose), 1.6 g/kg (maintain/gain) of goal-relevant
///   weight; fat 28% of calories; carbs fill the rest.
class PlanCalculator {
  const PlanCalculator._();

  static const kcalPerKg = 7700.0;
  static const minPaceKg = .1;

  static double maxLossPace(double weightKg) => weightKg * .01;
  static double maxGainPace(double weightKg) => weightKg * .005;

  static double bmr({
    required double weightKg,
    required double heightCm,
    int? ageYears,
    BiologicalSex sex = BiologicalSex.unspecified,
  }) {
    final age = (ageYears ?? 32).clamp(14, 100);
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (sex) {
      BiologicalSex.male => base + 5,
      BiologicalSex.female => base - 161,
      BiologicalSex.unspecified => base - 78,
    };
  }

  static NutritionPlan calculate(PlanInput input, {DateTime? today}) {
    final bmr = PlanCalculator.bmr(
      weightKg: input.weightKg,
      heightCm: input.heightCm,
      ageYears: input.ageYears,
      sex: input.sex,
    );
    final tdee = bmr * input.activity.multiplier;

    var pace = input.goal == GoalType.maintain
        ? 0.0
        : math.max(minPaceKg, input.paceKgPerWeek.abs());
    var clamped = false;
    if (input.goal == GoalType.lose && pace > maxLossPace(input.weightKg)) {
      pace = maxLossPace(input.weightKg);
      clamped = true;
    }
    if (input.goal == GoalType.gain && pace > maxGainPace(input.weightKg)) {
      pace = maxGainPace(input.weightKg);
      clamped = true;
    }
    final signedPace = switch (input.goal) {
      GoalType.lose => -pace,
      GoalType.gain => pace,
      GoalType.maintain => 0.0,
    };
    final dailyDelta = signedPace * kcalPerKg / 7;

    final floor = switch (input.sex) {
      BiologicalSex.male => 1500.0,
      BiologicalSex.female => 1200.0,
      BiologicalSex.unspecified => 1350.0,
    };
    var calories = tdee + dailyDelta;
    if (calories < math.max(floor, bmr * .9)) {
      calories = math.max(floor, bmr * .9);
      clamped = true;
    }
    calories = (calories / 10).round() * 10;

    final proteinBasis =
        input.goal == GoalType.lose && input.targetWeightKg != null
            ? (input.weightKg + input.targetWeightKg!) / 2
            : input.weightKg;
    final proteinPerKg = input.goal == GoalType.lose ? 1.8 : 1.6;
    final protein =
        (proteinBasis * proteinPerKg).clamp(50, 260).roundToDouble();
    final fat = ((calories * .28) / 9).roundToDouble();
    final carbs = math.max(
        50.0, ((calories - protein * 4 - fat * 9) / 4).roundToDouble());

    final effectivePace = signedPace;
    DateTime? goalDate;
    int? weeks;
    final target = input.targetWeightKg;
    if (target != null && effectivePace != 0) {
      final remaining = target - input.weightKg;
      if (remaining.sign == effectivePace.sign && remaining.abs() > .05) {
        weeks = (remaining / effectivePace).abs().ceil();
        goalDate = (today ?? DateTime.now()).add(Duration(days: weeks * 7));
      }
    }

    return NutritionPlan(
      bmr: bmr,
      tdee: tdee,
      caloriesKcal: calories.toDouble(),
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      weeklyChangeKg: signedPace,
      paceClamped: clamped,
      goalDate: goalDate,
      weeksToGoal: weeks,
    );
  }

  /// Weekly weights from today to the goal date for the projection curve.
  /// Eases in slightly so the curve reads as realistic, not a ruler line.
  static List<double> projection(PlanInput input, NutritionPlan plan) {
    final weeks = plan.weeksToGoal;
    final target = input.targetWeightKg;
    if (weeks == null || target == null || weeks <= 0) {
      return [input.weightKg, input.weightKg];
    }
    return [
      for (var w = 0; w <= weeks; w++)
        input.weightKg +
            (target - input.weightKg) *
                (1 - math.pow(1 - w / weeks, 1.25).toDouble()),
    ];
  }
}

/// Unit helpers.
class Units {
  const Units._();

  static const lbPerKg = 2.2046226218;
  static const cmPerInch = 2.54;

  static double kgToLb(double kg) => kg * lbPerKg;
  static double lbToKg(double lb) => lb / lbPerKg;
  static double cmToIn(double cm) => cm / cmPerInch;
  static double inToCm(double inches) => inches * cmPerInch;

  static String height(double cm, {required bool metric}) {
    if (metric) return '${cm.round()} cm';
    final totalIn = cmToIn(cm).round();
    return '${totalIn ~/ 12}′ ${totalIn % 12}″';
  }

  static String weight(double kg, {required bool metric, int decimals = 1}) =>
      metric
          ? '${kg.toStringAsFixed(decimals)} kg'
          : '${kgToLb(kg).toStringAsFixed(decimals)} lb';
}
