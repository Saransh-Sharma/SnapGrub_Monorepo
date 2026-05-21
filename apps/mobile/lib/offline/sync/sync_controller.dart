import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_repository.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/templates/data/template_repository.dart';

final syncControllerProvider = AsyncNotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

enum SyncStatus { idle, syncing, synced, failed }

class SyncController extends AsyncNotifier<SyncStatus> {
  @override
  Future<SyncStatus> build() async => SyncStatus.idle;

  Future<void> syncNow() async {
    final auth = await ref.read(authControllerProvider.future);
    final userId = auth.userId;
    if (auth.status != AuthStatus.signedIn || userId == null) return;

    state = const AsyncData(SyncStatus.syncing);
    try {
      await ref.read(customFoodRepositoryProvider).drainOutbox(userId);
      await ref.read(templateRepositoryProvider).drainOutbox(userId);
      await ref.read(mealRepositoryProvider).drainMealOutbox(userId);
      state = const AsyncData(SyncStatus.synced);
    } catch (_) {
      state = const AsyncData(SyncStatus.failed);
    }
  }
}
