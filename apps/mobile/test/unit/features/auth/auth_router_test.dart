import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/app/e2e/e2e_data.dart';
import 'package:snapgrub/app/env/app_config.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/data/db/drift/database_provider.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/capture/application/capture_controller.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/profile/domain/profile_state.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

import '../../../helpers/mobile_test_harness.dart';

void main() {
  setUp(() {
    RouterAuthController.initialState = const AsyncData(AuthState.signedOut());
    RouterProfileController.initialState =
        const AsyncData(ProfileState.empty());
  });

  testWidgets('auth loading stays on auth when already on auth',
      (tester) async {
    final container = await _pumpRouter(tester);

    expect(find.byKey(const ValueKey('screen.auth')), findsOneWidget);

    (container.read(authControllerProvider.notifier) as RouterAuthController)
        .setLoading();
    await tester.pump();

    expect(find.byKey(const ValueKey('screen.auth')), findsOneWidget);
  });

  testWidgets('auth loading on a protected route redirects to splash',
      (tester) async {
    RouterAuthController.initialState =
        const AsyncData(AuthState.signedIn('user-1'));
    final container = await _pumpRouter(tester);

    expect(find.byKey(const ValueKey('screen.onboarding')), findsOneWidget);

    container.read(appRouterProvider).go('/home');
    await tester.pumpAndSettle();
    (container.read(authControllerProvider.notifier) as RouterAuthController)
        .setLoading();
    await tester.pump();
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('screen.auth')), findsNothing);
  });

  testWidgets('password recovery routes to auth, not onboarding or home',
      (tester) async {
    RouterAuthController.initialState =
        const AsyncData(AuthState.passwordRecovery('user-1'));

    await _pumpRouter(tester);

    expect(find.byKey(const ValueKey('screen.auth')), findsOneWidget);
    expect(find.byKey(const ValueKey('screen.onboarding')), findsNothing);
  });

  testWidgets('signed in users still route through profile onboarding',
      (tester) async {
    RouterAuthController.initialState =
        const AsyncData(AuthState.signedIn('user-1'));

    await _pumpRouter(tester);

    expect(find.byKey(const ValueKey('screen.onboarding')), findsOneWidget);
    expect(find.byKey(const ValueKey('screen.auth')), findsNothing);
  });

  testWidgets('signed-out users cannot stay on protected routes',
      (tester) async {
    final container = await _pumpRouter(tester);

    container.read(appRouterProvider).go('/home');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('screen.auth')), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('profile loading on a protected route redirects to splash',
      (tester) async {
    RouterAuthController.initialState =
        const AsyncData(AuthState.signedIn('user-1'));
    RouterProfileController.initialState = const AsyncLoading();

    final container = await _pumpRouter(tester);
    container.read(appRouterProvider).go('/home');
    await tester.pump();
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('profile-complete signed-in users land on home', (tester) async {
    RouterAuthController.initialState =
        const AsyncData(AuthState.signedIn(testUserId));
    RouterProfileController.initialState = AsyncData(
      ProfileState(
        profile: testProfile(),
        activeGoal: testGoal(),
        featureFlags: E2eData.enabledFlags,
        syncStatus: ProfileSyncStatus.synced,
      ),
    );

    await _pumpRouter(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(find.byKey(const ValueKey('screen.auth')), findsNothing);
    expect(find.byKey(const ValueKey('screen.onboarding')), findsNothing);
  });

  testWidgets('profile-complete signed-in users are kept out of auth',
      (tester) async {
    RouterAuthController.initialState =
        const AsyncData(AuthState.signedIn(testUserId));
    RouterProfileController.initialState = AsyncData(
      ProfileState(
        profile: testProfile(),
        activeGoal: testGoal(),
        featureFlags: E2eData.enabledFlags,
        syncStatus: ProfileSyncStatus.synced,
      ),
    );
    final container = await _pumpRouter(tester);

    container.read(appRouterProvider).go('/auth');
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.byKey(const ValueKey('screen.auth')), findsNothing);
  });
}

Future<ProviderContainer> _pumpRouter(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfig(
          environment: 'dev',
          supabaseUrl: 'http://localhost:54321',
          supabaseAnonKey: 'test-anon-key',
          e2eEnabled: false,
          e2eBackend: '',
          e2eAuth: '',
        ),
      ),
      appDatabaseProvider.overrideWithValue(db),
      authControllerProvider.overrideWith(RouterAuthController.new),
      profileControllerProvider.overrideWith(RouterProfileController.new),
      syncControllerProvider.overrideWith(IdleSyncController.new),
      captureControllerProvider.overrideWith(StaticCaptureController.new),
      userDayTickProvider
          .overrideWith((ref, timezone) => DateTime(2026, 5, 30)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          return MaterialApp.router(routerConfig: ref.watch(appRouterProvider));
        },
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return container;
}

class RouterAuthController extends AuthController {
  static AsyncValue<AuthState> initialState =
      const AsyncData(AuthState.signedOut());
  final _loadingCompleter = Completer<AuthState>();

  @override
  Future<AuthState> build() async {
    final value = initialState;
    if (value.hasValue) return value.requireValue;
    if (value.hasError) {
      Error.throwWithStackTrace(value.error!, value.stackTrace!);
    }
    return _loadingCompleter.future;
  }

  void setLoading() {
    state = const AsyncLoading();
  }
}

class RouterProfileController extends ProfileController {
  static AsyncValue<ProfileState> initialState =
      const AsyncData(ProfileState.empty());

  @override
  Future<ProfileState> build() async {
    final value = initialState;
    if (value.hasValue) return value.requireValue;
    if (value.hasError) {
      Error.throwWithStackTrace(value.error!, value.stackTrace!);
    }
    return Completer<ProfileState>().future;
  }
}

class IdleSyncController extends SyncController {
  @override
  Future<SyncStatus> build() async => SyncStatus.idle;
}
