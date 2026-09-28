import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart';
import 'package:snapgrub/features/onboarding/presentation/widgets/onboarding_chrome.dart';

/// The signature moment: a holographic plan card springs up with the daily
/// target, a macro donut and the goal date, followed by a projection curve
/// that draws itself from today to the goal.
class PlanRevealStep extends ConsumerStatefulWidget {
  const PlanRevealStep({required this.active, super.key});

  final bool active;

  @override
  ConsumerState<PlanRevealStep> createState() => _PlanRevealStepState();
}

class _PlanRevealStepState extends ConsumerState<PlanRevealStep>
    with TickerProviderStateMixin {
  late final AnimationController _card =
      AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final Animation<double> _drawCurve = CurvedAnimation(
    parent: _draw,
    curve: const Interval(.25, 1, curve: Curves.easeInOutCubic),
  );
  bool _played = false;
  bool _numbersIn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_played && widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant PlanRevealStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
  }

  void _play() {
    _played = true;
    final reduced = SgMotion.of(context).reduced;
    if (reduced) {
      _card.value = 1;
      _draw.value = 1;
      _numbersIn = true;
    } else {
      _numbersIn = false;
      _card.value = 0;
      _card.animateWith(SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 220, damping: 17),
        0,
        1,
        0,
      ));
      _draw.forward(from: 0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active) return;
      if (!_numbersIn) setState(() => _numbersIn = true);
      Celebration.play(context, key: 'plan_reveal', onceEver: true);
    });
  }

  @override
  void dispose() {
    _card.dispose();
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);
    final theme = Theme.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final input = draft.planInput(now: today);
    final plan =
        input == null ? null : PlanCalculator.calculate(input, today: today);
    final projection = input == null || plan == null
        ? const <double>[]
        : PlanCalculator.projection(input, plan);
    final name = draft.firstName;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space8,
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name.isEmpty ? 'Here’s your plan.' : 'Here’s your plan, $name.',
            style:
                context.sg.editorial.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: SnapGrubDesignTokens.space4),
          Semantics(
            header: true,
            child: Text('Ready when you are',
                style: theme.textTheme.headlineMedium),
          ),
          const SizedBox(height: SnapGrubDesignTokens.space20),
          AnimatedBuilder(
            animation: _card,
            builder: (context, child) {
              final v = _card.value;
              return Opacity(
                opacity: v.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 140 * (1 - v)),
                  child: Transform.scale(
                    scale: .92 + .08 * v.clamp(0.0, 1.2),
                    child: child,
                  ),
                ),
              );
            },
            child: E2eId(
              id: 'onboarding.plan_card',
              child: _PlanCard(
                draft: draft,
                plan: plan,
                showNumbers: _numbersIn,
                sweep: _drawCurve,
              ),
            ),
          ),
          const SizedBox(height: SnapGrubDesignTokens.space16),
          _ProjectionCard(
            draft: draft,
            plan: plan,
            points: projection,
            progress: _drawCurve,
            today: today,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan card
// ---------------------------------------------------------------------------

String _goalLine(OnboardingDraft draft, NutritionPlan? plan) {
  final metric = draft.isMetric;
  final target = draft.targetWeightKg;
  final date = plan?.goalDate;
  if (draft.needsTargetWeight && target != null && date != null) {
    return '${Units.weight(target, metric: metric)} by '
        '${DateFormat.yMMMd().format(date)}';
  }
  if (draft.goalType == 'custom') {
    return 'Your starting point. Adjust anytime.';
  }
  final weight = draft.weightKg;
  return weight == null
      ? 'Maintain your weight'
      : 'Maintain around ${Units.weight(weight, metric: metric)}';
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.draft,
    required this.plan,
    required this.showNumbers,
    required this.sweep,
  });

  final OnboardingDraft draft;
  final NutritionPlan? plan;
  final bool showNumbers;
  final Animation<double> sweep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    const title = 'Daily plan';
    final calories = draft.caloriesKcal.round();
    final weekly = plan?.weeklyChangeKg ?? 0;
    final weeklyText = weekly == 0
        ? null
        : '${weekly < 0 ? '−' : '+'}'
            '${NumberFormat('0.0#').format(draft.isMetric ? weekly.abs() : Units.kgToLb(weekly.abs()))} '
            '${draft.isMetric ? 'kg' : 'lb'} a week';
    final goalLine = _goalLine(draft, plan);
    final muted = tokens.onHeroMuted;
    final summary = '$title. ${NumberFormat.decimalPattern().format(calories)} '
        'calories a day. Protein ${draft.proteinG.round()} grams, carbs '
        '${draft.carbsG.round()} grams, fat ${draft.fatG.round()} grams. '
        '${goalLine.endsWith('.') ? goalLine : '$goalLine.'}'
        '${draft.targetsAdjusted ? ' Adjusted by you.' : ''}';

    return Semantics(
      container: true,
      label: summary,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusLg),
          boxShadow: tokens.elevation3,
        ),
        child: AmbientTickerMode(
          child: HoloFoil(
            borderRadius: SnapGrubDesignTokens.radiusLg,
            intensity: .9,
            child: SgCard(
              variant: SgCardVariant.hero,
              radius: SnapGrubDesignTokens.radiusLg,
              padding: const EdgeInsets.all(SnapGrubDesignTokens.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (draft.targetsAdjusted)
                        Text('Adjusted',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: muted)),
                      const SizedBox(width: SnapGrubDesignTokens.space8),
                      Icon(Icons.auto_awesome_rounded,
                          size: SnapGrubDesignTokens.iconMd,
                          color: tokens.carbs.color),
                    ],
                  ),
                  const SizedBox(height: SnapGrubDesignTokens.space16),
                  Text('Daily target',
                      style:
                          theme.textTheme.bodyMedium?.copyWith(color: muted)),
                  const SizedBox(height: SnapGrubDesignTokens.space4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        RollingNumber(
                          value: showNumbers ? calories : 0,
                          style:
                              tokens.heroNumber.copyWith(color: tokens.onHero),
                        ),
                        const SizedBox(width: SnapGrubDesignTokens.space8),
                        Text('kcal',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: SnapGrubDesignTokens.space20),
                  LayoutBuilder(builder: (context, constraints) {
                    final donut = SizedBox.square(
                      dimension: 104,
                      child: AnimatedBuilder(
                        animation: sweep,
                        builder: (context, _) => CustomPaint(
                          painter: _MacroDonutPainter(
                            proteinKcal: draft.proteinG * 4,
                            carbsKcal: draft.carbsG * 4,
                            fatKcal: draft.fatG * 9,
                            protein: tokens.protein.color,
                            carbs: tokens.carbs.color,
                            fat: tokens.fat.color,
                            track: tokens.onHero.withValues(alpha: .1),
                            t: sweep.value,
                          ),
                        ),
                      ),
                    );
                    final rows = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MacroRow(macro: Macro.protein, grams: draft.proteinG),
                        _MacroRow(macro: Macro.carbs, grams: draft.carbsG),
                        _MacroRow(macro: Macro.fat, grams: draft.fatG),
                      ],
                    );
                    // Side by side when the legend fits; stacked for large
                    // text or narrow phones.
                    final legendWidth = constraints.maxWidth - 104 - 20;
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    if (legendWidth >= 150 * scale) {
                      return Row(children: [
                        donut,
                        const SizedBox(width: SnapGrubDesignTokens.space20),
                        Expanded(child: rows),
                      ]);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: donut),
                        const SizedBox(height: SnapGrubDesignTokens.space16),
                        rows,
                      ],
                    );
                  }),
                  const SizedBox(height: SnapGrubDesignTokens.space20),
                  Divider(
                      color: tokens.onHero.withValues(alpha: .14), height: 1),
                  const SizedBox(height: SnapGrubDesignTokens.space16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.flag_rounded,
                          size: SnapGrubDesignTokens.iconMd,
                          color: tokens.energy.soft),
                      const SizedBox(width: SnapGrubDesignTokens.space8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goalLine,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(color: tokens.onHero)),
                            if (weeklyText != null)
                              Text(weeklyText,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.macro, required this.grams});

  final Macro macro;
  final double grams;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: tokens.macro(macro).color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SnapGrubDesignTokens.space8),
          Expanded(
            child: Text(macroLabel(macro),
                overflow: TextOverflow.ellipsis,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: tokens.onHero)),
          ),
          Text('${grams.round()} g',
              style: tokens.metricSmall.copyWith(color: tokens.onHero)),
        ],
      ),
    );
  }
}

class _MacroDonutPainter extends CustomPainter {
  const _MacroDonutPainter({
    required this.proteinKcal,
    required this.carbsKcal,
    required this.fatKcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.track,
    required this.t,
  });

  final double proteinKcal;
  final double carbsKcal;
  final double fatKcal;
  final Color protein;
  final Color carbs;
  final Color fat;
  final Color track;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final total = proteinKcal + carbsKcal + fatKcal;
    if (total <= 0 || t <= 0) return;
    const gap = .07;
    var start = -math.pi / 2;
    final sweepTotal = math.pi * 2 * t.clamp(0.0, 1.0);
    for (final (kcal, color) in [
      (proteinKcal, protein),
      (carbsKcal, carbs),
      (fatKcal, fat),
    ]) {
      final share = kcal / total * math.pi * 2;
      final end = math.min(start + share, -math.pi / 2 + sweepTotal);
      final sweep = end - start - gap;
      if (sweep > 0) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      }
      start += share;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter old) =>
      old.t != t ||
      old.proteinKcal != proteinKcal ||
      old.carbsKcal != carbsKcal ||
      old.fatKcal != fatKcal ||
      old.protein != protein;
}

// ---------------------------------------------------------------------------
// Projection
// ---------------------------------------------------------------------------

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({
    required this.draft,
    required this.plan,
    required this.points,
    required this.progress,
    required this.today,
  });

  final OnboardingDraft draft;
  final NutritionPlan? plan;
  final List<double> points;
  final Animation<double> progress;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.sg;
    final metric = draft.isMetric;
    final goalDate = plan?.goalDate;
    final weeks = plan?.weeksToGoal;
    final shown = [
      for (final kg in points) metric ? kg : Units.kgToLb(kg),
    ];
    final unit = metric ? 'kg' : 'lb';
    final endLabel =
        goalDate == null ? 'Weeks ahead' : DateFormat.MMMd().format(goalDate);
    final description = shown.length < 2
        ? 'No projection yet.'
        : goalDate == null
            ? 'Projection: holding steady around '
                '${shown.first.toStringAsFixed(1)} $unit.'
            : 'Projection: from ${shown.first.toStringAsFixed(1)} $unit today '
                'to ${shown.last.toStringAsFixed(1)} $unit by $endLabel, '
                'about ${Labels.count(weeks ?? 0, 'week')}.';
    return SgCard(
      semanticLabel: description,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your projection', style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              weeks == null
                  ? 'Maintaining'
                  : 'About ${Labels.count(weeks, 'week')} at your pace.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space16),
            SizedBox(
              height: 140,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) => CustomPaint(
                  painter: _ProjectionPainter(
                    values: shown,
                    t: progress.value,
                    line: tokens.energy.color,
                    fill: tokens.energy.color,
                    grid: scheme.outlineVariant,
                    dot: tokens.protein.color,
                    labelStyle: theme.textTheme.labelSmall!
                        .copyWith(color: scheme.onSurfaceVariant),
                    unit: unit,
                  ),
                ),
              ),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space8),
            Row(
              children: [
                Expanded(
                  child: Text('Today',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
                Text(endLabel,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            Text(
              'An estimate. Real progress has ups and downs.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionPainter extends CustomPainter {
  const _ProjectionPainter({
    required this.values,
    required this.t,
    required this.line,
    required this.fill,
    required this.grid,
    required this.dot,
    required this.labelStyle,
    required this.unit,
  });

  final List<double> values;
  final double t;
  final Color line;
  final Color fill;
  final Color grid;
  final Color dot;
  final TextStyle labelStyle;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = math.max(hi - lo, 1.0);
    const top = 22.0;
    const bottom = 18.0;
    final h = size.height - top - bottom;
    Offset at(int i) {
      final x = size.width * i / (values.length - 1);
      final y = hi == lo ? top + h / 2 : top + (hi - values[i]) / span * h;
      return Offset(x, y);
    }

    final gridPaint = Paint()
      ..color = grid.withValues(alpha: .6)
      ..strokeWidth = 1;
    for (final y in [top, top + h / 2, top + h]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p0 = at(i - 1);
      final p1 = at(i);
      final mid = (p0.dx + p1.dx) / 2;
      path.cubicTo(mid, p0.dy, mid, p1.dy, p1.dx, p1.dy);
    }
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * t.clamp(0.0, 1.0));
    final tangent =
        metric.getTangentForOffset(metric.length * t.clamp(0.0, 1.0));

    if (t > 0) {
      final head = tangent?.position ?? at(0);
      final area = Path.from(drawn)
        ..lineTo(head.dx, size.height - bottom)
        ..lineTo(0, size.height - bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, top),
            Offset(0, size.height - bottom),
            [fill.withValues(alpha: .22 * t), fill.withValues(alpha: 0)],
          ),
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final start = at(0);
    canvas.drawCircle(start, 4.5, Paint()..color = line);
    _label(canvas, '${values.first.toStringAsFixed(1)} $unit',
        start + const Offset(4, -18), size);
    if (t >= .999) {
      final end = at(values.length - 1);
      canvas.drawCircle(end, 7, Paint()..color = dot.withValues(alpha: .25));
      canvas.drawCircle(end, 4.5, Paint()..color = dot);
      if (hi != lo) {
        _label(canvas, '${values.last.toStringAsFixed(1)} $unit',
            end + const Offset(-4, 8), size,
            alignRight: true);
      }
    } else if (tangent != null && t > 0) {
      canvas.drawCircle(tangent.position, 4, Paint()..color = line);
    }
  }

  void _label(Canvas canvas, String text, Offset at, Size size,
      {bool alignRight = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: size.width / 2);
    var dx = alignRight ? at.dx - painter.width : at.dx;
    dx = dx.clamp(0, math.max(0.0, size.width - painter.width)).toDouble();
    final dy = at.dy.clamp(0, math.max(0.0, size.height - painter.height));
    painter.paint(canvas, Offset(dx, dy.toDouble()));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter old) =>
      old.t != t || old.values != values || old.line != line;
}

// ---------------------------------------------------------------------------
// Adjust targets sheet
// ---------------------------------------------------------------------------

Future<void> showAdjustTargetsSheet(BuildContext context) {
  return showSgSheet<void>(
    context: context,
    title: 'Adjust targets',
    subtitle: 'Change these anytime.',
    builder: (context) => const _AdjustTargetsForm(),
  );
}

class _AdjustTargetsForm extends ConsumerStatefulWidget {
  const _AdjustTargetsForm();

  @override
  ConsumerState<_AdjustTargetsForm> createState() => _AdjustTargetsFormState();
}

class _AdjustTargetsFormState extends ConsumerState<_AdjustTargetsForm> {
  late final OnboardingDraft _start = ref.read(onboardingControllerProvider);
  late double? _calories = _start.caloriesKcal;
  late double? _protein = _start.proteinG;
  late double? _carbs = _start.carbsG;
  late double? _fat = _start.fatG;
  bool _submitted = false;

  static String? _range(double? v, double min, double max, String label) {
    if (v == null) return 'Enter $label.';
    if (v < min || v > max) {
      final number = NumberFormat.decimalPattern();
      return '${label[0].toUpperCase()}${label.substring(1)} must be '
          '${number.format(min.round())}–${number.format(max.round())}.';
    }
    return null;
  }

  String? get _calorieError => _range(_calories, 500, 6000, 'calories');
  String? get _proteinError => _range(_protein, 0, 500, 'protein');
  String? get _carbsError => _range(_carbs, 0, 800, 'carbs');
  String? get _fatError => _range(_fat, 0, 400, 'fat');

  bool get _valid =>
      _calorieError == null &&
      _proteinError == null &&
      _carbsError == null &&
      _fatError == null;

  void _save() {
    setState(() => _submitted = true);
    if (!_valid) {
      SgHaptics.warn();
      return;
    }
    ref.read(onboardingControllerProvider.notifier).adjustTargets(
          caloriesKcal: _calories!,
          proteinG: _protein!,
          carbsG: _carbs!,
          fatG: _fat!,
        );
    SgHaptics.tap();
    Navigator.of(context).pop();
  }

  void _reset() {
    final draft = ref.read(onboardingControllerProvider);
    final plan = draft.plan();
    if (plan == null) return;
    setState(() {
      _calories = plan.caloriesKcal;
      _protein = plan.proteinG;
      _carbs = plan.carbsG;
      _fat = plan.fatG;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromMacros =
        (_protein ?? 0) * 4 + (_carbs ?? 0) * 4 + (_fat ?? 0) * 9;
    Widget field(String id, String label, String suffix, double? value,
            ValueChanged<double?> onChanged, String? error) =>
        Padding(
          padding: const EdgeInsets.only(bottom: SnapGrubDesignTokens.space12),
          child: E2eId(
            id: id,
            child: SgNumberField(
              label: label,
              suffix: suffix,
              value: value,
              nullable: true,
              decimal: false,
              textInputAction: TextInputAction.next,
              errorText: _submitted ? error : null,
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field('onboarding.calories', 'Calories', 'kcal', _calories,
            (v) => _calories = v, _calorieError),
        field('onboarding.protein', 'Protein', 'g', _protein,
            (v) => _protein = v, _proteinError),
        field('onboarding.carbs', 'Carbs', 'g', _carbs, (v) => _carbs = v,
            _carbsError),
        field('onboarding.fat', 'Fat', 'g', _fat, (v) => _fat = v, _fatError),
        Text(
          'Macros add up to about '
          '${NumberFormat.decimalPattern().format(fromMacros.round())} kcal.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space16),
        E2eId(
          id: 'onboarding.adjust.save',
          child:
              FilledButton(onPressed: _save, child: const Text('Save targets')),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space4),
        TextButton(
          onPressed: _reset,
          child: const Text('Reset to suggested'),
        ),
      ],
    );
  }
}
