import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';

/// "Building your plan": four checklist lines tick in one at a time while
/// the macro rings assemble and the calorie target counts up. About 2.5 s;
/// well under a second with Reduce Motion. Calls [onDone] when finished.
class BuildingPlanStep extends ConsumerStatefulWidget {
  const BuildingPlanStep({
    required this.active,
    required this.onDone,
    super.key,
  });

  final bool active;
  final VoidCallback onDone;

  static const fullDuration = Duration(milliseconds: 2600);
  static const reducedDuration = Duration(milliseconds: 700);

  @override
  ConsumerState<BuildingPlanStep> createState() => _BuildingPlanStepState();
}

class _BuildingPlanStepState extends ConsumerState<BuildingPlanStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(vsync: this)
    ..addListener(_onTick)
    ..addStatusListener(_onStatus);
  int _stage = 0;
  bool _startedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_startedOnce && widget.active) _start();
  }

  @override
  void didUpdateWidget(covariant BuildingPlanStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _start();
    if (!widget.active && oldWidget.active) _run.stop();
  }

  void _start() {
    _startedOnce = true;
    final reduced = SgMotion.of(context).reduced;
    _run.duration = reduced
        ? BuildingPlanStep.reducedDuration
        : BuildingPlanStep.fullDuration;
    _stage = reduced ? 4 : 0;
    _run.forward(from: 0);
  }

  void _onTick() {
    // Lines tick at roughly 18%, 38%, 58% and 78% of the run.
    final stage = math.min(4, ((_run.value + .02) / .2).floor());
    if (stage > _stage) {
      SgHaptics.tick();
      setState(() => _stage = stage);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.active) widget.onDone();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);
    final theme = Theme.of(context);
    final tokens = context.sg;
    final name = draft.firstName;
    final lines = [
      'Estimating your energy needs…',
      'Setting your protein…',
      draft.needsTargetWeight
          ? 'Setting your pace…'
          : 'Finding your maintenance…',
      'Finalizing your targets…',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space16,
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              name.isEmpty
                  ? 'Building your plan…'
                  : 'Building your plan, $name…',
              style: theme.textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: SnapGrubDesignTokens.space32),
          Center(
            child: SizedBox.square(
              dimension: 184,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final (i, macro, size) in const [
                    (0, Macro.protein, 184.0),
                    (1, Macro.carbs, 146.0),
                    (2, Macro.fat, 108.0),
                  ])
                    ExcludeSemantics(
                      child: SgRing(
                        progress: _stage > i ? 1 : 0,
                        color: tokens.macro(macro).color,
                        trackColor:
                            tokens.macro(macro).color.withValues(alpha: .14),
                        size: size,
                        thickness: 10,
                      ),
                    ),
                  ExcludeSemantics(
                    child: AnimatedBuilder(
                      animation: _run,
                      builder: (context, _) {
                        final t = Curves.easeOutCubic.transform(_run.value);
                        final value = (draft.caloriesKcal * t).round();
                        return SizedBox(
                          width: 84,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                child: Text(
                                  NumberFormat.decimalPattern().format(value),
                                  style: tokens.metric,
                                ),
                              ),
                              FittedBox(
                                child: Text(
                                  'kcal',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: SnapGrubDesignTokens.space32),
          for (var i = 0; i < lines.length; i++)
            _ChecklistLine(
              text: lines[i],
              done: _stage > i,
              visible: _stage >= i,
            ),
        ],
      ),
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({
    required this.text,
    required this.done,
    required this.visible,
  });

  final String text;
  final bool done;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = SgMotion.of(context);
    return Semantics(
      label: done ? '$text Done.' : text,
      excludeSemantics: true,
      child: AnimatedOpacity(
        opacity: visible ? (done ? 1 : .6) : .25,
        duration: motion.settle,
        child: Padding(
          padding: const EdgeInsets.only(bottom: SnapGrubDesignTokens.space12),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: motion.settle,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                      parent: animation, curve: Curves.elasticOut),
                  child: child,
                ),
                child: Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(done),
                  color: done ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: SnapGrubDesignTokens.space12),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}
