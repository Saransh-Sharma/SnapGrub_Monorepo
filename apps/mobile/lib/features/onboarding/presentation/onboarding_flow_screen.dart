import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/presentation/body_screen.dart';
import 'package:snapgrub/features/onboarding/presentation/cuisine_screen.dart';
import 'package:snapgrub/features/onboarding/presentation/goal_screen.dart';
import 'package:snapgrub/features/onboarding/presentation/macro_target_screen.dart';
import 'package:snapgrub/features/onboarding/presentation/permission_primer_screen.dart';
import 'package:snapgrub/features/onboarding/presentation/welcome_screen.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final _controller = PageController();
  int _index = 0;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final pages = [
      const OnboardingWelcomeScreen(),
      const OnboardingGoalScreen(),
      const OnboardingBodyScreen(),
      const OnboardingMacroTargetScreen(),
      const OnboardingCuisineScreen(),
      const OnboardingPermissionPrimerScreen(),
    ];

    return AppScaffold(
      title: 'Setup',
      child: E2eId(
        id: 'screen.onboarding',
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / pages.length),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _index = value),
                children: pages,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Row(
              children: [
                if (_index > 0)
                  Expanded(
                    child: E2eId(
                      id: 'onboarding.back',
                      child: OutlinedButton(
                        onPressed: () => _controller.previousPage(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  ),
                if (_index > 0) const SizedBox(width: 12),
                Expanded(
                  child: E2eId(
                    id: _index == pages.length - 1
                        ? 'onboarding.finish'
                        : 'onboarding.next',
                    child: FilledButton(
                      onPressed: profileState.isLoading
                          ? null
                          : () async {
                              if (_index < pages.length - 1) {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                );
                                return;
                              }
                              try {
                                draft.validate();
                                final auth = await ref
                                    .read(authControllerProvider.future);
                                final userId = auth.userId;
                                if (userId == null) {
                                  throw StateError('Sign in again.');
                                }
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .completeOnboarding(userId, draft);
                                if (context.mounted) context.go('/home');
                              } catch (error) {
                                setState(() => _error = error
                                    .toString()
                                    .replaceFirst('Invalid argument(s): ', ''));
                              }
                            },
                      child:
                          Text(_index == pages.length - 1 ? 'Finish' : 'Next'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
