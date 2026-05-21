import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/repositories/profile_repository.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/profile/domain/profile_state.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileState>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    final auth = await ref.watch(authControllerProvider.future);
    if (auth.status != AuthStatus.signedIn) return const ProfileState.empty();

    final repo = ref.watch(profileRepositoryProvider);
    try {
      return await repo.bootstrap(auth.userId!);
    } catch (_) {
      return repo.loadLocal(auth.userId!);
    }
  }

  Future<void> completeOnboarding(String userId, OnboardingDraft draft) async {
    state = const AsyncLoading();
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveOnboarding(userId, draft);
    state = AsyncData(await repo.loadLocal(userId));
  }

  Future<void> refresh() async {
    final auth = await ref.read(authControllerProvider.future);
    final userId = auth.userId;
    if (userId == null) {
      state = const AsyncData(ProfileState.empty());
      return;
    }
    state = const AsyncLoading();
    state =
        AsyncData(await ref.read(profileRepositoryProvider).bootstrap(userId));
  }
}
