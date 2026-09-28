import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';

/// Goal (target) weight, in kilograms.
///
/// The Drift schema and the profile contract have no goal-weight column yet,
/// so it lives in shared_preferences under `snapgrub.goal_weight_kg.<userId>`.
/// Onboarding and the You tab write it; Progress and milestones read it.
class GoalWeightStore {
  const GoalWeightStore._();

  static String key(String userId) => 'snapgrub.goal_weight_kg.$userId';

  static Future<double?> load(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getDouble(key(userId));
      return value == null || value <= 0 ? null : value;
    } catch (_) {
      return null;
    }
  }

  /// Pass null to clear.
  static Future<void> save(String userId, double? kg) async {
    final prefs = await SharedPreferences.getInstance();
    if (kg == null) {
      await prefs.remove(key(userId));
    } else {
      await prefs.setDouble(key(userId), kg);
    }
  }
}

/// Goal weight for the signed-in user (kg), or null. Invalidate after saving.
final goalWeightProvider = FutureProvider<double?>((ref) async {
  final user = await ref.watch(homeUserContextProvider.future);
  if (user == null) return null;
  return GoalWeightStore.load(user.userId);
});
