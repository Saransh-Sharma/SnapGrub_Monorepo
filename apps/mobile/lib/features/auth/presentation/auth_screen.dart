import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final auth = ref.watch(authControllerProvider);

    return AppScaffold(
      title: 'SnapGrub',
      child: ListView(
        children: [
          Text(
            'Sign in to start tracking meals.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (!config.hasSupabaseConfig)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Supabase is not configured. Launch with SUPABASE_URL and SUPABASE_ANON_KEY dart defines.',
                ),
              ),
            ),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: !config.hasSupabaseConfig || auth.isLoading
                ? null
                : () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .requestMagicLink(_emailController.text.trim());
                    setState(() =>
                        _message = 'Check your email for a sign-in link.');
                  },
            child: auth.isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send sign-in link'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}
