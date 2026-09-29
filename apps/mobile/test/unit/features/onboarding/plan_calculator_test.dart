import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart';

void main() {
  test('Mifflin–St Jeor BMR by sex', () {
    expect(
      PlanCalculator.bmr(
          weightKg: 70, heightCm: 175, ageYears: 30, sex: BiologicalSex.male),
      closeTo(1648.75, .01),
    );
    expect(
      PlanCalculator.bmr(
          weightKg: 60, heightCm: 165, ageYears: 30, sex: BiologicalSex.female),
      closeTo(1320.25, .01),
    );
  });

  test('losing weight creates a deficit and a goal date', () {
    final today = DateTime(2026, 1, 1);
    final plan = PlanCalculator.calculate(
      const PlanInput(
        weightKg: 80,
        heightCm: 178,
        ageYears: 35,
        sex: BiologicalSex.male,
        goal: GoalType.lose,
        targetWeightKg: 74,
        paceKgPerWeek: .5,
      ),
      today: today,
    );
    expect(plan.caloriesKcal, lessThan(plan.tdee));
    expect(plan.weeklyChangeKg, -.5);
    expect(plan.weeksToGoal, 12);
    expect(plan.goalDate, today.add(const Duration(days: 84)));
    expect(plan.paceClamped, isFalse);
    // Macros add up close to the calorie target.
    final fromMacros = plan.proteinG * 4 + plan.carbsG * 4 + plan.fatG * 9;
    expect((fromMacros - plan.caloriesKcal).abs(), lessThan(40));
  });

  test('aggressive pace is clamped to 1% body weight per week', () {
    final plan = PlanCalculator.calculate(const PlanInput(
      weightKg: 60,
      heightCm: 160,
      goal: GoalType.lose,
      targetWeightKg: 50,
      paceKgPerWeek: 1.5,
    ));
    expect(plan.weeklyChangeKg, closeTo(-.6, 1e-9));
    expect(plan.paceClamped, isTrue);
  });

  test('calories never drop below the safety floor', () {
    final plan = PlanCalculator.calculate(const PlanInput(
      weightKg: 45,
      heightCm: 150,
      ageYears: 60,
      sex: BiologicalSex.female,
      activity: ActivityLevel.sedentary,
      goal: GoalType.lose,
      targetWeightKg: 42,
      paceKgPerWeek: .45,
    ));
    expect(plan.caloriesKcal, greaterThanOrEqualTo(1200));
  });

  test('maintain has no pace and no goal date', () {
    final plan = PlanCalculator.calculate(const PlanInput(
      weightKg: 70,
      heightCm: 170,
      goal: GoalType.maintain,
    ));
    expect(plan.weeklyChangeKg, 0);
    expect(plan.goalDate, isNull);
    expect(plan.caloriesKcal, closeTo(plan.tdee, 10));
  });

  test('projection starts at current weight and ends at target', () {
    const input = PlanInput(
      weightKg: 90,
      heightCm: 180,
      goal: GoalType.lose,
      targetWeightKg: 84,
      paceKgPerWeek: .5,
    );
    final plan = PlanCalculator.calculate(input);
    final curve = PlanCalculator.projection(input, plan);
    expect(curve.first, 90);
    expect(curve.last, closeTo(84, 1e-9));
  });

  test('unit conversions round-trip', () {
    expect(Units.lbToKg(Units.kgToLb(72.5)), closeTo(72.5, 1e-9));
    expect(Units.height(180, metric: false), '5′ 11″');
  });
}
