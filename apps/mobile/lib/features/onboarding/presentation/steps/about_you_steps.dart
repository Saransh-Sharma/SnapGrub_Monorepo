import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_steps.dart';
import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart';
import 'package:snapgrub/features/onboarding/presentation/widgets/onboarding_chrome.dart';

// ---------------------------------------------------------------------------
// 3. Goal
// ---------------------------------------------------------------------------

enum _GoalShape { down, level, up, tune }

class GoalStep extends ConsumerWidget {
  const GoalStep({super.key});

  static const _goals = [
    ('lose', 'Lose weight', 'Steady, sustainable loss', _GoalShape.down),
    ('maintain', 'Maintain', 'Keep your current weight', _GoalShape.level),
    ('gain', 'Gain', 'Build muscle with a small surplus', _GoalShape.up),
    ('custom', 'Custom', 'Start at maintenance and adjust', _GoalShape.tune),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final name = draft.firstName;
    return OnboardingStepBody(
      eyebrow: name.isEmpty ? null : 'Nice to meet you, $name.',
      question: 'What’s your goal?',
      why: 'Sets your daily targets. Change it anytime.',
      children: [
        for (final (value, title, subtitle, shape) in _goals)
          OnboardingChoiceCard(
            id: 'onboarding.goal.$value',
            title: title,
            subtitle: subtitle,
            selected: draft.goalType == value,
            leading:
                _GoalGlyph(shape: shape, selected: draft.goalType == value),
            onTap: () => notifier.updateGoal(value),
          ),
      ],
    );
  }
}

class _GoalGlyph extends StatelessWidget {
  const _GoalGlyph({required this.shape, required this.selected});

  final _GoalShape shape;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final palette = switch (shape) {
      _GoalShape.down => tokens.energy,
      _GoalShape.level => tokens.fat,
      _GoalShape.up => tokens.protein,
      _GoalShape.tune => tokens.carbs,
    };
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusSm),
      ),
      child: CustomPaint(
        painter: _GoalGlyphPainter(shape: shape, color: palette.color),
      ),
    );
  }
}

class _GoalGlyphPainter extends CustomPainter {
  const _GoalGlyphPainter({required this.shape, required this.color});

  final _GoalShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = color;
    switch (shape) {
      case _GoalShape.down:
        final path = Path()
          ..moveTo(w * .18, h * .3)
          ..cubicTo(w * .4, h * .3, w * .5, h * .68, w * .82, h * .7);
        canvas.drawPath(path, stroke);
        canvas.drawCircle(Offset(w * .82, h * .7), 4, dot);
      case _GoalShape.level:
        final path = Path()..moveTo(w * .18, h * .5);
        for (var i = 1; i <= 16; i++) {
          final x = w * (.18 + .64 * i / 16);
          path.lineTo(x, h * .5 + math.sin(i / 16 * math.pi * 2) * h * .08);
        }
        canvas.drawPath(path, stroke);
        canvas.drawCircle(Offset(w * .82, h * .5), 4, dot);
      case _GoalShape.up:
        for (var i = 0; i < 3; i++) {
          final x = w * (.28 + i * .22);
          final top = h * (.62 - i * .14);
          canvas.drawLine(Offset(x, h * .74), Offset(x, top), stroke);
        }
        canvas.drawCircle(Offset(w * .72, h * .28), 4, dot);
      case _GoalShape.tune:
        for (var i = 0; i < 3; i++) {
          final y = h * (.32 + i * .18);
          canvas.drawLine(Offset(w * .2, y), Offset(w * .8, y),
              stroke..color = color.withValues(alpha: .45));
          canvas.drawCircle(
              Offset(w * (.35 + (i == 1 ? .3 : i * .1)), y), 4.5, dot);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _GoalGlyphPainter old) =>
      old.shape != shape || old.color != color;
}

// ---------------------------------------------------------------------------
// 4. Sex
// ---------------------------------------------------------------------------

class SexStep extends ConsumerWidget {
  const SexStep({super.key});

  static const _options = [
    (BiologicalSex.female, 'Female', Icons.female_rounded),
    (BiologicalSex.male, 'Male', Icons.male_rounded),
    (BiologicalSex.unspecified, 'Prefer not to say', Icons.more_horiz_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return OnboardingStepBody(
      question: 'Which sex should we use?',
      why: 'Used once for your estimate. Not stored.',
      children: [
        for (final (value, label, icon) in _options)
          OnboardingChoiceCard(
            id: 'onboarding.sex.${value.name}',
            title: label,
            selected: draft.sex == value,
            leading: Icon(icon, color: scheme.primary),
            onTap: () => notifier.updateSex(value),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Birth year
// ---------------------------------------------------------------------------

class BirthYearStep extends ConsumerWidget {
  const BirthYearStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final now = DateTime.now();
    final years = [
      for (var y = now.year - OnboardingDefaults.maxAge;
          y <= now.year - OnboardingDefaults.minAge;
          y++)
        y,
    ];
    final selected = OnboardingDefaults.birthYearOf(draft, now)
        .clamp(years.first, years.last);
    final age = now.year - selected;
    final theme = Theme.of(context);
    return OnboardingStepBody(
      question: 'What year were you born?',
      why: 'Fine-tunes your estimate. Not stored.',
      children: [
        E2eId(
          id: 'onboarding.birth_year',
          child: SgWheelPicker<int>(
            values: years,
            selected: selected,
            labelFor: (y) => '$y',
            semanticLabel: 'Birth year',
            onChanged: notifier.updateBirthYear,
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space12),
        Text(
          'About $age years old',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Height
// ---------------------------------------------------------------------------

class HeightStep extends ConsumerWidget {
  const HeightStep({super.key});

  static final _cm = [for (var v = 120; v <= 230; v++) v];
  static final _inches = [for (var v = 48; v <= 90; v++) v];

  static int _nearest(List<int> values, double target) =>
      values.reduce((a, b) => (a - target).abs() <= (b - target).abs() ? a : b);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final metric = draft.isMetric;
    final cm = OnboardingDefaults.height(draft);
    return OnboardingStepBody(
      question: 'How tall are you?',
      why: 'Used to estimate your energy needs.',
      children: [
        UnitToggle(
          metric: metric,
          metricLabel: 'cm',
          imperialLabel: 'ft / in',
          onChanged: (m) =>
              notifier.updateUnitSystem(m ? 'metric' : 'imperial'),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space16),
        E2eId(
          id: 'onboarding.height',
          child: metric
              ? SgWheelPicker<int>(
                  key: const ValueKey('height.metric'),
                  values: _cm,
                  selected: _nearest(_cm, cm),
                  labelFor: (v) => '$v cm',
                  semanticLabel: 'Height',
                  onChanged: (v) => notifier.updateHeightCm(v.toDouble()),
                )
              : SgWheelPicker<int>(
                  key: const ValueKey('height.imperial'),
                  values: _inches,
                  selected: _nearest(_inches, Units.cmToIn(cm)),
                  labelFor: (v) =>
                      Units.height(Units.inToCm(v.toDouble()), metric: false),
                  semanticLabel: 'Height',
                  onChanged: (v) =>
                      notifier.updateHeightCm(Units.inToCm(v.toDouble())),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Current weight & 8. Target weight
// ---------------------------------------------------------------------------

/// Ruler in the user's unit, bound to a canonical kg value.
class _WeightRuler extends StatelessWidget {
  const _WeightRuler({
    required this.kg,
    required this.metric,
    required this.onChanged,
    required this.semanticLabel,
  });

  final double kg;
  final bool metric;
  final ValueChanged<double> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final min = OnboardingDefaults.minWeightKg;
    final max = OnboardingDefaults.maxWeightKg;
    final clamped = kg.clamp(min, max).toDouble();
    final unit = metric ? 'kg' : 'lb';
    final shown = metric ? clamped : Units.kgToLb(clamped);
    // Screen-reader steps are coarser than the 0.1 ruler ticks.
    final a11yStep = metric ? .5 : 1.0;
    double toKg(double v) => metric ? v : Units.lbToKg(v);
    final canUp = clamped < max - 1e-6;
    final canDown = clamped > min + 1e-6;
    String label(double v) => '${v.toStringAsFixed(1)} $unit';
    void nudge(int direction) {
      final next = toKg(((shown / a11yStep).round() + direction) * a11yStep)
          .clamp(min, max)
          .toDouble();
      SgHaptics.tick();
      onChanged(next);
    }

    // The ruler's own semantics are replaced with a complete adjustable
    // node (value, increased / decreased value, actions).
    return Semantics(
      label: semanticLabel,
      value: label(shown),
      increasedValue: canUp ? label(shown + a11yStep) : null,
      decreasedValue: canDown ? label(shown - a11yStep) : null,
      onIncrease: canUp ? () => nudge(1) : null,
      onDecrease: canDown ? () => nudge(-1) : null,
      child: ExcludeSemantics(
        child: metric
            ? SgRulerPicker(
                key: const ValueKey('ruler.kg'),
                value: clamped,
                min: min,
                max: max,
                unit: 'kg',
                onChanged: onChanged,
              )
            : SgRulerPicker(
                key: const ValueKey('ruler.lb'),
                value: shown,
                min: Units.kgToLb(min).roundToDouble(),
                max: Units.kgToLb(max).roundToDouble(),
                unit: 'lb',
                onChanged: (lb) => onChanged(Units.lbToKg(lb)),
              ),
      ),
    );
  }
}

class WeightStep extends ConsumerWidget {
  const WeightStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    return OnboardingStepBody(
      question: 'What’s your current weight?',
      why: 'Your starting point. Only you see it.',
      children: [
        UnitToggle(
          metric: draft.isMetric,
          metricLabel: 'kg',
          imperialLabel: 'lb',
          onChanged: (m) =>
              notifier.updateUnitSystem(m ? 'metric' : 'imperial'),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space24),
        E2eId(
          id: 'onboarding.weight',
          child: _WeightRuler(
            kg: OnboardingDefaults.weight(draft),
            metric: draft.isMetric,
            semanticLabel: 'Current weight',
            onChanged: notifier.updateWeightKg,
          ),
        ),
      ],
    );
  }
}

class TargetWeightStep extends ConsumerWidget {
  const TargetWeightStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);
    final tokens = context.sg;
    final metric = draft.isMetric;
    final current = OnboardingDefaults.weight(draft);
    final target = OnboardingDefaults.target(draft);
    final delta = target - current;
    final shown = metric ? delta : Units.kgToLb(delta);
    final sign = shown < -.05 ? '−' : (shown > .05 ? '+' : '');
    final deltaText =
        '$sign${shown.abs().toStringAsFixed(1)} ${metric ? 'kg' : 'lb'}';
    final heightCm = OnboardingDefaults.height(draft);
    final low = OnboardingDefaults.healthyMinKg(heightCm);
    final high = 24.9 * math.pow(heightCm / 100, 2);
    return OnboardingStepBody(
      question: 'What’s your goal weight?',
      why: 'You can change it anytime.',
      children: [
        E2eId(
          id: 'onboarding.target_weight',
          child: _WeightRuler(
            kg: target,
            metric: metric,
            semanticLabel: 'Goal weight',
            onChanged: notifier.updateTargetWeightKg,
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space16),
        Center(
          child: Semantics(
            liveRegion: true,
            label: 'Change from today: $deltaText',
            excludeSemantics: true,
            child: AnimatedSwitcher(
              duration: SgMotion.of(context).press,
              child: Container(
                key: ValueKey(deltaText),
                padding: const EdgeInsets.symmetric(
                  horizontal: SnapGrubDesignTokens.space16,
                  vertical: SnapGrubDesignTokens.space8,
                ),
                decoration: BoxDecoration(
                  color: tokens.energy.soft,
                  borderRadius:
                      BorderRadius.circular(SnapGrubDesignTokens.radiusPill),
                ),
                child: Text(
                  deltaText,
                  style:
                      tokens.metricSmall.copyWith(color: tokens.energy.onSoft),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space16),
        Text(
          'Healthy range for your height: '
          '${(metric ? low : Units.kgToLb(low)).toStringAsFixed(1)}–'
          '${Units.weight(high, metric: metric)}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
