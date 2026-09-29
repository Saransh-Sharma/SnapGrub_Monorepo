import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_region.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_steps.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
  OnboardingController.new,
);

/// Holds the onboarding answers. All body values are stored canonically
/// (kg / cm); the unit system only changes how they are displayed.
class OnboardingController extends Notifier<OnboardingDraft> {
  bool _unitsChosen = false;
  bool _regionDetected = false;

  @override
  OnboardingDraft build() => const OnboardingDraft();

  /// Replaces the fallback locale / timezone with the device's. Runs once;
  /// also picks imperial units for imperial countries unless the user has
  /// already chosen.
  Future<void> detectRegion() async {
    if (_regionDetected) return;
    _regionDetected = true;
    final DetectedRegion region;
    try {
      region = await ref.read(regionDetectorProvider).detect();
    } catch (_) {
      return;
    }
    final zone = region.timezone;
    state = state.copyWith(
      locale: region.locale.isEmpty ? null : region.locale,
      countryCode: region.countryCode,
      timezone: zone == null || zone.isEmpty ? null : zone,
      unitSystem: !_unitsChosen && region.prefersImperial ? 'imperial' : null,
    );
  }

  void updateName(String value) => state = state.copyWith(displayName: value);

  void updateGoal(String value) {
    if (!OnboardingDraft.goalTypes.contains(value)) return;
    if (value == state.goalType) return;
    // A target from another goal would point the wrong way.
    state = state.copyWith(
      goalType: value,
      clearTargetWeight: true,
      targetsAdjusted: false,
    );
  }

  void updateSex(BiologicalSex value) =>
      state = state.copyWith(sex: value, targetsAdjusted: false);

  void updateBirthYear(int year) =>
      state = state.copyWith(birthYear: year, targetsAdjusted: false);

  void updateUnitSystem(String value) {
    if (value != 'metric' && value != 'imperial') return;
    _unitsChosen = true;
    state = state.copyWith(unitSystem: value);
  }

  void updateHeightCm(double cm) =>
      state = state.copyWith(heightCm: cm, targetsAdjusted: false);

  void updateWeightKg(double kg) =>
      state = state.copyWith(weightKg: kg, targetsAdjusted: false);

  void updateTargetWeightKg(double kg) =>
      state = state.copyWith(targetWeightKg: kg, targetsAdjusted: false);

  void updateActivityLevel(String value) =>
      state = state.copyWith(activityLevel: value, targetsAdjusted: false);

  void updatePace(double kgPerWeek) =>
      state = state.copyWith(paceKgPerWeek: kgPerWeek, targetsAdjusted: false);

  void toggleCuisine(String cuisine) {
    final current = [...state.cuisinePreferences];
    current.contains(cuisine) ? current.remove(cuisine) : current.add(cuisine);
    state = state.copyWith(cuisinePreferences: List.unmodifiable(current));
  }

  void toggleMealReminder(String slot) {
    final current = [...state.mealReminders];
    current.contains(slot) ? current.remove(slot) : current.add(slot);
    state = state.copyWith(
      mealReminders: List.unmodifiable(current),
      notificationPreference: current.isNotEmpty,
    );
  }

  void updateNotificationPreference(bool value) {
    state = state.copyWith(
      notificationPreference: value,
      mealReminders: value
          ? (state.mealReminders.isEmpty
              ? const ['lunch', 'dinner']
              : state.mealReminders)
          : const [],
    );
  }

  void markCameraPrimerSeen() {
    state = state.copyWith(cameraPrimerSeen: true);
  }

  /// Commits the values a step was showing by default, so what the user saw
  /// when they tapped Continue is what gets saved.
  void commitStep(OnboardingStep step, {DateTime? now}) {
    final d = state;
    final today = now ?? DateTime.now();
    state = switch (step) {
      OnboardingStep.birthYear when d.birthYear == null =>
        d.copyWith(birthYear: OnboardingDefaults.birthYear(today)),
      OnboardingStep.height when d.heightCm == null =>
        d.copyWith(heightCm: OnboardingDefaults.heightCm),
      OnboardingStep.weight when d.weightKg == null =>
        d.copyWith(weightKg: OnboardingDefaults.weightKg),
      OnboardingStep.targetWeight when d.targetWeightKg == null =>
        d.copyWith(targetWeightKg: OnboardingDefaults.target(d)),
      OnboardingStep.reminders => d.copyWith(cameraPrimerSeen: true),
      _ => d,
    };
  }

  /// Copies the calculated plan into the targets (unless hand-adjusted).
  void applyPlan({DateTime? today}) {
    state = _withDefaults(state, today ?? DateTime.now())
        .withPlanTargets(today: today);
  }

  /// Hand-edited targets from the plan reveal.
  void adjustTargets({
    required double caloriesKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) {
    state = state.copyWith(
      caloriesKcal: caloriesKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      targetsAdjusted: true,
    );
  }

  /// The draft to save: defaults committed, plan applied, primer marked.
  OnboardingDraft finalDraft({DateTime? today}) {
    final now = today ?? DateTime.now();
    final draft =
        _withDefaults(state, now).withPlanTargets(today: now).copyWith(
              cameraPrimerSeen: true,
              displayName: state.displayName.trim(),
            );
    state = draft;
    return draft;
  }

  static OnboardingDraft _withDefaults(OnboardingDraft d, DateTime now) {
    var next = d.copyWith(
      heightCm: d.heightCm ?? OnboardingDefaults.heightCm,
      weightKg: d.weightKg ?? OnboardingDefaults.weightKg,
      birthYear: d.birthYear ?? OnboardingDefaults.birthYear(now),
    );
    if (next.needsTargetWeight && next.targetWeightKg == null) {
      next = next.copyWith(targetWeightKg: OnboardingDefaults.target(next));
    }
    return next;
  }
}
