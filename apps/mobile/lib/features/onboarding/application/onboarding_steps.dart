import 'dart:math' as math;

import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart';

/// One screen of the onboarding flow.
enum OnboardingStep {
  welcome('welcome'),
  name('name'),
  goal('goal'),
  sex('sex'),
  birthYear('birth_year'),
  height('height'),
  weight('weight'),
  targetWeight('target_weight'),
  activity('activity'),
  pace('pace'),
  cuisines('cuisines'),
  reminders('reminders'),
  building('building'),
  reveal('reveal');

  const OnboardingStep(this.id);

  /// Stable id used for E2E selectors: `onboarding.step.<id>`.
  final String id;

  /// Question steps show the segmented progress bar.
  bool get isQuestion => this != welcome && this != building && this != reveal;
}

/// The steps for [draft], in order. Target weight and pace only apply to
/// lose / gain goals.
List<OnboardingStep> onboardingStepsFor(OnboardingDraft draft) => [
      for (final step in OnboardingStep.values)
        if (draft.needsTargetWeight ||
            (step != OnboardingStep.targetWeight &&
                step != OnboardingStep.pace))
          step,
    ];

/// Starting values shown by pickers before the user moves them.
class OnboardingDefaults {
  const OnboardingDefaults._();

  static const heightCm = 170.0;
  static const weightKg = 70.0;
  static const defaultAge = 30;
  static const minAge = 13;
  static const maxAge = 100;

  static const minWeightKg = 30.0;
  static const maxWeightKg = 250.0;
  static const minHeightCm = 120.0;
  static const maxHeightCm = 230.0;

  static const minPace = .25;
  static const maxPace = 1.0;
  static const paceStep = .25;

  /// Lowest target weight we'll suggest for a height (BMI 18.5).
  static double healthyMinKg(double heightCm) =>
      18.5 * math.pow(heightCm / 100, 2);

  static int birthYear(DateTime now) => now.year - defaultAge;

  static double height(OnboardingDraft d) => d.heightCm ?? heightCm;

  static double weight(OnboardingDraft d) => d.weightKg ?? weightKg;

  static int birthYearOf(OnboardingDraft d, DateTime now) =>
      d.birthYear ?? birthYear(now);

  /// The target shown before the user picks one: a modest change in the
  /// goal's direction, never below a healthy weight for their height.
  static double target(OnboardingDraft d) {
    final existing = d.targetWeightKg;
    if (existing != null) return existing;
    final current = weight(d);
    final raw = d.goalType == 'gain' ? current + 3 : current - 5;
    final floor = healthyMinKg(height(d));
    final value = d.goalType == 'gain'
        ? raw
        : math.max(raw, math.min(floor, current - .5));
    return (value * 10).roundToDouble() / 10;
  }
}

/// Human validation message for [step], or null when the step is complete.
String? validateOnboardingStep(
  OnboardingStep step,
  OnboardingDraft draft, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  switch (step) {
    case OnboardingStep.name:
      final name = draft.displayName.trim();
      if (name.isEmpty) return 'Add a name or nickname.';
      if (name.length > 40) return 'Keep it under 40 characters.';
      return null;
    case OnboardingStep.goal:
      return OnboardingDraft.goalTypes.contains(draft.goalType)
          ? null
          : 'Choose a goal.';
    case OnboardingStep.sex:
      return draft.sex == null ? 'Choose one, or “Prefer not to say.”' : null;
    case OnboardingStep.birthYear:
      final age = today.year - OnboardingDefaults.birthYearOf(draft, today);
      if (age < OnboardingDefaults.minAge || age > OnboardingDefaults.maxAge) {
        return 'Choose a year between '
            '${today.year - OnboardingDefaults.maxAge} and '
            '${today.year - OnboardingDefaults.minAge}.';
      }
      return null;
    case OnboardingStep.height:
      final h = OnboardingDefaults.height(draft);
      return h < 80 || h > 260 ? 'Choose your height.' : null;
    case OnboardingStep.weight:
      final w = OnboardingDefaults.weight(draft);
      return w < 20 || w > 400 ? 'Choose your weight.' : null;
    case OnboardingStep.targetWeight:
      if (!draft.needsTargetWeight) return null;
      final current = OnboardingDefaults.weight(draft);
      final target = OnboardingDefaults.target(draft);
      final metric = draft.isMetric;
      if (draft.goalType == 'lose') {
        if (target >= current - .05) {
          return 'Choose a goal below '
              '${Units.weight(current, metric: metric)} to lose weight.';
        }
        final floor =
            OnboardingDefaults.healthyMinKg(OnboardingDefaults.height(draft));
        if (target < floor - .05) {
          return 'That’s below a healthy weight for your height. Try '
              '${Units.weight(floor, metric: metric)} or more.';
        }
      } else if (target <= current + .05) {
        return 'Choose a goal above '
            '${Units.weight(current, metric: metric)} to gain weight.';
      }
      return null;
    case OnboardingStep.activity:
      final valid = ActivityLevel.values
          .any((level) => level.storageKey == draft.activityLevel);
      return valid ? null : 'Choose an activity level.';
    case OnboardingStep.pace:
      final pace = draft.paceKgPerWeek;
      return pace < PlanCalculator.minPaceKg || pace > 2
          ? 'Choose a pace.'
          : null;
    case OnboardingStep.welcome:
    case OnboardingStep.cuisines:
    case OnboardingStep.reminders:
    case OnboardingStep.building:
    case OnboardingStep.reveal:
      return null;
  }
}
