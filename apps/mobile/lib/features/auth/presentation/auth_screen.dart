import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:snapgrub/features/auth/presentation/widgets/otp_code_input.dart';

/// Email + password / one-time-code authentication.
///
/// Seven modes share one screen: password sign-in, code sign-in, sign-up,
/// sign-up confirmation, recovery email, recovery code and new password.
/// Each mode shows one primary and at most one secondary action; anything
/// else folds under "More options".
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

/// Loose-but-real email check: something@domain.tld, no spaces.
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@.]+(\.[^\s@.]+)*\.[A-Za-z]{2,}$');

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static const _minimumPasswordLength = 8;
  static const _otpLength = 6;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signInPassword;
  String? _pendingEmail;
  String? _message;
  String? _error;

  /// Bumped to shake / shimmer the code boxes.
  int _otpErrorSignal = 0;
  int _otpSuccessSignal = 0;

  /// Bumped whenever a code is (re)sent, restarting the resend cooldown.
  int _codeSentToken = 0;

  /// Last code submitted, so auto-submit and a manual tap never double-send.
  String? _submittedOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final auth = ref.watch(authControllerProvider);
    final isLoading = auth.isLoading;
    final canUseAuth = config.hasSupabaseConfig || config.isE2eMock;
    final media = MediaQuery.of(context);
    final isCompact = media.size.height < 720 ||
        media.textScaler.scale(16) > 16 * 1.5;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = SgMotion.of(context);
    final spec = _spec(isLoading, canUseAuth);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshAurora()),
          SafeArea(
            child: E2eId(
              id: 'screen.auth',
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  SnapGrubDesignTokens.space20,
                  isCompact
                      ? SnapGrubDesignTokens.space16
                      : SnapGrubDesignTokens.space40,
                  SnapGrubDesignTokens.space20,
                  SnapGrubDesignTokens.space32,
                ),
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(
                              mode: _mode,
                              headline: _headline,
                              supporting: _supportingCopy,
                              compact: isCompact,
                            ),
                            SizedBox(
                              height: isCompact
                                  ? SnapGrubDesignTokens.space16
                                  : SnapGrubDesignTokens.space32,
                            ),
                            if (!config.hasSupabaseConfig &&
                                !config.isE2eMock) ...[
                              const SgCard(
                                child: Text(
                                  'Supabase isn’t configured. Run with SUPABASE_URL and SUPABASE_ANON_KEY dart defines.',
                                ),
                              ),
                              const SizedBox(
                                  height: SnapGrubDesignTokens.space16),
                            ],
                            if (_showsEmailField) ...[
                              _emailField(isLoading),
                              const SizedBox(
                                  height: SnapGrubDesignTokens.space16),
                            ],
                            TweenAnimationBuilder<double>(
                              key: ValueKey(_mode),
                              tween: Tween(begin: 0, end: 1),
                              duration: motion.settle,
                              curve: motion.emphasized,
                              builder: (context, value, child) => Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...spec.fields,
                                  _feedback(),
                                  const SizedBox(
                                      height: SnapGrubDesignTokens.space20),
                                  spec.primary,
                                  if (spec.secondary != null) ...[
                                    const SizedBox(
                                        height: SnapGrubDesignTokens.space8),
                                    spec.secondary!,
                                  ],
                                  if (spec.more.isNotEmpty) ...[
                                    const SizedBox(
                                        height: SnapGrubDesignTokens.space8),
                                    AuthMoreOptions(
                                      key: ValueKey('more-$_mode'),
                                      children: spec.more,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout per mode
  // ---------------------------------------------------------------------------

  _ModeSpec _spec(bool isLoading, bool canUseAuth) {
    VoidCallback? unlessLoading(VoidCallback action) =>
        isLoading ? null : action;
    VoidCallback? whenReady(VoidCallback action) =>
        isLoading || !canUseAuth ? null : action;

    switch (_mode) {
      case _AuthMode.signInPassword:
        return _ModeSpec(
          fields: [
            _passwordField(
              controller: _passwordController,
              id: 'auth.password',
              label: 'Password',
              autofillHints: const [AutofillHints.password],
              isLoading: isLoading,
              textInputAction: TextInputAction.done,
              onSubmitted: canUseAuth && !isLoading
                  ? (_) => _signInWithPassword()
                  : null,
            ),
          ],
          primary: _primaryButton(
            id: 'auth.password_sign_in',
            label: 'Sign in',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _signInWithPassword,
          ),
          secondary: _secondaryButton(
            id: 'auth.create_account',
            label: 'Create account',
            onPressed: unlessLoading(() => _switchMode(_AuthMode.signUp)),
          ),
          more: [
            _moreOption(
              id: 'auth.signin_send_code',
              label: 'Email me a code',
              icon: Icons.mark_email_unread_outlined,
              onPressed: whenReady(_requestSignInOtp),
            ),
            _moreOption(
              id: 'auth.forgot_password',
              label: 'Forgot password?',
              icon: Icons.key_outlined,
              onPressed:
                  unlessLoading(() => _switchMode(_AuthMode.recoveryEmail)),
            ),
          ],
        );
      case _AuthMode.signInOtp:
        return _ModeSpec(
          fields: _otpFields(
            isLoading: isLoading,
            resendId: 'auth.resend_code',
            onResend: whenReady(_requestSignInOtp),
            onCompleted: _verifySignInOtp,
          ),
          primary: _primaryButton(
            id: 'auth.verify_code',
            label: 'Verify code',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _verifySignInOtp,
          ),
          secondary: _secondaryButton(
            id: 'auth.use_password',
            label: 'Use password instead',
            onPressed:
                unlessLoading(() => _switchMode(_AuthMode.signInPassword)),
          ),
          more: [
            _moreOption(
              id: 'auth.create_account',
              label: 'Create account',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: unlessLoading(() => _switchMode(_AuthMode.signUp)),
            ),
          ],
        );
      case _AuthMode.signUp:
        return _ModeSpec(
          fields: [
            _passwordField(
              controller: _passwordController,
              id: 'auth.signup_password',
              label: 'Password',
              helperText: 'At least $_minimumPasswordLength characters',
              autofillHints: const [AutofillHints.newPassword],
              isLoading: isLoading,
            ),
            const SizedBox(height: SnapGrubDesignTokens.space16),
            _passwordField(
              controller: _confirmPasswordController,
              id: 'auth.signup_confirm_password',
              label: 'Confirm password',
              autofillHints: const [AutofillHints.newPassword],
              isLoading: isLoading,
              textInputAction: TextInputAction.done,
              onSubmitted: canUseAuth && !isLoading
                  ? (_) => _signUpWithPassword()
                  : null,
            ),
          ],
          primary: _primaryButton(
            id: 'auth.signup_create',
            label: 'Create account',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _signUpWithPassword,
          ),
          secondary: _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed: unlessLoading(_cancelPasswordRecovery),
          ),
        );
      case _AuthMode.signUpOtp:
        return _ModeSpec(
          fields: _otpFields(
            isLoading: isLoading,
            resendId: 'auth.resend_signup_code',
            onResend: whenReady(_resendSignUpOtp),
            onCompleted: _verifySignUpOtp,
          ),
          primary: _primaryButton(
            id: 'auth.signup_verify_code',
            label: 'Verify code',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _verifySignUpOtp,
          ),
          secondary: _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed: unlessLoading(_cancelPasswordRecovery),
          ),
        );
      case _AuthMode.recoveryEmail:
        return _ModeSpec(
          fields: const [],
          primary: _primaryButton(
            id: 'auth.recovery_send_code',
            label: 'Send code',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _requestPasswordRecovery,
          ),
          secondary: _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed:
                unlessLoading(() => _switchMode(_AuthMode.signInPassword)),
          ),
        );
      case _AuthMode.recoveryOtp:
        return _ModeSpec(
          fields: _otpFields(
            isLoading: isLoading,
            resendId: 'auth.resend_recovery_code',
            onResend: whenReady(_requestPasswordRecovery),
            onCompleted: _verifyRecoveryOtp,
          ),
          primary: _primaryButton(
            id: 'auth.recovery_verify_code',
            label: 'Verify code',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _verifyRecoveryOtp,
          ),
          secondary: _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed:
                unlessLoading(() => _switchMode(_AuthMode.signInPassword)),
          ),
        );
      case _AuthMode.recoveryPassword:
        return _ModeSpec(
          fields: [
            _passwordField(
              controller: _newPasswordController,
              id: 'auth.new_password',
              label: 'New password',
              helperText: 'At least $_minimumPasswordLength characters',
              autofillHints: const [AutofillHints.newPassword],
              isLoading: isLoading,
            ),
            const SizedBox(height: SnapGrubDesignTokens.space16),
            _passwordField(
              controller: _confirmNewPasswordController,
              id: 'auth.confirm_new_password',
              label: 'Confirm new password',
              autofillHints: const [AutofillHints.newPassword],
              isLoading: isLoading,
              textInputAction: TextInputAction.done,
              onSubmitted: canUseAuth && !isLoading
                  ? (_) => _setRecoveredPassword()
                  : null,
            ),
          ],
          primary: _primaryButton(
            id: 'auth.set_new_password',
            label: 'Save password',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _setRecoveredPassword,
          ),
          secondary: _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed: unlessLoading(_cancelPasswordRecovery),
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Pieces
  // ---------------------------------------------------------------------------

  Widget _emailField(bool isLoading) {
    return E2eId(
      id: 'auth.email',
      child: TextField(
        controller: _emailController,
        enabled: !_locksEmail && !isLoading,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.email, AutofillHints.username],
        decoration: InputDecoration(
          labelText: 'Email',
          prefixIcon: const Icon(Icons.alternate_email_rounded),
          helperText: _locksEmail ? 'Code sent to this address' : null,
        ),
      ),
    );
  }

  List<Widget> _otpFields({
    required bool isLoading,
    required String resendId,
    required VoidCallback? onResend,
    required VoidCallback onCompleted,
  }) {
    return [
      E2eId(
        id: 'auth.email_otp',
        child: OtpCodeInput(
          controller: _otpController,
          length: _otpLength,
          hasError: _error != null,
          errorSignal: _otpErrorSignal,
          successSignal: _otpSuccessSignal,
          onCompleted: (_) => onCompleted(),
        ),
      ),
      const SizedBox(height: SnapGrubDesignTokens.space8),
      Align(
        alignment: Alignment.centerLeft,
        child: ResendCodeButton(
          id: resendId,
          restartToken: _codeSentToken,
          onPressed: onResend,
        ),
      ),
    ];
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String id,
    required String label,
    required bool isLoading,
    String? helperText,
    Iterable<String>? autofillHints,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return E2eId(
      id: id,
      child: AuthPasswordField(
        controller: controller,
        label: label,
        helperText: helperText,
        autofillHints: autofillHints,
        enabled: !isLoading,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
      ),
    );
  }

  Widget _feedback() {
    final motion = SgMotion.of(context);
    final Widget child;
    if (_error != null) {
      child = Padding(
        key: ValueKey('error:$_error'),
        padding: const EdgeInsets.only(top: SnapGrubDesignTokens.space16),
        child: E2eId(id: 'auth.error', child: InlineError(message: _error!)),
      );
    } else if (_message != null) {
      child = Padding(
        key: ValueKey('message:$_message'),
        padding: const EdgeInsets.only(top: SnapGrubDesignTokens.space16),
        child: E2eId(id: 'auth.message', child: _Notice(message: _message!)),
      );
    } else {
      child = const SizedBox(width: double.infinity);
    }
    return AnimatedSize(
      duration: motion.settle,
      curve: motion.standard,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  Widget _primaryButton({
    required String id,
    required String label,
    required bool isLoading,
    bool enabled = true,
    required VoidCallback onPressed,
  }) {
    return E2eId(
      id: id,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
        ),
        onPressed: isLoading || !enabled
            ? null
            : () {
                SgHaptics.tap();
                onPressed();
              },
        child: isLoading
            ? Semantics(
                label: 'Loading',
                child: const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Text(label),
      ),
    );
  }

  Widget _secondaryButton({
    required String id,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return E2eId(
      id: id,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _moreOption({
    required String id,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return E2eId(
      id: id,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(
            SnapGrubDesignTokens.minTapTarget,
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  String get _headline {
    switch (_mode) {
      case _AuthMode.signInPassword:
        return 'Welcome back';
      case _AuthMode.signInOtp:
        return 'Check your email';
      case _AuthMode.signUp:
        return 'Create your account';
      case _AuthMode.signUpOtp:
        return 'Confirm your email';
      case _AuthMode.recoveryEmail:
        return 'Reset your password';
      case _AuthMode.recoveryOtp:
        return 'Enter recovery code';
      case _AuthMode.recoveryPassword:
        return 'Set a new password';
    }
  }

  String get _supportingCopy {
    switch (_mode) {
      case _AuthMode.signInPassword:
        return 'Use your password or get a code by email.';
      case _AuthMode.signInOtp:
        return 'Enter the $_otpLength-digit code we emailed you.';
      case _AuthMode.signUp:
        return 'Set a password, then confirm your email.';
      case _AuthMode.signUpOtp:
        return 'Enter the $_otpLength-digit code we emailed you.';
      case _AuthMode.recoveryEmail:
        return 'We’ll email a code if this address has an account.';
      case _AuthMode.recoveryOtp:
        return 'Enter the code, then choose a new password.';
      case _AuthMode.recoveryPassword:
        return 'Use at least $_minimumPasswordLength characters.';
    }
  }

  bool get _showsEmailField => _mode != _AuthMode.recoveryPassword;

  bool get _locksEmail =>
      _mode == _AuthMode.signInOtp ||
      _mode == _AuthMode.signUpOtp ||
      _mode == _AuthMode.recoveryOtp;

  String get _email => (_pendingEmail ?? _emailController.text).trim();

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _message = null;
      _error = null;
      _submittedOtp = null;
      _otpController.clear();
      if (mode == _AuthMode.signInPassword ||
          mode == _AuthMode.signUp ||
          mode == _AuthMode.recoveryEmail) {
        _pendingEmail = null;
      }
    });
  }

  void _enterCodeMode(_AuthMode mode, String email) {
    _pendingEmail = email;
    _mode = mode;
    _submittedOtp = null;
    _otpController.clear();
    _codeSentToken++;
  }

  Future<void> _signInWithPassword() async {
    final email = _validatedEmail();
    if (email == null) return;
    if (_passwordController.text.isEmpty) {
      _showError('Enter your password.');
      return;
    }
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).signInWithPassword(
            email: email,
            password: _passwordController.text,
          ),
      successMessage: null,
    );
  }

  Future<void> _requestSignInOtp() async {
    final email = _mode == _AuthMode.signInOtp ? _email : _validatedEmail();
    if (email == null || email.isEmpty) return;
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).requestSignInOtp(email),
      successMessage: 'Code sent. Check your email.',
      onSuccess: () => _enterCodeMode(_AuthMode.signInOtp, email),
    );
  }

  Future<void> _verifySignInOtp() => _verifyOtp(
        (token) => ref.read(authControllerProvider.notifier).verifySignInOtp(
              email: _email,
              token: token,
            ),
      );

  Future<void> _signUpWithPassword() async {
    final email = _validatedEmail();
    if (email == null || !_validatePasswordSetup()) return;
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).signUpWithPassword(
            email: email,
            password: _passwordController.text,
          ),
      successMessage: 'Code sent. Check your email.',
      onSuccess: () => _enterCodeMode(_AuthMode.signUpOtp, email),
    );
  }

  Future<void> _resendSignUpOtp() async {
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).resendSignUpOtp(_email),
      successMessage: 'New code sent.',
      onSuccess: () {
        _submittedOtp = null;
        _otpController.clear();
        _codeSentToken++;
      },
    );
  }

  Future<void> _verifySignUpOtp() => _verifyOtp(
        (token) => ref.read(authControllerProvider.notifier).verifySignUpOtp(
              email: _email,
              token: token,
            ),
      );

  Future<void> _requestPasswordRecovery() async {
    final email =
        _mode == _AuthMode.recoveryOtp ? _email : _validatedEmail();
    if (email == null || email.isEmpty) return;
    await _runAuthAction(
      () => ref
          .read(authControllerProvider.notifier)
          .requestPasswordRecovery(email),
      successMessage: 'Code sent. Check your email.',
      onSuccess: () => _enterCodeMode(_AuthMode.recoveryOtp, email),
    );
  }

  Future<void> _verifyRecoveryOtp() => _verifyOtp(
        (token) => ref.read(authControllerProvider.notifier).verifyRecoveryOtp(
              email: _email,
              token: token,
            ),
        onSuccess: () {
          _mode = _AuthMode.recoveryPassword;
          _newPasswordController.clear();
          _confirmNewPasswordController.clear();
        },
      );

  /// Shared verify flow: validates the six digits, de-duplicates auto-submit
  /// and manual taps, and plays the shimmer / shake feedback.
  Future<void> _verifyOtp(
    Future<void> Function(String token) verify, {
    VoidCallback? onSuccess,
  }) async {
    final token = _validatedOtp();
    if (token == null) return;
    if (_submittedOtp == token) return;
    _submittedOtp = token;
    await _runAuthAction(
      () => verify(token),
      successMessage: null,
      onSuccess: () {
        _otpSuccessSignal++;
        onSuccess?.call();
      },
      onError: () {
        _submittedOtp = null;
        _otpErrorSignal++;
        _otpController.clear();
      },
    );
  }

  Future<void> _setRecoveredPassword() async {
    if (!_validateNewPasswordSetup()) return;
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).setRecoveredPassword(
            _newPasswordController.text,
          ),
      successMessage: null,
    );
  }

  Future<void> _cancelPasswordRecovery() async {
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).cancelPasswordRecovery(),
      successMessage: null,
      onSuccess: () {
        _mode = _AuthMode.signInPassword;
        _pendingEmail = null;
        _submittedOtp = null;
        _otpController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      },
    );
  }

  Future<void> _runAuthAction(
    Future<void> Function() action, {
    required String? successMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _error = null;
        _message = successMessage;
        onSuccess?.call();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = null;
        _error = authErrorMessage(error);
        onError?.call();
      });
    }
  }

  String? _validatedEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email.');
      return null;
    }
    if (!_emailPattern.hasMatch(email)) {
      _showError('That email doesn’t look right.');
      return null;
    }
    return email;
  }

  String? _validatedOtp() {
    final token = _otpController.text.trim();
    if (token.length != _otpLength) {
      _showError(token.isEmpty
          ? 'Enter the code.'
          : 'Enter all $_otpLength digits.');
      return null;
    }
    return token;
  }

  bool _validatePasswordSetup() {
    return _validatePasswordPair(
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  bool _validateNewPasswordSetup() {
    return _validatePasswordPair(
      password: _newPasswordController.text,
      confirmPassword: _confirmNewPasswordController.text,
    );
  }

  bool _validatePasswordPair({
    required String password,
    required String confirmPassword,
  }) {
    if (password.length < _minimumPasswordLength) {
      _showError('Use at least $_minimumPasswordLength characters.');
      return false;
    }
    if (password != confirmPassword) {
      _showError('Passwords don’t match.');
      return false;
    }
    return true;
  }

  void _showError(String error) {
    setState(() {
      _message = null;
      _error = error;
    });
  }
}

class _ModeSpec {
  const _ModeSpec({
    required this.fields,
    required this.primary,
    this.secondary,
    this.more = const [],
  });

  final List<Widget> fields;
  final Widget primary;
  final Widget? secondary;
  final List<Widget> more;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.mode,
    required this.headline,
    required this.supporting,
    required this.compact,
  });

  final _AuthMode mode;
  final String headline;
  final String supporting;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final motion = SgMotion.of(context);
    final headlineStyle =
        compact ? textTheme.headlineLarge : textTheme.displaySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthMark(size: compact ? 44 : 64, replayKey: mode),
        SizedBox(
          height: compact
              ? SnapGrubDesignTokens.space12
              : SnapGrubDesignTokens.space24,
        ),
        Semantics(
          header: true,
          liveRegion: true,
          child: AnimatedSwitcher(
            duration: motion.settle,
            switchInCurve: motion.standard,
            switchOutCurve: motion.standard,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Text(
              headline,
              key: ValueKey(headline),
              style: headlineStyle,
            ),
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space8),
        Text(
          supporting,
          style: (compact ? textTheme.bodyMedium : textTheme.bodyLarge)
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.sg;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.success.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.mark_email_read_outlined,
                size: 18, color: tokens.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AuthMode {
  signInPassword,
  signInOtp,
  signUp,
  signUpOtp,
  recoveryEmail,
  recoveryOtp,
  recoveryPassword,
}
