import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  StreamSubscription<dynamic>? _subscription;

  @override
  Future<AuthState> build() async {
    ref.onDispose(() => _subscription?.cancel());
    final config = ref.watch(appConfigProvider);
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
    await client.auth.signInWithOtp(email: email);
    state = const AsyncData(AuthState.signedOut());
  }

  Future<void> signOut() async {
    final client = ref.read(supabaseClientProvider);
    await client?.auth.signOut();
    state = const AsyncData(AuthState.signedOut());
  }
}
