import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/app/e2e/e2e_data.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  static const _e2eUserIdKey = 'snapgrub.e2e.user_id';
  static const _passwordRecoveryUserIdKey =
      'snapgrub.auth.password_recovery_user_id';

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
      if (event.event == AuthChangeEvent.passwordRecovery &&
          sessionUser != null) {
        unawaited(_storePasswordRecoveryUserId(sessionUser.id));
      } else if (event.event == AuthChangeEvent.signedOut ||
          event.event == AuthChangeEvent.signedIn) {
        unawaited(_clearPasswordRecoveryUserId());
      }
      state = AsyncData(
        sessionUser == null
            ? const AuthState.signedOut()
            : event.event == AuthChangeEvent.passwordRecovery
                ? AuthState.passwordRecovery(sessionUser.id)
                : AuthState.signedIn(sessionUser.id),
      );
    });

    if (user == null) return const AuthState.signedOut();
    return await isStoredPasswordRecoveryUser(user.id)
        ? AuthState.passwordRecovery(user.id)
        : AuthState.signedIn(user.id);
  }

  Future<void> requestSignInOtp(String email) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = const AsyncData(AuthState.configurationMissing());
      return;
    }
    state = const AsyncLoading();
    try {
      await client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      state = const AsyncData(AuthState.signedOut());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> verifySignInOtp({
    required String email,
    required String token,
  }) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = const AsyncData(AuthState.configurationMissing());
      return;
    }
    state = const AsyncLoading();
    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      final userId = response.user?.id;
      if (userId != null) await _clearPasswordRecoveryUserId();
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

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = const AsyncData(AuthState.configurationMissing());
      return;
    }
    state = const AsyncLoading();
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      final userId = response.user?.id;
      if (response.session != null && userId != null) {
        await _clearPasswordRecoveryUserId();
      }
      state = AsyncData(
        response.session == null || userId == null
            ? const AuthState.signedOut()
            : AuthState.signedIn(userId),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> verifySignUpOtp({
    required String email,
    required String token,
  }) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = const AsyncData(AuthState.configurationMissing());
      return;
    }
    state = const AsyncLoading();
    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      final userId = response.user?.id;
      if (userId != null) await _clearPasswordRecoveryUserId();
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

  Future<void> resendSignUpOtp(String email) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = const AsyncData(AuthState.configurationMissing());
      return;
    }
    state = const AsyncLoading();
    try {
      await client.auth.resend(email: email, type: OtpType.signup);
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
      if (userId != null) await _clearPasswordRecoveryUserId();
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

  Future<void> requestPasswordRecovery(String email) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = const AsyncData(AuthState.configurationMissing());
      return;
    }
    state = const AsyncLoading();
    try {
      await client.auth.resetPasswordForEmail(email);
      state = const AsyncData(AuthState.signedOut());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = const AsyncData(AuthState.configurationMissing());
      return;
    }
    state = const AsyncLoading();
    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      final userId = response.user?.id;
      if (userId != null) await _storePasswordRecoveryUserId(userId);
      state = AsyncData(
        userId == null
            ? const AuthState.signedOut()
            : AuthState.passwordRecovery(userId),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> setRecoveredPassword(String password) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = const AsyncData(AuthState.configurationMissing());
      return;
    }
    state = const AsyncLoading();
    try {
      final response = await client.auth.updateUser(
        UserAttributes(password: password),
      );
      final userId = response.user?.id ?? client.auth.currentUser?.id;
      if (userId != null) await _clearPasswordRecoveryUserId();
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
      await _clearPasswordRecoveryUserId();
      state = const AsyncData(AuthState.signedOut());
      return;
    }
    final client = ref.read(supabaseClientProvider);
    await client?.auth.signOut();
    await _clearPasswordRecoveryUserId();
    state = const AsyncData(AuthState.signedOut());
  }

  Future<void> cancelPasswordRecovery() => signOut();

  @visibleForTesting
  static Future<bool> isStoredPasswordRecoveryUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordRecoveryUserIdKey) == userId;
  }

  @visibleForTesting
  static Future<void> storePasswordRecoveryUserForTesting(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordRecoveryUserIdKey, userId);
  }

  @visibleForTesting
  static Future<void> clearPasswordRecoveryUserForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordRecoveryUserIdKey);
  }

  Future<void> _storePasswordRecoveryUserId(String userId) async {
    await storePasswordRecoveryUserForTesting(userId);
  }

  Future<void> _clearPasswordRecoveryUserId() async {
    await clearPasswordRecoveryUserForTesting();
  }
}
