import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static const _minimumPasswordLength = 8;
  static const _genericAuthError =
      'Couldn\'t complete that request. Check your details or try another sign-in option.';

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

    return AppScaffold(
      title: 'SnapGrub',
      child: E2eId(
        id: 'screen.auth',
        child: ListView(
          children: [
            Text(
              _headline,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _supportingCopy,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (!config.hasSupabaseConfig && !config.isE2eMock)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Supabase is not configured. Launch with SUPABASE_URL and SUPABASE_ANON_KEY dart defines.',
                  ),
                ),
              ),
            if (_showsEmailField) ...[
              E2eId(
                id: 'auth.email',
                child: TextField(
                  controller: _emailController,
                  enabled: !_locksEmail && !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ..._modeFields(isLoading, canUseAuth),
            if (_error != null) ...[
              const SizedBox(height: 12),
              E2eId(
                id: 'auth.error',
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              E2eId(id: 'auth.message', child: Text(_message!)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _modeFields(bool isLoading, bool canUseAuth) {
    switch (_mode) {
      case _AuthMode.signInPassword:
        return [
          _passwordField(
            controller: _passwordController,
            id: 'auth.password',
            label: 'Password',
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 16),
          _primaryButton(
            id: 'auth.password_sign_in',
            label: 'Sign in',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _signInWithPassword,
          ),
          const SizedBox(height: 8),
          _secondaryButton(
            id: 'auth.signin_send_code',
            label: 'Email me a code',
            onPressed: isLoading || !canUseAuth ? null : _requestSignInOtp,
          ),
          _secondaryButton(
            id: 'auth.forgot_password',
            label: 'Forgot password',
            onPressed:
                isLoading ? null : () => _switchMode(_AuthMode.recoveryEmail),
          ),
          _secondaryButton(
            id: 'auth.create_account',
            label: 'Create account',
            onPressed: isLoading ? null : () => _switchMode(_AuthMode.signUp),
          ),
        ];
      case _AuthMode.signInOtp:
        return [
          _otpField(),
          const SizedBox(height: 16),
          _primaryButton(
            id: 'auth.verify_code',
            label: 'Verify code',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _verifySignInOtp,
          ),
          const SizedBox(height: 8),
          _secondaryButton(
            id: 'auth.resend_code',
            label: 'Resend code',
            onPressed: isLoading || !canUseAuth ? null : _requestSignInOtp,
          ),
          _secondaryButton(
            id: 'auth.use_password',
            label: 'Use password instead',
            onPressed:
                isLoading ? null : () => _switchMode(_AuthMode.signInPassword),
          ),
          _secondaryButton(
            id: 'auth.create_account',
            label: 'Create account',
            onPressed: isLoading ? null : () => _switchMode(_AuthMode.signUp),
          ),
        ];
      case _AuthMode.signUp:
        return [
          _passwordField(
            controller: _passwordController,
            id: 'auth.signup_password',
            label: 'Password',
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 16),
          _passwordField(
            controller: _confirmPasswordController,
            id: 'auth.signup_confirm_password',
            label: 'Confirm password',
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 16),
          _primaryButton(
            id: 'auth.signup_create',
            label: 'Create account',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _signUpWithPassword,
          ),
          const SizedBox(height: 8),
          _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed: isLoading ? null : _cancelPasswordRecovery,
          ),
        ];
      case _AuthMode.signUpOtp:
        return [
          _otpField(),
          const SizedBox(height: 16),
          _primaryButton(
            id: 'auth.signup_verify_code',
            label: 'Verify code',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _verifySignUpOtp,
          ),
          const SizedBox(height: 8),
          _secondaryButton(
            id: 'auth.resend_signup_code',
            label: 'Resend code',
            onPressed: isLoading || !canUseAuth ? null : _resendSignUpOtp,
          ),
          _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed: isLoading ? null : _cancelPasswordRecovery,
          ),
        ];
      case _AuthMode.recoveryEmail:
        return [
          _primaryButton(
            id: 'auth.recovery_send_code',
            label: 'Send recovery code',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _requestPasswordRecovery,
          ),
          const SizedBox(height: 8),
          _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed:
                isLoading ? null : () => _switchMode(_AuthMode.signInPassword),
          ),
        ];
      case _AuthMode.recoveryOtp:
        return [
          _otpField(),
          const SizedBox(height: 16),
          _primaryButton(
            id: 'auth.recovery_verify_code',
            label: 'Verify code',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _verifyRecoveryOtp,
          ),
          const SizedBox(height: 8),
          _secondaryButton(
            id: 'auth.resend_recovery_code',
            label: 'Resend code',
            onPressed:
                isLoading || !canUseAuth ? null : _requestPasswordRecovery,
          ),
          _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed:
                isLoading ? null : () => _switchMode(_AuthMode.signInPassword),
          ),
        ];
      case _AuthMode.recoveryPassword:
        return [
          _passwordField(
            controller: _newPasswordController,
            id: 'auth.new_password',
            label: 'New password',
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 16),
          _passwordField(
            controller: _confirmNewPasswordController,
            id: 'auth.confirm_new_password',
            label: 'Confirm new password',
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 16),
          _primaryButton(
            id: 'auth.set_new_password',
            label: 'Save password',
            isLoading: isLoading,
            enabled: canUseAuth,
            onPressed: _setRecoveredPassword,
          ),
          const SizedBox(height: 8),
          _secondaryButton(
            id: 'auth.sign_in_instead',
            label: 'Sign in instead',
            onPressed: isLoading ? null : _cancelPasswordRecovery,
          ),
        ];
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String id,
    required String label,
    Iterable<String>? autofillHints,
  }) {
    return E2eId(
      id: id,
      child: TextField(
        controller: controller,
        obscureText: true,
        autofillHints: autofillHints,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _otpField() {
    return E2eId(
      id: 'auth.email_otp',
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Email code'),
      ),
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
        onPressed: isLoading || !enabled ? null : onPressed,
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
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
      child: TextButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  String get _headline {
    switch (_mode) {
      case _AuthMode.signInPassword:
        return 'Sign in to continue.';
      case _AuthMode.signInOtp:
        return 'Enter the code sent to your email.';
      case _AuthMode.signUp:
        return 'Create your account.';
      case _AuthMode.signUpOtp:
        return 'Confirm your email.';
      case _AuthMode.recoveryEmail:
        return 'Reset your password.';
      case _AuthMode.recoveryOtp:
        return 'Enter the recovery code.';
      case _AuthMode.recoveryPassword:
        return 'Set a new password.';
    }
  }

  String get _supportingCopy {
    switch (_mode) {
      case _AuthMode.signInPassword:
        return 'Use your password, or get a one-time code by email.';
      case _AuthMode.signInOtp:
        return 'Use the code from your email. This will not create a new account.';
      case _AuthMode.signUp:
        return 'Set a password first, then confirm your email with a code.';
      case _AuthMode.signUpOtp:
        return 'Enter the code from your email to finish creating your account.';
      case _AuthMode.recoveryEmail:
        return 'We will email a recovery code if this address can be used.';
      case _AuthMode.recoveryOtp:
        return 'Verify the recovery code before choosing a new password.';
      case _AuthMode.recoveryPassword:
        return 'Choose a new password for future sign-ins.';
    }
  }

  bool get _showsEmailField => _mode != _AuthMode.recoveryPassword;

  bool get _locksEmail =>
      _mode == _AuthMode.signInOtp ||
      _mode == _AuthMode.signUpOtp ||
      _mode == _AuthMode.recoveryOtp;

  String get _email => (_pendingEmail ?? _emailController.text).trim();

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _message = null;
      _error = null;
      _otpController.clear();
      if (mode == _AuthMode.signInPassword ||
          mode == _AuthMode.signUp ||
          mode == _AuthMode.recoveryEmail) {
        _pendingEmail = null;
      }
    });
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
    final email = _validatedEmail();
    if (email == null) return;
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).requestSignInOtp(email),
      successMessage: 'Check your email for a sign-in code.',
      onSuccess: () {
        _pendingEmail = email;
        _mode = _AuthMode.signInOtp;
        _otpController.clear();
      },
    );
  }

  Future<void> _verifySignInOtp() async {
    final token = _validatedOtp();
    if (token == null) return;
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).verifySignInOtp(
            email: _email,
            token: token,
          ),
      successMessage: null,
    );
  }

  Future<void> _signUpWithPassword() async {
    final email = _validatedEmail();
    if (email == null || !_validatePasswordSetup()) return;
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).signUpWithPassword(
            email: email,
            password: _passwordController.text,
          ),
      successMessage: 'Check your email for a confirmation code.',
      onSuccess: () {
        _pendingEmail = email;
        _mode = _AuthMode.signUpOtp;
        _otpController.clear();
      },
    );
  }

  Future<void> _resendSignUpOtp() async {
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).resendSignUpOtp(_email),
      successMessage: 'Check your email for a confirmation code.',
    );
  }

  Future<void> _verifySignUpOtp() async {
    final token = _validatedOtp();
    if (token == null) return;
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).verifySignUpOtp(
            email: _email,
            token: token,
          ),
      successMessage: null,
    );
  }

  Future<void> _requestPasswordRecovery() async {
    final email = _validatedEmail();
    if (email == null) return;
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).requestPasswordRecovery(
            email,
          ),
      successMessage: 'Check your email for a recovery code.',
      onSuccess: () {
        _pendingEmail = email;
        _mode = _AuthMode.recoveryOtp;
        _otpController.clear();
      },
    );
  }

  Future<void> _verifyRecoveryOtp() async {
    final token = _validatedOtp();
    if (token == null) return;
    await _runAuthAction(
      () => ref.read(authControllerProvider.notifier).verifyRecoveryOtp(
            email: _email,
            token: token,
          ),
      successMessage: null,
      onSuccess: () {
        _mode = _AuthMode.recoveryPassword;
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
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
  }) async {
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _error = null;
        _message = successMessage;
        onSuccess?.call();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = null;
        _error = _genericAuthError;
      });
    }
  }

  String? _validatedEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter a valid email address.');
      return null;
    }
    return email;
  }

  String? _validatedOtp() {
    final token = _otpController.text.trim();
    if (token.isEmpty) {
      _showError('Enter the code from your email.');
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
      _showError('Passwords do not match.');
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

enum _AuthMode {
  signInPassword,
  signInOtp,
  signUp,
  signUpOtp,
  recoveryEmail,
  recoveryOtp,
  recoveryPassword,
}
