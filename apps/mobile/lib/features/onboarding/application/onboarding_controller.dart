import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
  OnboardingController.new,
);

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void updateName(String value) => state = state.copyWith(displayName: value);

  void updateGoal(String value) => state = state.copyWith(goalType: value);

  void updateUnitSystem(String value) =>
      state = state.copyWith(unitSystem: value);

  void updateWeight(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return;
    state = state.copyWith(
        weightKg:
            state.unitSystem == 'imperial' ? parsed * 0.45359237 : parsed);
  }

  void updateTargetWeight(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return;
    state = state.copyWith(
        targetWeightKg:
            state.unitSystem == 'imperial' ? parsed * 0.45359237 : parsed);
  }

  void updateHeight(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return;
    state = state.copyWith(
        heightCm: state.unitSystem == 'imperial' ? parsed * 2.54 : parsed);
  }

  void updateActivityLevel(String value) {
    state = state.copyWith(activityLevel: value);
  }

  void updateTimezone(String value) {
    if (value.trim().isEmpty) return;
    state = state.copyWith(timezone: value.trim());
  }

  void updateCalories(String value) {
    state = state.copyWith(
        caloriesKcal: double.tryParse(value) ?? state.caloriesKcal);
  }

  void updateProtein(String value) {
    state = state.copyWith(proteinG: double.tryParse(value) ?? state.proteinG);
  }

  void updateCarbs(String value) {
    state = state.copyWith(carbsG: double.tryParse(value) ?? state.carbsG);
  }

  void updateFat(String value) {
    state = state.copyWith(fatG: double.tryParse(value) ?? state.fatG);
  }

  void updateCuisines(String value) {
    final cuisines = value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    state = state.copyWith(cuisinePreferences: cuisines);
  }

  void markCameraPrimerSeen() {
    state = state.copyWith(cameraPrimerSeen: true);
  }

  void updateNotificationPreference(bool value) {
    state = state.copyWith(notificationPreference: value);
  }
}
