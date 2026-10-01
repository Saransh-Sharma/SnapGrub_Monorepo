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

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Create account'));
    await tester.pump();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirm password'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign in instead'));
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('sign-up validates password setup before sending code',
      (tester) async {
    FakeAuthController.emitLoadingDuringCodeRequests = true;
    await _pumpAuthScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'new@example.com',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Create account'));
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

    expect(find.text('Passwords don’t match.'), findsOneWidget);
    expect(FakeAuthController.calls, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'longpass1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(FakeAuthController.calls, ['signUpWithPassword:new@example.com']);
    expect(find.text('Confirm your email'), findsOneWidget);
    expect(
      find.text('Code sent. Check your email.'),
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
    await _openMoreOptions(tester);
    await _tapText(tester, 'Email me a code');
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(FakeAuthController.calls, ['requestSignInOtp:user@example.com']);
    expect(find.text('Check your email'), findsOneWidget);
    expect(_otpField, findsOneWidget);

    // Six digits auto-submit; a manual tap afterwards never double-sends.
    await tester.enterText(_otpField, '123456');
    await tester.pump();
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
    await _openMoreOptions(tester);
    await _tapText(tester, 'Forgot password?');
    await tester.pump();

    expect(find.text('Reset your password'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await tester.pump();
    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(
      FakeAuthController.calls,
      ['requestPasswordRecovery:recover@example.com'],
    );
    expect(find.text('Enter recovery code'), findsOneWidget);

    await tester.enterText(_otpField, '654321');
    await tester.pumpAndSettle();

    expect(find.text('Set a new password'), findsOneWidget);
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

  testWidgets('auth failures show friendly non-enumerating error',
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
        'Couldn’t sign in. Check your details and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('raw auth failure'), findsNothing);
  });

  testWidgets('canceling after recovery verification signs out',
      (tester) async {
    await _pumpAuthScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'recover@example.com',
    );
    await _openMoreOptions(tester);
    await _tapText(tester, 'Forgot password?');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await tester.pump();
    await tester.enterText(_otpField, '654321');
    await tester.pumpAndSettle();

    expect(find.text('Set a new password'), findsOneWidget);
    final signInInstead =
        find.widgetWithText(OutlinedButton, 'Sign in instead');
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
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('email validation rejects malformed addresses', (tester) async {
    await _pumpAuthScreen(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'a@b');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password'), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(
      find.text('That email doesn’t look right.'),
      findsOneWidget,
    );
    expect(FakeAuthController.calls, isEmpty);
  });

  testWidgets('password visibility toggles', (tester) async {
    await _pumpAuthScreen(tester);

    EditableText editable() => tester.widget<EditableText>(find.descendant(
          of: find.widgetWithText(TextField, 'Password'),
          matching: find.byType(EditableText),
        ));

    expect(editable().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(editable().obscureText, isFalse);
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(editable().obscureText, isTrue);
  });

  testWidgets('more options folds secondary sign-in paths', (tester) async {
    await _pumpAuthScreen(tester);

    expect(find.text('Email me a code'), findsNothing);
    expect(find.text('Forgot password?'), findsNothing);

    await _openMoreOptions(tester);

    expect(find.text('Email me a code'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth.signin_send_code')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth.forgot_password')), findsOneWidget);
  });

  testWidgets('wrong code shows specific error and clears the boxes',
      (tester) async {
    FakeAuthController.verifyError = StateError('otp_expired');
    await _pumpAuthScreen(tester);

    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'user@example.com');
    await _openMoreOptions(tester);
    await _tapText(tester, 'Email me a code');
    await tester.pumpAndSettle();

    await tester.enterText(_otpField, '111111');
    await tester.pumpAndSettle();

    expect(find.text('Code expired. Get a new one.'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth.error')), findsOneWidget);
    expect(tester.widget<TextField>(_otpField).controller!.text, isEmpty);

    // A corrected code can be submitted again.
    FakeAuthController.verifyError = null;
    await tester.enterText(_otpField, '222222');
    await tester.pumpAndSettle();
    expect(
      FakeAuthController.calls.where((c) => c.startsWith('verifySignInOtp')),
      hasLength(2),
    );
  });

  testWidgets('pasting a formatted code keeps only six digits', (tester) async {
    await _pumpAuthScreen(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'user@example.com');
    await _openMoreOptions(tester);
    await _tapText(tester, 'Email me a code');
    await tester.pumpAndSettle();

    await tester.enterText(_otpField, '123-456 789');
    await tester.pump();

    expect(tester.widget<TextField>(_otpField).controller!.text, '123456');
    expect(FakeAuthController.calls.last,
        'verifySignInOtp:user@example.com:123456');
  });

  testWidgets('resend is disabled for 30 seconds after sending',
      (tester) async {
    await _pumpAuthScreen(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'user@example.com');
    await _openMoreOptions(tester);
    await _tapText(tester, 'Email me a code');
    await tester.pumpAndSettle();

    final resend = find.descendant(
      of: find.byKey(const ValueKey('auth.resend_code')),
      matching: find.byWidgetPredicate((w) => w is TextButton),
    );
    final countdown = find.textContaining(RegExp(r'^Resend in \d+s$'));
    expect(countdown, findsOneWidget);
    expect(tester.widget<TextButton>(resend).onPressed, isNull);

    await tester.pump(const Duration(seconds: 10));
    expect(countdown, findsOneWidget);
    expect(tester.widget<TextButton>(resend).onPressed, isNull);

    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();
    expect(find.text('Resend code'), findsOneWidget);
    expect(tester.widget<TextButton>(resend).onPressed, isNotNull);

    await tester.ensureVisible(resend);
    await tester.tap(resend);
    await tester.pump();
    expect(
      FakeAuthController.calls,
      [
        'requestSignInOtp:user@example.com',
        'requestSignInOtp:user@example.com',
      ],
    );
    expect(find.text('Resend in 30s'), findsOneWidget);
  });

  testWidgets('auth screen meets tap target and label guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpAuthScreen(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('auth screen fits at 2x text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_authScreen(textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final signIn = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(signIn);
    expect(signIn, findsOneWidget);
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
        'Supabase isn’t configured. Run with SUPABASE_URL and SUPABASE_ANON_KEY dart defines.',
      ),
      findsOneWidget,
    );
    final button = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign in'));
    expect(button.onPressed, isNull);
  });
}

final _otpField = find.descendant(
  of: find.byKey(const ValueKey('auth.email_otp')),
  matching: find.byType(TextField),
);

Future<void> _openMoreOptions(WidgetTester tester) async {
  await _tapText(tester, 'More options');
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _pumpAuthScreen(WidgetTester tester) async {
  await tester.pumpWidget(_authScreen());
  await tester.pumpAndSettle();
}

Widget _authScreen({double textScale = 1}) {
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
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const AuthScreen(),
    ),
  );
}

class FakeAuthController extends AuthController {
  static final calls = <String>[];
  static bool throwOnPasswordSignIn = false;
  static bool emitLoadingDuringCodeRequests = false;
  static Object? verifyError;

  static void reset() {
    verifyError = null;
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
    if (verifyError != null) throw verifyError!;
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
