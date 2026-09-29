import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_completion.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_steps.dart';
import 'package:snapgrub/features/onboarding/presentation/steps/about_you_steps.dart';
import 'package:snapgrub/features/onboarding/presentation/steps/building_step.dart';
import 'package:snapgrub/features/onboarding/presentation/steps/intro_steps.dart';
import 'package:snapgrub/features/onboarding/presentation/steps/plan_reveal_step.dart';
import 'package:snapgrub/features/onboarding/presentation/steps/plan_steps.dart';
import 'package:snapgrub/features/onboarding/presentation/widgets/onboarding_chrome.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

/// One question per screen on a slow aurora, ending in the plan reveal.
///
/// Values live in [onboardingControllerProvider], so pages keep their state
/// when you go back; the system back gesture steps back through the flow.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final _pages = PageController();
  int _index = 0;

  /// Validation message for [_errorStep], shown until the step becomes valid.
  String? _stepError;
  OnboardingStep? _errorStep;

  /// Save failure on the final step.
  String? _saveError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(onboardingControllerProvider.notifier).detectRegion();
      }
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<OnboardingStep> get _steps =>
      onboardingStepsFor(ref.read(onboardingControllerProvider));

  void _goTo(int index) {
    final steps = _steps;
    final target = index.clamp(0, steps.length - 1);
    setState(() {
      _index = target;
      _stepError = null;
      _errorStep = null;
      _saveError = null;
    });
    if (!_pages.hasClients) return;
    final motion = SgMotion.of(context);
    if (motion.reduced) {
      _pages.jumpToPage(target);
    } else {
      _pages.animateToPage(
        target,
        duration: motion.page,
        curve: motion.emphasized,
      );
    }
  }

  void _next() {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final draft = ref.read(onboardingControllerProvider);
    final steps = onboardingStepsFor(draft);
    final step = steps[_index];
    final error = validateOnboardingStep(step, draft);
    if (error != null) {
      SgHaptics.warn();
      setState(() {
        _stepError = error;
        _errorStep = step;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    SgHaptics.tap();
    notifier.commitStep(step);
    final nextSteps = _steps;
    final nextIndex = nextSteps.indexOf(step) + 1;
    if (nextIndex >= nextSteps.length) return;
    if (nextSteps[nextIndex] == OnboardingStep.building) notifier.applyPlan();
    _goTo(nextIndex);
  }

  void _back() {
    if (_index == 0 || _saving) return;
    final steps = _steps;
    var target = _index - 1;
    if (steps[target] == OnboardingStep.building) target--;
    FocusScope.of(context).unfocus();
    _goTo(target);
  }

  void _onBuilt() {
    final steps = _steps;
    if (!mounted || steps[_index] != OnboardingStep.building) return;
    _goTo(_index + 1);
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final draft =
          ref.read(onboardingControllerProvider.notifier).finalDraft();
      draft.validate();
      final auth = await ref.read(authControllerProvider.future);
      final userId = auth.userId;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _saveError = 'Your session expired. Sign in again to save your plan.';
        });
        return;
      }
      await OnboardingHandoff.save(userId, draft);
      if (!mounted) return;
      await ref
          .read(profileControllerProvider.notifier)
          .completeOnboarding(userId, draft);
      SgHaptics.logged();
      if (mounted) context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = friendlyError(error).message;
      });
    }
  }

  Widget _stepWidget(OnboardingStep step, bool active) => switch (step) {
        OnboardingStep.welcome => const WelcomeStep(),
        OnboardingStep.name => NameStep(active: active, onSubmit: _next),
        OnboardingStep.goal => const GoalStep(),
        OnboardingStep.sex => const SexStep(),
        OnboardingStep.birthYear => const BirthYearStep(),
        OnboardingStep.height => const HeightStep(),
        OnboardingStep.weight => const WeightStep(),
        OnboardingStep.targetWeight => const TargetWeightStep(),
        OnboardingStep.activity => const ActivityStep(),
        OnboardingStep.pace => const PaceStep(),
        OnboardingStep.cuisines => const CuisinesStep(),
        OnboardingStep.reminders => const RemindersStep(),
        OnboardingStep.building =>
          BuildingPlanStep(active: active, onDone: _onBuilt),
        OnboardingStep.reveal => PlanRevealStep(active: active),
      };

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);
    final steps = onboardingStepsFor(draft);
    if (_index >= steps.length) _index = steps.length - 1;
    final step = steps[_index];
    final questions = steps.where((s) => s.isQuestion).toList();
    final scheme = Theme.of(context).colorScheme;

    final liveError =
        _errorStep == step && validateOnboardingStep(step, draft) != null
            ? _stepError
            : null;
    final error = _saveError ?? liveError;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: E2eId(
        id: 'screen.onboarding',
        child: Scaffold(
          backgroundColor: scheme.surface,
          body: Stack(
            children: [
              const Positioned.fill(
                child: AmbientTickerMode(child: MeshAurora()),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _Header(
                      showBack: _index > 0 &&
                          step != OnboardingStep.building &&
                          !_saving,
                      onBack: _back,
                      progressTotal: questions.length,
                      progressIndex:
                          step.isQuestion ? questions.indexOf(step) : null,
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pages,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: steps.length,
                        findChildIndexCallback: (key) {
                          final value = (key as ValueKey<OnboardingStep>).value;
                          final i = steps.indexOf(value);
                          return i < 0 ? null : i;
                        },
                        itemBuilder: (context, i) {
                          final s = steps[i];
                          return KeepAlivePage(
                            key: ValueKey(s),
                            keepAlive: s != OnboardingStep.building,
                            child: E2eId(
                              id: 'onboarding.step.${s.id}',
                              child: _stepWidget(s, i == _index),
                            ),
                          );
                        },
                      ),
                    ),
                    _BottomBar(
                      step: step,
                      valid: validateOnboardingStep(step, draft) == null,
                      error: error,
                      saving: _saving,
                      onContinue: _next,
                      onFinish: _finish,
                      onAdjust: () => showAdjustTargetsSheet(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.showBack,
    required this.onBack,
    required this.progressTotal,
    required this.progressIndex,
  });

  final bool showBack;
  final VoidCallback onBack;
  final int progressTotal;
  final int? progressIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SnapGrubDesignTokens.space8,
        SnapGrubDesignTokens.space4,
        SnapGrubDesignTokens.space24,
        0,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: showBack
                  ? E2eId(
                      id: 'onboarding.back',
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () {
                          SgHaptics.tap();
                          onBack();
                        },
                        icon: const Icon(Icons.chevron_left_rounded, size: 30),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: SnapGrubDesignTokens.space8),
            Expanded(
              child: AnimatedOpacity(
                opacity: progressIndex == null ? 0 : 1,
                duration: SgMotion.of(context).settle,
                child: progressIndex == null
                    ? const SizedBox.shrink()
                    : OnboardingProgressBar(
                        total: progressTotal,
                        current: progressIndex!,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.valid,
    required this.error,
    required this.saving,
    required this.onContinue,
    required this.onFinish,
    required this.onAdjust,
  });

  final OnboardingStep step;
  final bool valid;
  final String? error;
  final bool saving;
  final VoidCallback onContinue;
  final VoidCallback onFinish;
  final VoidCallback onAdjust;

  String get _label => switch (step) {
        OnboardingStep.welcome => 'Get started',
        OnboardingStep.reminders => 'Build my plan',
        _ => 'Continue',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motion = SgMotion.of(context);
    if (step == OnboardingStep.building) {
      return const SizedBox(height: SnapGrubDesignTokens.space24);
    }

    final List<Widget> actions;
    if (step == OnboardingStep.reveal) {
      actions = [
        E2eId(
          id: 'onboarding.finish',
          child: FilledButton(
            onPressed: saving ? null : onFinish,
            child: Text(saving ? 'Saving…' : 'Start logging'),
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space4),
        E2eId(
          id: 'onboarding.adjust_targets',
          child: TextButton(
            onPressed: saving ? null : onAdjust,
            child: const Text('Adjust targets'),
          ),
        ),
      ];
    } else {
      // Looks disabled until the step is valid, but stays tappable so a tap
      // explains what's missing instead of doing nothing.
      actions = [
        E2eId(
          id: 'onboarding.continue',
          child: E2eId(
            id: 'onboarding.next',
            child: Semantics(
              hint: valid ? null : 'Answer to continue',
              child: FilledButton(
                style: valid
                    ? null
                    : FilledButton.styleFrom(
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: .12),
                        foregroundColor: scheme.onSurface.withValues(alpha: .5),
                        elevation: 0,
                      ),
                onPressed: onContinue,
                child: Text(_label),
              ),
            ),
          ),
        ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space8,
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: motion.settle,
            curve: motion.standard,
            alignment: Alignment.bottomCenter,
            child: error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(
                        bottom: SnapGrubDesignTokens.space12),
                    child: E2eId(
                      id: 'onboarding.error',
                      child: InlineError(message: error!),
                    ),
                  ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
