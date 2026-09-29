import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';

final bool _underFlutterTest =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

/// Whether continuous idle motion (aurora drift, the looping welcome demo,
/// foil shimmer) may run.
///
/// Idle loops never settle, so besides the effects tier they are paused
/// under `flutter test`, where widget tests rely on `pumpAndSettle`.
bool ambientMotionOf(BuildContext context) =>
    SgEffectsScope.of(context).animates && !_underFlutterTest;

/// Freezes tickers below it unless ambient motion is allowed.
class AmbientTickerMode extends StatelessWidget {
  const AmbientTickerMode({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      TickerMode(enabled: ambientMotionOf(context), child: child);
}

/// Keeps a page's state (scroll position, text fields) while off screen.
class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({required this.child, this.keepAlive = true, super.key});

  final Widget child;
  final bool keepAlive;

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void didUpdateWidget(covariant KeepAlivePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keepAlive != widget.keepAlive) updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

/// Segmented progress: one segment per question, filling with a spring.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    required this.total,
    required this.current,
    super.key,
  });

  final int total;

  /// Zero-based index of the current question.
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Question ${current + 1} of $total',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: SnapGrubDesignTokens.space4),
            Expanded(
              child: _SpringSegment(
                filled: i <= current,
                track: scheme.onSurface.withValues(alpha: .1),
                fill: scheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpringSegment extends StatefulWidget {
  const _SpringSegment({
    required this.filled,
    required this.track,
    required this.fill,
  });

  final bool filled;
  final Color track;
  final Color fill;

  @override
  State<_SpringSegment> createState() => _SpringSegmentState();
}

class _SpringSegmentState extends State<_SpringSegment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _value = AnimationController.unbounded(
    vsync: this,
    value: widget.filled ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant _SpringSegment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filled == widget.filled) return;
    final target = widget.filled ? 1.0 : 0.0;
    if (SgMotion.of(context).reduced) {
      _value.value = target;
      return;
    }
    _value.animateWith(SpringSimulation(
      SgSprings.snappy,
      _value.value,
      target,
      _value.velocity,
    ));
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.track,
          borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusPill),
        ),
        child: AnimatedBuilder(
          animation: _value,
          builder: (context, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _value.value.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.fill,
                borderRadius:
                    BorderRadius.circular(SnapGrubDesignTokens.radiusPill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step layout
// ---------------------------------------------------------------------------

/// A single question: optional eyebrow, a large serif question, an optional
/// "why we ask" line, then the step's controls. Scrolls at large text sizes;
/// the sticky Continue button lives in the flow shell.
class OnboardingStepBody extends StatelessWidget {
  const OnboardingStepBody({
    required this.question,
    required this.children,
    this.eyebrow,
    this.why,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    super.key,
  });

  final String question;
  final String? eyebrow;
  final String? why;
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space16,
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space24,
      ),
      child: OnboardingEntrance(
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            if (eyebrow != null) ...[
              Text(eyebrow!,
                  style: tokens.editorial.copyWith(
                    color: theme.colorScheme.primary,
                  )),
              const SizedBox(height: SnapGrubDesignTokens.space8),
            ],
            Semantics(
              header: true,
              child: Text(question, style: theme.textTheme.headlineLarge),
            ),
            if (why != null) ...[
              const SizedBox(height: SnapGrubDesignTokens.space12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: SnapGrubDesignTokens.iconSm,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: SnapGrubDesignTokens.space8),
                  Expanded(
                    child: Text(
                      why!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: SnapGrubDesignTokens.space24),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// One-shot fade + lift used when a step first appears. Timer-free, so it is
/// safe under `pumpAndSettle`.
class OnboardingEntrance extends StatefulWidget {
  const OnboardingEntrance({
    required this.child,
    this.delay = 0,
    this.offset = 18,
    super.key,
  });

  final Widget child;

  /// 0..1 fraction of the entrance spent waiting (for simple staggers).
  final double delay;
  final double offset;

  @override
  State<OnboardingEntrance> createState() => _OnboardingEntranceState();
}

class _OnboardingEntranceState extends State<OnboardingEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(widget.delay.clamp(0, .9), 1, curve: Curves.easeOutCubic),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (SgMotion.of(context).reduced) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Choice card
// ---------------------------------------------------------------------------

/// A large selectable card (goal, sex, activity). Tilts toward the finger and
/// scales on press; announces its selected state.
class OnboardingChoiceCard extends StatelessWidget {
  const OnboardingChoiceCard({
    required this.id,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.inGroup = true,
    super.key,
  });

  final String id;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;
  final bool inGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.sg;
    final motion = SgMotion.of(context);
    final label = subtitle == null ? title : '$title. $subtitle';
    return Padding(
      padding: const EdgeInsets.only(bottom: SnapGrubDesignTokens.space12),
      child: E2eId(
        id: id,
        child: Semantics(
          selected: selected,
          inMutuallyExclusiveGroup: inGroup,
          child: TiltOnPress(
            child: PremiumPressable(
              onTap: onTap,
              semanticLabel: label,
              child: AnimatedContainer(
                duration: motion.settle,
                curve: motion.standard,
                padding: const EdgeInsets.all(SnapGrubDesignTokens.space16),
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerLowest.withValues(alpha: .86),
                  borderRadius:
                      BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : tokens.outlineStrong.withValues(alpha: .45),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected ? tokens.elevation1 : null,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: SnapGrubDesignTokens.space16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleMedium),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: SnapGrubDesignTokens.space8),
                    AnimatedScale(
                      scale: selected ? 1 : .6,
                      duration: motion.settle,
                      curve: selected ? Curves.elasticOut : motion.standard,
                      child: AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: motion.press,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tilts [child] a few degrees toward where it's pressed.
class TiltOnPress extends StatefulWidget {
  const TiltOnPress({required this.child, this.maxAngle = .07, super.key});

  final Widget child;
  final double maxAngle;

  @override
  State<TiltOnPress> createState() => _TiltOnPressState();
}

class _TiltOnPressState extends State<TiltOnPress> {
  Offset _tilt = Offset.zero;

  void _down(PointerDownEvent event) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || SgMotion.of(context).reduced) return;
    final size = box.size;
    final local = event.localPosition;
    setState(() {
      _tilt = Offset(
        ((local.dx / size.width) - .5) * 2,
        ((local.dy / size.height) - .5) * 2,
      );
    });
  }

  void _up([PointerEvent? _]) {
    if (_tilt != Offset.zero) setState(() => _tilt = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final motion = SgMotion.of(context);
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _tilt),
        duration: _tilt == Offset.zero ? motion.settle : motion.press,
        curve: _tilt == Offset.zero ? Curves.elasticOut : motion.standard,
        child: widget.child,
        builder: (context, tilt, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0011)
            ..rotateX(-tilt.dy * widget.maxAngle)
            ..rotateY(tilt.dx * widget.maxAngle),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chips & toggles
// ---------------------------------------------------------------------------

/// A multi-select chip that pops with a spring when selected.
class PopChip extends StatelessWidget {
  const PopChip({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.enabled = true,
    super.key,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = SgMotion.of(context);
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return E2eId(
      id: id,
      child: Semantics(
        selected: selected,
        enabled: enabled,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: enabled ? _tap : null,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(selected),
          tween: Tween(begin: selected && !motion.reduced ? .82 : 1, end: 1),
          duration: motion.of(const Duration(milliseconds: 520)),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Opacity(
            opacity: enabled ? 1 : .45,
            child: Material(
              color: selected
                  ? scheme.primary
                  : scheme.surfaceContainerLowest.withValues(alpha: .86),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(SnapGrubDesignTokens.radiusPill),
                side: BorderSide(
                  color: selected
                      ? scheme.primary
                      : context.sg.outlineStrong.withValues(alpha: .5),
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: enabled ? _tap : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SnapGrubDesignTokens.space16,
                      vertical: SnapGrubDesignTokens.space8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected || icon != null) ...[
                          Icon(
                            selected ? Icons.check_rounded : icon,
                            size: SnapGrubDesignTokens.iconSm,
                            color: fg,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style:
                                theme.textTheme.labelLarge?.copyWith(color: fg),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _tap() {
    SgHaptics.tap();
    onTap();
  }
}

/// Metric / imperial switch. Converting is free because the draft stores
/// canonical units; the pickers simply re-render in the new unit.
class UnitToggle extends StatelessWidget {
  const UnitToggle({
    required this.metric,
    required this.onChanged,
    this.metricLabel = 'Metric',
    this.imperialLabel = 'Imperial',
    super.key,
  });

  final bool metric;
  final ValueChanged<bool> onChanged;
  final String metricLabel;
  final String imperialLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: true,
            label:
                E2eId(id: 'onboarding.unit.metric', child: Text(metricLabel)),
          ),
          ButtonSegment(
            value: false,
            label: E2eId(
                id: 'onboarding.unit.imperial', child: Text(imperialLabel)),
          ),
        ],
        selected: {metric},
        onSelectionChanged: (value) {
          SgHaptics.tick();
          onChanged(value.single);
        },
      ),
    );
  }
}
