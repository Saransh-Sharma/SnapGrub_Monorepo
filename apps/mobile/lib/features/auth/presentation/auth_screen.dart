import 'package:flutter/material.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final auth = ref.watch(authControllerProvider);

    return AppScaffold(
      title: 'SnapGrub',
      child: E2eId(
        id: 'screen.auth',
        child: ListView(
          children: [
            Text(
              'Sign in to start tracking meals.',
              style: Theme.of(context).textTheme.headlineSmall,
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
            E2eId(
              id: 'auth.email',
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ),
            const SizedBox(height: 16),
            if (config.usesE2ePasswordAuth) ...[
              E2eId(
                id: 'auth.password',
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ),
              const SizedBox(height: 16),
              E2eId(
                id: 'auth.password_sign_in',
                child: FilledButton(
                  onPressed: auth.isLoading ? null : _signInWithPassword,
                  child: auth.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in for E2E'),
                ),
              ),
            ] else
              E2eId(
                id: 'auth.magic_link',
                child: FilledButton(
                  onPressed: !config.hasSupabaseConfig || auth.isLoading
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(authControllerProvider.notifier)
                                .requestMagicLink(_emailController.text.trim());
                            if (!mounted) return;
                            setState(() {
                              _error = null;
                              _message = 'Check your email for a sign-in link.';
                            });
                          } catch (error) {
                            if (!mounted) return;
                            setState(() {
                              _message = null;
                              _error = error.toString();
                            });
                          }
                        },
                  child: auth.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send sign-in link'),
                ),
              ),
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

  Future<void> _signInWithPassword() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      setState(() {
        _error = null;
        _message = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = null;
        _error = error.toString();
      });
    }
  }
}
