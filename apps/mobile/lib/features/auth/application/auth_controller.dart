import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/app/e2e/e2e_data.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  static const _e2eUserIdKey = 'snapgrub.e2e.user_id';

  StreamSubscription<dynamic>? _subscription;

  @override
  Future<AuthState> build() async {
    ref.onDispose(() => _subscription?.cancel());
    final config = ref.watch(appConfigProvider);
    if (config.isE2eMock) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_e2eUserIdKey);
      return userId == null
          ? const AuthState.signedOut()
          : AuthState.signedIn(userId);
    }

    if (!config.hasSupabaseConfig) {
      return const AuthState.configurationMissing();
    }

    final client = ref.watch(supabaseClientProvider);
    final user = client?.auth.currentUser;
    _subscription ??= client?.auth.onAuthStateChange.listen((event) {
      final sessionUser = event.session?.user;
      state = AsyncData(
        sessionUser == null
            ? const AuthState.signedOut()
            : AuthState.signedIn(sessionUser.id),
      );
    });

    return user == null
        ? const AuthState.signedOut()
        : AuthState.signedIn(user.id);
  }

  Future<void> requestMagicLink(String email) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = const AsyncData(AuthState.configurationMissing());
      return;
    }
    state = const AsyncLoading();
    try {
      await client.auth.signInWithOtp(email: email);
      state = const AsyncData(AuthState.signedOut());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final config = ref.read(appConfigProvider);
    if (!config.usesE2ePasswordAuth) {
      throw StateError('Password sign-in is only available for E2E builds.');
    }

    state = const AsyncLoading();
    try {
      if (config.isE2eMock) {
        final userId = E2eData.userIdForEmail(email);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_e2eUserIdKey, userId);
        state = AsyncData(AuthState.signedIn(userId));
        return;
      }

      final client = ref.read(supabaseClientProvider);
      if (client == null) {
        state = const AsyncData(AuthState.configurationMissing());
        return;
      }
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final userId = response.user?.id;
      state = AsyncData(
        userId == null
            ? const AuthState.signedOut()
            : AuthState.signedIn(userId),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final config = ref.read(appConfigProvider);
    if (config.isE2eMock) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_e2eUserIdKey);
      state = const AsyncData(AuthState.signedOut());
      return;
    }
    final client = ref.read(supabaseClientProvider);
    await client?.auth.signOut();
    state = const AsyncData(AuthState.signedOut());
  }
}
