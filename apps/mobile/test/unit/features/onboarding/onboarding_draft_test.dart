import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_region.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_steps.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart';

import 'onboarding_test_utils.dart';

void main() {
  group('OnboardingDraft', () {
    test('default onboarding draft is valid', () {
      const draft = OnboardingDraft();
      expect(() => draft.validate(), returnsNormally);
    });

    test('invalid calories are rejected', () {
      const draft = OnboardingDraft(caloriesKcal: 200);
      expect(draft.validate, throwsArgumentError);
    });

    test('weight creates onboarding body measurement', () {
      const draft = OnboardingDraft(weightKg: 82);
      expect(draft.bodyMeasurement?.weightKg, 82);
      expect(draft.bodyMeasurement?.source, 'onboarding');
    });

    test('invalid target weight is rejected', () {
      const draft = OnboardingDraft(targetWeightKg: 10);
      expect(draft.validate, throwsArgumentError);
    });

    test('custom goal plans from maintenance and ignores a target', () {
      const draft = OnboardingDraft(
        goalType: 'custom',
        weightKg: 70,
        heightCm: 170,
        targetWeightKg: 60,
      );
      expect(draft.planGoal, GoalType.maintain);
      expect(draft.needsTargetWeight, isFalse);
      expect(draft.planInput()!.targetWeightKg, isNull);
    });

    test('withPlanTargets copies the calculator output unless adjusted', () {
      final today = DateTime(2026, 9, 1);
      const base = OnboardingDraft(
        goalType: 'lose',
        weightKg: 80,
        heightCm: 178,
        targetWeightKg: 74,
        birthYear: 1990,
        sex: BiologicalSex.male,
      );
      final plan = base.plan(today: today)!;
      final applied = base.withPlanTargets(today: today);
      expect(applied.caloriesKcal, plan.caloriesKcal);
      expect(applied.proteinG, plan.proteinG);
      expect(applied.carbsG, plan.carbsG);
      expect(applied.fatG, plan.fatG);

      final adjusted = base.copyWith(caloriesKcal: 2222, targetsAdjusted: true);
      expect(adjusted.withPlanTargets(today: today).caloriesKcal, 2222);
    });

    test('copyWith can clear the target weight', () {
      const draft = OnboardingDraft(targetWeightKg: 60);
      expect(draft.copyWith(clearTargetWeight: true).targetWeightKg, isNull);
      expect(draft.copyWith().targetWeightKg, 60);
    });
  });

  group('OnboardingController', () {
    ProviderContainer make(
        {RegionDetector detector = const FakeRegionDetector()}) {
      final container = ProviderContainer(overrides: [
        regionDetectorProvider.overrideWithValue(detector),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('detectRegion replaces the fallback locale and timezone', () async {
      final container = make();
      await container
          .read(onboardingControllerProvider.notifier)
          .detectRegion();
      final draft = container.read(onboardingControllerProvider);
      expect(draft.locale, 'en-GB');
      expect(draft.countryCode, 'GB');
      expect(draft.timezone, 'Europe/London');
      expect(draft.unitSystem, 'metric');
    });

    test('imperial countries default to imperial unless already chosen',
        () async {
      const us = FakeRegionDetector(
        region: DetectedRegion(
            locale: 'en-US', countryCode: 'US', timezone: 'America/Chicago'),
      );
      final auto = make(detector: us);
      await auto.read(onboardingControllerProvider.notifier).detectRegion();
      expect(auto.read(onboardingControllerProvider).unitSystem, 'imperial');

      final chosen = make(detector: us);
      final notifier = chosen.read(onboardingControllerProvider.notifier);
      notifier.updateUnitSystem('metric');
      await notifier.detectRegion();
      expect(chosen.read(onboardingControllerProvider).unitSystem, 'metric');
    });

    test('a missing timezone keeps the fallback', () async {
      final container = make(
        detector: const FakeRegionDetector(
          region: DetectedRegion(locale: '', countryCode: null),
        ),
      );
      await container
          .read(onboardingControllerProvider.notifier)
          .detectRegion();
      final draft = container.read(onboardingControllerProvider);
      expect(draft.timezone, 'Asia/Kolkata');
      expect(draft.locale, 'en-IN');
    });

    test('switching units keeps canonical values', () {
      final container = make();
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier
        ..updateHeightCm(Units.inToCm(70))
        ..updateWeightKg(Units.lbToKg(180))
        ..updateUnitSystem('imperial')
        ..updateUnitSystem('metric');
      final draft = container.read(onboardingControllerProvider);
      expect(draft.heightCm, closeTo(177.8, .01));
      expect(draft.weightKg, closeTo(81.65, .01));
    });

    test('changing goal clears a target that would point the wrong way', () {
      final container = make();
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier
        ..updateGoal('lose')
        ..updateTargetWeightKg(60)
        ..updateGoal('gain');
      expect(
          container.read(onboardingControllerProvider).targetWeightKg, isNull);
    });

    test('plan inputs reset hand-adjusted targets', () {
      final container = make();
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.adjustTargets(
          caloriesKcal: 2000, proteinG: 150, carbsG: 200, fatG: 60);
      expect(
          container.read(onboardingControllerProvider).targetsAdjusted, isTrue);
      notifier.updateWeightKg(75);
      expect(container.read(onboardingControllerProvider).targetsAdjusted,
          isFalse);
    });

    test('commitStep saves the defaults a picker was showing', () {
      final container = make();
      final notifier = container.read(onboardingControllerProvider.notifier);
      final now = DateTime(2026, 9, 25);
      notifier
        ..commitStep(OnboardingStep.birthYear, now: now)
        ..commitStep(OnboardingStep.height)
        ..commitStep(OnboardingStep.weight)
        ..commitStep(OnboardingStep.targetWeight);
      final draft = container.read(onboardingControllerProvider);
      expect(draft.birthYear, 1996);
      expect(draft.heightCm, OnboardingDefaults.heightCm);
      expect(draft.weightKg, OnboardingDefaults.weightKg);
      expect(draft.targetWeightKg, 65);
    });

    test('finalDraft applies the plan and marks the camera primer seen', () {
      final container = make();
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier
        ..updateName('  Asha  ')
        ..updateGoal('maintain');
      final draft = notifier.finalDraft(today: DateTime(2026, 9, 25));
      expect(draft.displayName, 'Asha');
      expect(draft.cameraPrimerSeen, isTrue);
      expect(draft.caloriesKcal, draft.plan()!.caloriesKcal);
      expect(() => draft.validate(), returnsNormally);
    });

    test('reminder chips drive the notification preference', () {
      final container = make();
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.toggleMealReminder('dinner');
      expect(
          container.read(onboardingControllerProvider).notificationPreference,
          isTrue);
      notifier.toggleMealReminder('dinner');
      expect(
          container.read(onboardingControllerProvider).notificationPreference,
          isFalse);
      notifier.updateNotificationPreference(true);
      expect(container.read(onboardingControllerProvider).mealReminders,
          ['lunch', 'dinner']);
    });
  });

  group('steps', () {
    test('maintain and custom skip target weight and pace', () {
      for (final goal in ['maintain', 'custom']) {
        final steps = onboardingStepsFor(OnboardingDraft(goalType: goal));
        expect(steps, isNot(contains(OnboardingStep.targetWeight)));
        expect(steps, isNot(contains(OnboardingStep.pace)));
        expect(steps.length, 12);
      }
      expect(onboardingStepsFor(const OnboardingDraft(goalType: 'gain')).length,
          14);
    });

    test('validation messages per step', () {
      const empty = OnboardingDraft();
      expect(validateOnboardingStep(OnboardingStep.name, empty), isNotNull);
      expect(
          validateOnboardingStep(
              OnboardingStep.name, empty.copyWith(displayName: 'A')),
          isNull);
      expect(validateOnboardingStep(OnboardingStep.sex, empty), isNotNull);
      expect(
          validateOnboardingStep(OnboardingStep.sex,
              empty.copyWith(sex: BiologicalSex.unspecified)),
          isNull);
      // Defaults are valid for picker steps.
      for (final step in [
        OnboardingStep.birthYear,
        OnboardingStep.height,
        OnboardingStep.weight,
        OnboardingStep.targetWeight,
        OnboardingStep.activity,
        OnboardingStep.pace,
        OnboardingStep.cuisines,
        OnboardingStep.reminders,
      ]) {
        expect(validateOnboardingStep(step, empty), isNull, reason: '$step');
      }
    });

    test('target weight must point in the goal direction and stay healthy', () {
      const lose =
          OnboardingDraft(goalType: 'lose', weightKg: 70, heightCm: 170);
      expect(
          validateOnboardingStep(
              OnboardingStep.targetWeight, lose.copyWith(targetWeightKg: 72)),
          contains('below'));
      expect(
          validateOnboardingStep(
              OnboardingStep.targetWeight, lose.copyWith(targetWeightKg: 45)),
          contains('healthy'));
      const gain =
          OnboardingDraft(goalType: 'gain', weightKg: 70, heightCm: 170);
      expect(
          validateOnboardingStep(
              OnboardingStep.targetWeight, gain.copyWith(targetWeightKg: 68)),
          contains('above'));
      expect(
          validateOnboardingStep(
              OnboardingStep.targetWeight, gain.copyWith(targetWeightKg: 74)),
          isNull);
    });

    test('default lose target never drops below a healthy weight', () {
      const draft =
          OnboardingDraft(goalType: 'lose', weightKg: 55, heightCm: 170);
      final target = OnboardingDefaults.target(draft);
      expect(target, lessThan(55));
      expect(target,
          greaterThanOrEqualTo(OnboardingDefaults.healthyMinKg(170) - .05));
    });
  });
}
