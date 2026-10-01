import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/progress/domain/intake_summary.dart';

final _kcal = NumberFormat.decimalPattern();

/// Calories per day as bars against a dashed target line, with the average
/// per logged day and a days-logged count. Scrub to inspect a day.
///
/// Over-target days are shown with a neutral cap above the target — never an
/// error colour (adherence-neutral).
class CalorieCard extends StatefulWidget {
  const CalorieCard({
    required this.summary,
    required this.range,
    this.targetKcal,
    super.key,
  });

  final IntakeSummary summary;
  final ProgressRange range;
  final double? targetKcal;

  @override
  State<CalorieCard> createState() => _CalorieCardState();
}

class _CalorieCardState extends State<CalorieCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  int? _touched;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play();
  }

  @override
  void didUpdateWidget(covariant CalorieCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      _touched = null;
      _play();
    }
  }

  void _play() {
    if (SgMotion.of(context).reduced) {
      _grow.value = 1;
    } else {
      _grow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final s = widget.summary;
    final target = widget.targetKcal;
    final days = s.days;
    final avg = s.avgKcal.round();
    final today = days.isEmpty ? null : days.last;
    final focus =
        _touched == null || _touched! >= days.length ? today : days[_touched!];

    final semantics =
        StringBuffer('Calories chart for the last ${widget.range.label}. ')
          ..write(s.daysLogged == 0
              ? 'No days logged yet.'
              : 'Average ${_kcal.format(avg)} kilocalories per logged day, '
                  '${s.daysLogged} of ${days.length} days logged.');
    if (target != null) {
      semantics.write(' Target ${_kcal.format(target.round())} per day.');
    }

    return SgCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calories', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        RollingNumber(
                          value: avg,
                          style: tokens.metric,
                          semanticsLabel: 'Average calories',
                        ),
                        const SizedBox(width: 4),
                        Text('avg kcal/day',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              _DaysLoggedBadge(logged: s.daysLogged, total: days.length),
            ],
          ),
          const SizedBox(height: 16),
          E2eId(
            id: 'progress.calories.chart',
            child: Semantics(
              label: semantics.toString(),
              child: SizedBox(
                height: 168,
                child: AnimatedBuilder(
                  animation: _grow,
                  builder: (context, _) => BarChart(
                    _data(context, days, target),
                    duration: Duration.zero,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (focus != null)
            AnimatedSwitcher(
              duration: SgMotion.of(context).press,
              child: _FocusLine(
                key: ValueKey(focus.day),
                day: focus,
                isToday: identical(focus, today),
                target: target,
              ),
            ),
        ],
      ),
    );
  }

  BarChartData _data(
      BuildContext context, List<DayIntake> days, double? target) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final n = days.length;
    final peak = days.fold<double>(0, (m, d) => math.max(m, d.kcal));
    final maxY = math.max(peak, target ?? 0) * 1.15;
    final safeMax = maxY <= 0 ? 2000.0 : maxY;
    final barWidth = n <= 7
        ? 22.0
        : n <= 30
            ? 7.0
            : 2.6;
    // Stagger: each bar starts a little after the previous one.
    final step = math.min(.045, .5 / math.max(1, n));
    final t = _grow.value;
    final energy = tokens.energy.color;

    return BarChartData(
      maxY: safeMax,
      minY: 0,
      alignment: BarChartAlignment.spaceAround,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= n) return const SizedBox.shrink();
              final label = _axisLabel(days, i);
              if (label == null) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: i == _touched
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          if (target != null && target > 0)
            HorizontalLine(
              y: target,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: .7),
              strokeWidth: 1.2,
              dashArray: const [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(bottom: 4),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                labelResolver: (_) => 'Target ${_kcal.format(target.round())}',
              ),
            ),
        ],
      ),
      barTouchData: BarTouchData(
        touchExtraThreshold: const EdgeInsets.symmetric(horizontal: 6),
        touchTooltipData: BarTouchTooltipData(
          tooltipBorderRadius: BorderRadius.circular(12),
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          tooltipMargin: 8,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (_) => tokens.hero,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final d = days[group.x];
            return BarTooltipItem(
              '${DateFormat('EEE d MMM').format(d.day)}\n',
              theme.textTheme.labelSmall!.copyWith(color: tokens.onHeroMuted),
              children: [
                TextSpan(
                  text: d.logged
                      ? '${_kcal.format(d.kcal.round())} kcal'
                      : 'Not logged',
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: tokens.onHero,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (event, response) {
          final index = response?.spot?.touchedBarGroupIndex;
          if (!event.isInterestedForInteractions || index == null) return;
          if (index != _touched) {
            SgHaptics.tick();
            setState(() => _touched = index);
          }
        },
      ),
      barGroups: [
        for (var i = 0; i < n; i++)
          () {
            final local = ((t - i * step) / math.max(.001, 1 - (n - 1) * step))
                .clamp(0.0, 1.0);
            final grow = Curves.easeOutCubic.transform(local);
            final kcal = days[i].kcal * grow;
            final over = target != null && kcal > target;
            final selected = i == _touched;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: kcal,
                  width: barWidth,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(math.min(barWidth / 2, 6)),
                  ),
                  color: energy.withValues(
                      alpha: _touched == null || selected ? 1 : .45),
                  rodStackItems: over
                      ? [
                          BarChartRodStackItem(
                              0,
                              target,
                              energy.withValues(
                                  alpha:
                                      _touched == null || selected ? 1 : .45)),
                          BarChartRodStackItem(target, kcal,
                              tokens.overTarget.withValues(alpha: .55)),
                        ]
                      : const [],
                ),
              ],
            );
          }(),
      ],
    );
  }

  String? _axisLabel(List<DayIntake> days, int i) {
    final n = days.length;
    final d = days[i].day;
    if (n <= 7) return DateFormat('E').format(d).substring(0, 1);
    final every = n <= 30 ? 7 : 30;
    // Anchor labels to the last day (today) so it is always labelled.
    if ((n - 1 - i) % every != 0) return null;
    return DateFormat('d MMM').format(d);
  }
}

class _DaysLoggedBadge extends StatelessWidget {
  const _DaysLoggedBadge({required this.logged, required this.total});

  final int logged;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.energy.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$logged of $total days logged',
        style: theme.textTheme.labelMedium?.copyWith(
          color: tokens.energy.onSoft,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _FocusLine extends StatelessWidget {
  const _FocusLine({
    required this.day,
    required this.isToday,
    required this.target,
    super.key,
  });

  final DayIntake day;
  final bool isToday;
  final double? target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isToday ? 'Today' : DateFormat('EEE d MMM').format(day.day);
    final value = target == null
        ? '${_kcal.format(day.kcal.round())} kcal'
        : '${_kcal.format(day.kcal.round())} / ${_kcal.format(target!.round())} kcal';
    return Row(
      children: [
        Text(label,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
