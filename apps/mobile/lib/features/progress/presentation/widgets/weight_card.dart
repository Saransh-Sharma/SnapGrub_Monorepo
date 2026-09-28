import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/onboarding/domain/plan_calculator.dart'
    show Units;
import 'package:snapgrub/features/progress/application/progress_controller.dart';
import 'package:snapgrub/features/progress/data/body_measurement_repository.dart';
import 'package:snapgrub/features/progress/data/goal_weight_store.dart';
import 'package:snapgrub/features/progress/domain/weight_trend.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

/// Formats kilograms in the user's unit ("72.4 kg" / "159.6 lb").
String formatWeight(double kg, {required bool imperial, int decimals = 1}) =>
    Units.weight(kg, metric: !imperial, decimals: decimals);

double _display(double kg, bool imperial) => imperial ? Units.kgToLb(kg) : kg;

/// Weight: EMA trend over faint raw weigh-ins, goal line, projected goal date
/// and a "Log weight" action.
class WeightCard extends ConsumerWidget {
  const WeightCard({required this.range, super.key});

  final ProgressRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trendAsync = ref.watch(weightTrendProvider);
    final goal = ref.watch(goalWeightProvider).valueOrNull;
    final imperial = ref.watch(prefersImperialProvider);
    final projection = ref.watch(goalProjectionProvider);
    final user = ref.watch(homeUserContextProvider).valueOrNull;
    final today = user == null
        ? DateUtils.dateOnly(DateTime.now())
        : ref.watch(userDayTickProvider(user.timezone));

    return SgCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: trendAsync.when(
        loading: () => const _WeightSkeleton(),
        error: (error, _) => ErrorState(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(weightEntriesProvider),
        ),
        data: (trend) {
          if (trend.isEmpty) {
            return EmptyState(
              compact: true,
              illustration: SgIllustrationKind.chart,
              title: 'No weigh-ins yet',
              message: 'Log your weight to see your trend. '
                  'We smooth out daily ups and downs.',
              actionLabel: 'Log weight',
              onAction: () => showLogWeightSheet(context, ref),
            );
          }
          final from =
              DateTime(today.year, today.month, today.day - (range.days - 1));
          final window = trend.since(from);
          final latest = trend.latestTrend!;
          final change = window.length >= 2
              ? window.last.trend - window.first.trend
              : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weight', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            RollingNumber(
                              value: double.parse(_display(latest, imperial)
                                  .toStringAsFixed(1)),
                              format: NumberFormat('0.0'),
                              style: context.sg.metric,
                              semanticsLabel: 'Trend weight',
                            ),
                            const SizedBox(width: 4),
                            Text(imperial ? 'lb' : 'kg',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        if (change != null)
                          Text(
                            _changeLabel(change, imperial, range),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  E2eId(
                    id: 'progress.weight.log',
                    child: FilledButton.tonalIcon(
                      onPressed: () => showLogWeightSheet(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Log weight'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              WeightTrendChart(
                trend: trend,
                from: from,
                to: today,
                goalKg: goal,
                imperial: imperial,
              ),
              const SizedBox(height: 12),
              _ProjectionLine(
                projection: projection,
                goalKg: goal,
                imperial: imperial,
                onSetGoal: () => showGoalWeightSheet(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _changeLabel(double changeKg, bool imperial, ProgressRange r) {
    final v = _display(changeKg.abs(), imperial);
    final unit = imperial ? 'lb' : 'kg';
    if (v < .05) return 'Steady · last ${r.label}';
    final dir = changeKg < 0 ? 'Down' : 'Up';
    return '$dir ${v.toStringAsFixed(1)} $unit · last ${r.label}';
  }
}

class _ProjectionLine extends StatelessWidget {
  const _ProjectionLine({
    required this.projection,
    required this.goalKg,
    required this.imperial,
    required this.onSetGoal,
  });

  final GoalProjection? projection;
  final double? goalKg;
  final bool imperial;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = projection;
    if (p == null) return const SizedBox.shrink();
    if (p.status == ProjectionStatus.noGoal) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onSetGoal,
          icon: const Icon(Icons.flag_outlined, size: 18),
          label: const Text('Set a goal weight'),
        ),
      );
    }
    final goal = formatWeight(goalKg!, imperial: imperial);
    final text = switch (p.status) {
      ProjectionStatus.onPace =>
        'At this pace, you’ll reach $goal around ${DateFormat.yMMMd().format(p.date!)}.',
      ProjectionStatus.reached => 'You reached your goal of $goal!',
      ProjectionStatus.flat => 'Holding steady. Goal: $goal.',
      ProjectionStatus.awayFromGoal =>
        'Trending the other way lately. That’s normal. Goal: $goal.',
      ProjectionStatus.tooFar => '$goal is a while away at this pace.',
      ProjectionStatus.needsData =>
        'Log a few more weigh-ins to see when you’ll reach $goal.',
      ProjectionStatus.noGoal => '',
    };
    return Material(
      type: MaterialType.transparency,
      child: _projectionInk(theme, p, text),
    );
  }

  Widget _projectionInk(ThemeData theme, GoalProjection p, String text) {
    return InkWell(
      onTap: onSetGoal,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              p.status == ProjectionStatus.reached
                  ? Icons.emoji_events_outlined
                  : Icons.flag_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightSkeleton extends StatelessWidget {
  const _WeightSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SgSkeleton(width: 80, height: 14),
          SizedBox(height: 10),
          SgSkeleton(width: 120, height: 28),
          SizedBox(height: 16),
          SgSkeleton(height: 150, radius: 16),
        ],
      );
}

// ---------------------------------------------------------------------------
// Chart
// ---------------------------------------------------------------------------

/// Custom-painted weight chart: faint raw dots, a draw-on EMA trend line with
/// a soft area, a dashed goal line, and a gold glint on a new trend best.
class WeightTrendChart extends StatefulWidget {
  const WeightTrendChart({
    required this.trend,
    required this.from,
    required this.to,
    required this.imperial,
    this.goalKg,
    this.height = 168,
    super.key,
  });

  final WeightTrend trend;
  final DateTime from;
  final DateTime to;
  final double? goalKg;
  final bool imperial;
  final double height;

  @override
  State<WeightTrendChart> createState() => _WeightTrendChartState();
}

class _WeightTrendChartState extends State<WeightTrendChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play();
  }

  @override
  void didUpdateWidget(covariant WeightTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from) _play();
  }

  void _play() {
    if (SgMotion.of(context).reduced) {
      _draw.value = 1;
    } else {
      _draw.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final window = widget.trend.since(widget.from);
    final unit = widget.imperial ? 'lb' : 'kg';

    if (window.isEmpty) {
      final last = widget.trend.points.last;
      return Container(
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No weigh-ins in this range. Last: '
          '${formatWeight(last.raw, imperial: widget.imperial)} '
          'on ${DateFormat('d MMM').format(last.day)}.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final geometry = _ChartGeometry(
      points: window,
      from: widget.from,
      to: widget.to,
      goalKg: widget.goalKg,
    );
    final summary = StringBuffer('Weight chart. Trend ')
      ..write(formatWeight(window.last.trend, imperial: widget.imperial))
      ..write(', ${Labels.count(window.length, 'weigh-in day')} '
          'in range, lowest ')
      ..write(formatWeight(window.map((p) => p.raw).reduce(math.min),
          imperial: widget.imperial))
      ..write(', highest ')
      ..write(formatWeight(window.map((p) => p.raw).reduce(math.max),
          imperial: widget.imperial))
      ..write('.');
    if (widget.goalKg != null) {
      summary.write(
          ' Goal ${formatWeight(widget.goalKg!, imperial: widget.imperial)}.');
    }
    final glint = widget.trend.newTrendBest &&
        identical(window.last, widget.trend.points.last);

    return Semantics(
      label: summary.toString(),
      excludeSemantics: true,
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, widget.height);
            final lastPos =
                geometry.offset(size, window.last.day, window.last.trend);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WeightPainter(
                      geometry: geometry,
                      progress: _draw,
                      trendColor: tokens.energy.color,
                      dotColor: theme.colorScheme.onSurface,
                      gridColor: theme.colorScheme.outlineVariant,
                      goalColor: tokens.carbs.color,
                      labelStyle: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      imperial: widget.imperial,
                      unit: unit,
                    ),
                  ),
                ),
                if (glint)
                  AnimatedBuilder(
                    animation: _draw,
                    builder: (context, child) => Positioned(
                      left: lastPos.dx - 8,
                      top: lastPos.dy - 8,
                      child: Opacity(
                        opacity: Curves.easeOut
                            .transform(((_draw.value - .85) / .15).clamp(0, 1)),
                        child: child,
                      ),
                    ),
                    child: Tooltip(
                      message: 'New low',
                      child: SizedBox.square(
                        dimension: 16,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: SgMetal.gold.base.withValues(alpha: .55),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const MetalSurface(
                            metal: SgMetal.gold,
                            shape: MetalShape.disc,
                            idleGlint: true,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChartGeometry {
  _ChartGeometry({
    required this.points,
    required this.from,
    required this.to,
    required this.goalKg,
  }) {
    var lo = double.infinity;
    var hi = -double.infinity;
    for (final p in points) {
      lo = math.min(lo, math.min(p.raw, p.trend));
      hi = math.max(hi, math.max(p.raw, p.trend));
    }
    final span = math.max(hi - lo, 1.0);
    final g = goalKg;
    // Only pull the goal into view when it's near the data; otherwise the
    // line would flatten. Far goals get an edge label instead.
    if (g != null && g >= lo - span * 1.2 && g <= hi + span * 1.2) {
      lo = math.min(lo, g);
      hi = math.max(hi, g);
    }
    final pad = math.max((hi - lo) * .14, .4);
    minY = lo - pad;
    maxY = hi + pad;
    totalDays = math.max(1, to.difference(from).inDays);
  }

  final List<WeightPoint> points;
  final DateTime from;
  final DateTime to;
  final double? goalKg;
  late final double minY;
  late final double maxY;
  late final int totalDays;

  static const insetLeft = 6.0;
  static const insetRight = 40.0;
  static const insetTop = 10.0;
  static const insetBottom = 10.0;

  double x(Size size, DateTime day) {
    final w = size.width - insetLeft - insetRight;
    final d = day.difference(from).inDays.clamp(0, totalDays);
    return insetLeft + w * d / totalDays;
  }

  double y(Size size, double kg) {
    final h = size.height - insetTop - insetBottom;
    return insetTop + h * (1 - (kg - minY) / (maxY - minY));
  }

  Offset offset(Size size, DateTime day, double kg) =>
      Offset(x(size, day), y(size, kg));
}

class _WeightPainter extends CustomPainter {
  _WeightPainter({
    required this.geometry,
    required this.progress,
    required this.trendColor,
    required this.dotColor,
    required this.gridColor,
    required this.goalColor,
    required this.labelStyle,
    required this.imperial,
    required this.unit,
  }) : super(repaint: progress);

  final _ChartGeometry geometry;
  final Animation<double> progress;
  final Color trendColor;
  final Color dotColor;
  final Color gridColor;
  final Color goalColor;
  final TextStyle labelStyle;
  final bool imperial;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final t = Curves.easeInOutCubic.transform(progress.value);
    final right = size.width - _ChartGeometry.insetRight;

    // Grid: three hairlines with unit labels on the right.
    final grid = Paint()
      ..color = gridColor.withValues(alpha: .6)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final kg = g.minY + (g.maxY - g.minY) * (i + .5) / 3;
      final y = g.y(size, kg);
      canvas.drawLine(
          Offset(_ChartGeometry.insetLeft, y), Offset(right, y), grid);
      _label(canvas, _display(kg, imperial).toStringAsFixed(0),
          Offset(right + 6, y - 7));
    }

    // Goal line (dashed) or an edge hint when the goal is out of view.
    final goal = g.goalKg;
    if (goal != null) {
      final paint = Paint()
        ..color = goalColor
        ..strokeWidth = 1.4;
      if (goal >= g.minY && goal <= g.maxY) {
        final y = g.y(size, goal);
        var x = _ChartGeometry.insetLeft;
        while (x < right) {
          canvas.drawLine(
              Offset(x, y), Offset(math.min(x + 6, right), y), paint);
          x += 10;
        }
        _label(canvas, 'Goal', Offset(right + 6, y - 7),
            color: goalColor, bold: true);
      } else {
        final above = goal > g.maxY;
        _label(
          canvas,
          '${above ? '↑' : '↓'} Goal ${_display(goal, imperial).toStringAsFixed(0)} $unit',
          Offset(_ChartGeometry.insetLeft, above ? 0 : size.height - 14),
          color: goalColor,
          bold: true,
        );
      }
    }

    // Raw weigh-ins: faint dots that fade in.
    final dot = Paint()..color = dotColor.withValues(alpha: .22 * t);
    for (final p in g.points) {
      canvas.drawCircle(g.offset(size, p.day, p.raw), 2.6, dot);
    }

    if (g.points.length == 1) {
      final c = g.offset(size, g.points.first.day, g.points.first.trend);
      canvas.drawCircle(c, 4.5 * t, Paint()..color = trendColor);
      return;
    }

    // Trend path, drawn on.
    final path = Path();
    for (var i = 0; i < g.points.length; i++) {
      final o = g.offset(size, g.points[i].day, g.points[i].trend);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        final prev = g.offset(size, g.points[i - 1].day, g.points[i - 1].trend);
        final mid = (prev.dx + o.dx) / 2;
        path.cubicTo(mid, prev.dy, mid, o.dy, o.dx, o.dy);
      }
    }
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    var remaining = total * t;
    final drawn = Path();
    for (final m in metrics) {
      if (remaining <= 0) break;
      drawn.addPath(
          m.extractPath(0, math.min(remaining, m.length)), Offset.zero);
      remaining -= m.length;
    }

    // Soft area under the line.
    final bounds = drawn.getBounds();
    if (!bounds.isEmpty) {
      final area = Path.from(drawn)
        ..lineTo(bounds.right, size.height)
        ..lineTo(bounds.left, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, bounds.top),
            Offset(0, size.height),
            [
              trendColor.withValues(alpha: .16),
              trendColor.withValues(alpha: 0),
            ],
          ),
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = trendColor,
    );

    if (t >= .98) {
      final last = g.offset(size, g.points.last.day, g.points.last.trend);
      canvas.drawCircle(
          last, 5.5, Paint()..color = trendColor.withValues(alpha: .25));
      canvas.drawCircle(last, 3.6, Paint()..color = trendColor);
    }
  }

  void _label(Canvas canvas, String text, Offset at,
      {Color? color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: labelStyle.copyWith(
          color: color,
          fontWeight: bold ? FontWeight.w600 : null,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant _WeightPainter old) =>
      old.geometry != geometry ||
      old.trendColor != trendColor ||
      old.imperial != imperial;
}

// ---------------------------------------------------------------------------
// Sheets
// ---------------------------------------------------------------------------

/// Opens the "Log weight" ruler sheet and saves a body measurement.
Future<void> showLogWeightSheet(BuildContext context, WidgetRef ref) async {
  final user = ref.read(homeUserContextProvider).valueOrNull;
  if (user == null) return;
  final imperial = ref.read(prefersImperialProvider);
  final latest = ref.read(latestWeightKgProvider) ?? (imperial ? 72.6 : 70.0);
  final kg = await showSgSheet<double>(
    context: context,
    title: 'Log weight',
    subtitle: 'Weigh in the same way each time for the best trend.',
    builder: (context) => _WeightPickerSheet(
      initialKg: latest,
      imperial: imperial,
      saveLabel: 'Save',
      fieldId: 'progress.weight.ruler',
    ),
  );
  if (kg == null) return;
  try {
    await ref
        .read(bodyMeasurementRepositoryProvider)
        .addWeight(userId: user.userId, weightKg: kg);
    unawaited(SgHaptics.logged());
    unawaited(ref
        .read(syncControllerProvider.notifier)
        .syncNow()
        .catchError((Object _) {}));
    if (context.mounted) {
      showSgToast(context, 'Logged ${formatWeight(kg, imperial: imperial)}',
          icon: Icons.monitor_weight_outlined);
    }
  } catch (error) {
    if (context.mounted) {
      showSgToast(context, friendlyError(error).message,
          icon: Icons.info_outline_rounded);
    }
  }
}

/// Opens a ruler sheet to set (or change) the goal weight.
Future<void> showGoalWeightSheet(BuildContext context, WidgetRef ref) async {
  final user = ref.read(homeUserContextProvider).valueOrNull;
  if (user == null) return;
  final imperial = ref.read(prefersImperialProvider);
  final current = ref.read(goalWeightProvider).valueOrNull ??
      ref.read(latestWeightKgProvider) ??
      70.0;
  final kg = await showSgSheet<double>(
    context: context,
    title: 'Goal weight',
    subtitle: 'Used for your projection and milestones.',
    builder: (context) => _WeightPickerSheet(
      initialKg: current,
      imperial: imperial,
      saveLabel: 'Save goal',
      fieldId: 'progress.goal_weight.ruler',
    ),
  );
  if (kg == null) return;
  await GoalWeightStore.save(user.userId, kg);
  ref.invalidate(goalWeightProvider);
  unawaited(SgHaptics.tap());
}

class _WeightPickerSheet extends StatefulWidget {
  const _WeightPickerSheet({
    required this.initialKg,
    required this.imperial,
    required this.saveLabel,
    required this.fieldId,
  });

  final double initialKg;
  final bool imperial;
  final String saveLabel;
  final String fieldId;

  @override
  State<_WeightPickerSheet> createState() => _WeightPickerSheetState();
}

class _WeightPickerSheetState extends State<_WeightPickerSheet> {
  late double _value = double.parse(
      _display(widget.initialKg, widget.imperial).toStringAsFixed(1));

  @override
  Widget build(BuildContext context) {
    final min = widget.imperial ? 66.0 : 30.0;
    final max = widget.imperial ? 550.0 : 250.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        E2eId(
          id: widget.fieldId,
          child: SgRulerPicker(
            value: _value.clamp(min, max),
            min: min,
            max: max,
            unit: widget.imperial ? 'lb' : 'kg',
            semanticLabel: 'Weight',
            onChanged: (v) => setState(() => _value = v),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            final kg = widget.imperial ? Units.lbToKg(_value) : _value;
            Navigator.of(context).pop(double.parse(kg.toStringAsFixed(2)));
          },
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}
