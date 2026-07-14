import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/app/env/app_config.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/auth/presentation/auth_screen.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

import '../../../helpers/mobile_test_harness.dart';

void main() {
  setUp(FakeAuthController.reset);

  testWidgets('starts in password sign-in and switches to sign-up copy',
      (tester) async {
    await _pumpAuthScreen(tester);

    expect(find.text('Sign in to continue.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Create account'));
    await tester.pump();

    expect(find.text('Create your account.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirm password'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Sign in instead'));
    await tester.pump();

    expect(find.text('Sign in to continue.'), findsOneWidget);
  });

  testWidgets('sign-up validates password setup before sending code',
      (tester) async {
    FakeAuthController.emitLoadingDuringCodeRequests = true;
    await _pumpAuthScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'new@example.com',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Create account'));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'short');
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'short',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(FakeAuthController.calls, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'longpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'longpass2',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(FakeAuthController.calls, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'longpass1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('Create your account.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(FakeAuthController.calls, ['signUpWithPassword:new@example.com']);
    expect(find.text('Confirm your email.'), findsOneWidget);
    expect(
      find.text('Check your email for a confirmation code.'),
      findsOneWidget,
    );
  });

  testWidgets('sign-in OTP fallback sends and verifies code', (tester) async {
    FakeAuthController.emitLoadingDuringCodeRequests = true;
    await _pumpAuthScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Email me a code'));
    await tester.pump();
    expect(find.text('Sign in to continue.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(FakeAuthController.calls, ['requestSignInOtp:user@example.com']);
    expect(find.text('Enter the code sent to your email.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email code'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Email code'), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify code'));
    await tester.pump();

    expect(
      FakeAuthController.calls,
      [
        'requestSignInOtp:user@example.com',
        'verifySignInOtp:user@example.com:123456',
      ],
    );
  });

  testWidgets('forgot password verifies recovery code before new password',
      (tester) async {
    FakeAuthController.emitLoadingDuringCodeRequests = true;
    await _pumpAuthScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'recover@example.com',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Forgot password'));
    await tester.pump();

    expect(find.text('Reset your password.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Send recovery code'));
    await tester.pump();
    expect(find.text('Reset your password.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(
      FakeAuthController.calls,
      ['requestPasswordRecovery:recover@example.com'],
    );
    expect(find.text('Enter the recovery code.'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Email code'), '654321');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify code'));
    await tester.pumpAndSettle();

    expect(find.text('Set a new password.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'New password'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'New password'),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm new password'),
      'newpass1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
    await tester.pump();

    expect(
      FakeAuthController.calls,
      [
        'requestPasswordRecovery:recover@example.com',
        'verifyRecoveryOtp:recover@example.com:654321',
        'setRecoveredPassword',
      ],
    );
  });

  testWidgets('auth failures show generic non-enumerating error',
      (tester) async {
    FakeAuthController.throwOnPasswordSignIn = true;
    await _pumpAuthScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'wrong-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(
      find.text(
        'Couldn\'t complete that request. Check your details or try another sign-in option.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('canceling after recovery verification signs out',
      (tester) async {
    await _pumpAuthScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'recover@example.com',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Forgot password'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send recovery code'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, 'Email code'), '654321');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify code'));
    await tester.pumpAndSettle();

    expect(find.text('Set a new password.'), findsOneWidget);
    final signInInstead = find.widgetWithText(TextButton, 'Sign in instead');
    await tester.ensureVisible(signInInstead);
    await tester.tap(signInInstead);
    await tester.pumpAndSettle();

    expect(
      FakeAuthController.calls,
      [
        'requestPasswordRecovery:recover@example.com',
        'verifyRecoveryOtp:recover@example.com:654321',
        'cancelPasswordRecovery',
      ],
    );
    expect(find.text('Sign in to continue.'), findsOneWidget);
  });

  testWidgets('e2e mock password sign-in stores a signed-in user',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(testE2eConfig),
          syncControllerProvider.overrideWith(IdleSyncController.new),
        ],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'e2e@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('snapgrub.e2e.user_id'),
      'e2e-e2e-example-com',
    );
  });

  testWidgets('missing Supabase config disables primary auth action',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(testMissingConfig),
          syncControllerProvider.overrideWith(IdleSyncController.new),
        ],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Supabase is not configured. Launch with SUPABASE_URL and SUPABASE_ANON_KEY dart defines.',
      ),
      findsOneWidget,
    );
    final button = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign in'));
    expect(button.onPressed, isNull);
  });
}

Future<void> _pumpAuthScreen(WidgetTester tester) async {
  await tester.pumpWidget(_authScreen());
  await tester.pumpAndSettle();
}

Widget _authScreen() {
  return ProviderScope(
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
      authControllerProvider.overrideWith(FakeAuthController.new),
      syncControllerProvider.overrideWith(IdleSyncController.new),
    ],
    child: const MaterialApp(home: AuthScreen()),
  );
}

class FakeAuthController extends AuthController {
  static final calls = <String>[];
  static bool throwOnPasswordSignIn = false;
  static bool emitLoadingDuringCodeRequests = false;

  static void reset() {
    calls.clear();
    throwOnPasswordSignIn = false;
    emitLoadingDuringCodeRequests = false;
  }

  @override
  Future<AuthState> build() async => const AuthState.signedOut();

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    calls.add('signInWithPassword:$email');
    if (throwOnPasswordSignIn) throw StateError('raw auth failure');
  }

  @override
  Future<void> requestSignInOtp(String email) async {
    calls.add('requestSignInOtp:$email');
    if (emitLoadingDuringCodeRequests) {
      state = const AsyncLoading();
      await Future<void>.delayed(Duration.zero);
      state = const AsyncData(AuthState.signedOut());
    }
  }

  @override
  Future<void> verifySignInOtp({
    required String email,
    required String token,
  }) async {
    calls.add('verifySignInOtp:$email:$token');
  }

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    calls.add('signUpWithPassword:$email');
    if (emitLoadingDuringCodeRequests) {
      state = const AsyncLoading();
      await Future<void>.delayed(Duration.zero);
      state = const AsyncData(AuthState.signedOut());
    }
  }

  @override
  Future<void> resendSignUpOtp(String email) async {
    calls.add('resendSignUpOtp:$email');
  }

  @override
  Future<void> verifySignUpOtp({
    required String email,
    required String token,
  }) async {
    calls.add('verifySignUpOtp:$email:$token');
  }

  @override
  Future<void> requestPasswordRecovery(String email) async {
    calls.add('requestPasswordRecovery:$email');
    if (emitLoadingDuringCodeRequests) {
      state = const AsyncLoading();
      await Future<void>.delayed(Duration.zero);
      state = const AsyncData(AuthState.signedOut());
    }
  }

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    calls.add('verifyRecoveryOtp:$email:$token');
    state = const AsyncData(AuthState.passwordRecovery('recovery-user'));
  }

  @override
  Future<void> setRecoveredPassword(String password) async {
    calls.add('setRecoveredPassword');
  }

  @override
  Future<void> cancelPasswordRecovery() async {
    calls.add('cancelPasswordRecovery');
    state = const AsyncData(AuthState.signedOut());
  }
}

class IdleSyncController extends SyncController {
  @override
  Future<SyncStatus> build() async => SyncStatus.idle;
}
