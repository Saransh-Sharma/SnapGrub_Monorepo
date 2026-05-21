import 'package:snapgrub/features/profile/domain/nutrition_goal.dart';
import 'package:snapgrub/features/profile/domain/profile.dart';

class ProfileState {
  const ProfileState({
    required this.profile,
    required this.activeGoal,
    required this.featureFlags,
    required this.syncStatus,
  });

  const ProfileState.empty()
      : this(
          profile: null,
          activeGoal: null,
          featureFlags: const {},
          syncStatus: ProfileSyncStatus.idle,
        );

  final UserProfile? profile;
  final NutritionGoal? activeGoal;
  final Map<String, Object?> featureFlags;
  final ProfileSyncStatus syncStatus;

  bool get needsOnboarding =>
      profile == null || !profile!.hasCompletedOnboarding || activeGoal == null;

  ProfileState copyWith({
    UserProfile? profile,
    NutritionGoal? activeGoal,
    Map<String, Object?>? featureFlags,
    ProfileSyncStatus? syncStatus,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      activeGoal: activeGoal ?? this.activeGoal,
      featureFlags: featureFlags ?? this.featureFlags,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

enum ProfileSyncStatus {
  idle,
  syncing,
  synced,
  pending,
  failed,
}
