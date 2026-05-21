import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_repository.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/templates/data/template_repository.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:snapgrub/offline/sync/sync_command_repository.dart';

final syncControllerProvider = AsyncNotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

enum SyncStatus { idle, pending, syncing, synced, failed, conflict }

class SyncController extends AsyncNotifier<SyncStatus> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _syncInFlight = false;

  @override
  Future<SyncStatus> build() async {
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
    });
    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen((results) {
      if (_hasNetwork(results)) {
        unawaited(syncNow(trigger: SyncTrigger.networkRestored));
      }
    });
    return _statusForCurrentUser();
  }

  Future<void> syncNow({SyncTrigger trigger = SyncTrigger.manual}) async {
    if (_syncInFlight) return;
    final auth = await ref.read(authControllerProvider.future);
    final userId = auth.userId;
    if (auth.status != AuthStatus.signedIn || userId == null) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (!_hasNetwork(connectivity)) {
      state = const AsyncData(SyncStatus.pending);
      return;
    }

    _syncInFlight = true;
    state = const AsyncData(SyncStatus.syncing);
    try {
      await ref.read(syncCommandRepositoryProvider).drainPhase6Commands(userId);
      await ref.read(customFoodRepositoryProvider).drainOutbox(userId);
      await ref.read(templateRepositoryProvider).drainOutbox(userId);
      await ref.read(mealRepositoryProvider).drainMealOutbox(userId);
      await ref.read(syncCommandRepositoryProvider).drainPhase6Commands(userId);
      state = AsyncData(await _statusForCurrentUser());
    } catch (error) {
      state = const AsyncData(SyncStatus.failed);
    } finally {
      _syncInFlight = false;
    }
  }

  Future<SyncStatus> _statusForCurrentUser() async {
    final auth = await ref.read(authControllerProvider.future);
    final userId = auth.userId;
    if (auth.status != AuthStatus.signedIn || userId == null) return SyncStatus.idle;
    final pending = await ref.read(outboxRepositoryProvider).pendingCount(userId);
    if (pending == 0) return SyncStatus.synced;
    final hasConflict = await ref.read(outboxRepositoryProvider).hasConflict(userId);
    return hasConflict ? SyncStatus.conflict : SyncStatus.pending;
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

enum SyncTrigger { manual, foreground, networkRestored, login, pullToRefresh, background }
