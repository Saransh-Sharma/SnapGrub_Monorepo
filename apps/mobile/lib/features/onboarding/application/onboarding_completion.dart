import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';

/// Small, local-only facts onboarding hands to the rest of the app.
///
/// The profile schema has no goal-weight column, so the goal weight is kept
/// on the device under the key Progress reads (`goal_weight_store.dart`).
class OnboardingHandoff {
  const OnboardingHandoff._();

  static String goalWeightKey(String userId) =>
      'snapgrub.goal_weight_kg.$userId';

  /// Set when onboarding finishes; Today shows its first-run coach mark on the
  /// capture button while this is true, then clears it.
  static const firstRunCoachKey = 'snapgrub.first_run.coach_pending';

  static Future<void> save(String userId, OnboardingDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final target = draft.targetWeightKg;
      if (draft.needsTargetWeight && target != null) {
        await prefs.setDouble(goalWeightKey(userId), target);
      } else {
        await prefs.remove(goalWeightKey(userId));
      }
      await prefs.setBool(firstRunCoachKey, true);
    } catch (_) {
      // Preferences are a nicety here; never block finishing onboarding.
    }
  }
}
