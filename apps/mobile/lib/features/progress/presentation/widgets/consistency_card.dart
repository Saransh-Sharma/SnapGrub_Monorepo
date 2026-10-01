import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/milestones/domain/streak.dart';
import 'package:snapgrub/features/milestones/presentation/milestone_medal.dart';

/// Heatmap of logged days (last 13 weeks, Monday-first columns) plus the
/// current and best logging streak with the matching medal.
///
/// Days bridged by the weekly automatic freeze render as frosted cells.
class ConsistencyCard extends StatelessWidget {
  const ConsistencyCard({
    required this.loggedDays,
    required this.streak,
    required this.today,
    this.weeks = 13,
    super.key,
  });

  final Set<DateTime> loggedDays;
  final StreakSummary streak;
  final DateTime today;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = DateUtils.dateOnly(today);
    final monday = t.subtract(Duration(days: t.weekday - 1));
    final start =
        DateTime(monday.year, monday.month, monday.day - 7 * (weeks - 1));
    final logged = {for (final d in loggedDays) DateUtils.dateOnly(d)};
    final frozen = {for (final d in streak.frozenDays) DateUtils.dateOnly(d)};
    final inWindow = logged.where((d) => !d.isBefore(start) && !d.isAfter(t));

    return SgCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Consistency', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text('Last $weeks weeks',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Logging calendar: ${inWindow.length} days logged in the '
                'last $weeks weeks'
                '${frozen.isEmpty ? '' : ', ${frozen.length} bridged by a streak freeze'}.',
            excludeSemantics: true,
            child: _Heatmap(
              start: start,
              today: t,
              weeks: weeks,
              logged: logged,
              frozen: frozen,
            ),
          ),
          const SizedBox(height: 10),
          const _Legend(),
          const SizedBox(height: 14),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 14),
          _StreakRow(streak: streak),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({
    required this.start,
    required this.today,
    required this.weeks,
    required this.logged,
    required this.frozen,
  });

  final DateTime start;
  final DateTime today;
  final int weeks;
  final Set<DateTime> logged;
  final Set<DateTime> frozen;

  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.sg;
    const labelW = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = math.min(
          22.0,
          (constraints.maxWidth - labelW - _gap * weeks) / weeks,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelW,
              child: Column(
                children: [
                  for (var r = 0; r < 7; r++)
                    SizedBox(
                      height: cell + _gap,
                      child: r.isEven
                          ? Text(
                              const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][r],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            )
                          : null,
                    ),
                ],
              ),
            ),
            for (var w = 0; w < weeks; w++)
              Padding(
                padding: const EdgeInsets.only(left: _gap),
                child: Column(
                  children: [
                    for (var r = 0; r < 7; r++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: _gap),
                        child: _cell(
                          context,
                          DateTime(
                              start.year, start.month, start.day + w * 7 + r),
                          cell,
                          scheme,
                          tokens,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _cell(BuildContext context, DateTime day, double size,
      ColorScheme scheme, SnapGrubTokens tokens) {
    final radius = BorderRadius.circular(size * .28);
    if (day.isAfter(today)) return SizedBox.square(dimension: size);
    final isToday = day == today;
    if (frozen.contains(day)) {
      return _FrostCell(size: size, radius: radius);
    }
    final on = logged.contains(day);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            on ? tokens.energy.color : scheme.onSurface.withValues(alpha: .06),
        borderRadius: radius,
        border: isToday
            ? Border.all(
                color: scheme.onSurface.withValues(alpha: .7), width: 1.4)
            : null,
      ),
    );
  }
}

/// A "frosted" cell: icy gradient, hairline rim and a tiny snowflake.
class _FrostCell extends StatelessWidget {
  const _FrostCell({required this.size, required this.radius});

  final double size;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final ice = tokens.info;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: tokens.dark ? .28 : .95),
            ice.withValues(alpha: .35),
          ],
        ),
        border: Border.all(color: ice.withValues(alpha: .55), width: .8),
      ),
      child: size >= 12
          ? Icon(Icons.ac_unit_rounded, size: size * .62, color: ice)
          : null,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final style = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    Widget swatch(Widget box, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [box, const SizedBox(width: 6), Text(label, style: style)],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        swatch(
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: tokens.energy.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          'Logged',
        ),
        swatch(
          _FrostCell(size: 12, radius: BorderRadius.circular(3)),
          'Streak freeze (1 free per week)',
        ),
      ],
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.streak});

  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final tier = medalTierForStreak(streak.tier);
    final current = streak.current;
    final String note;
    if (current == 0) {
      note = 'Log a meal today to start a streak.';
    } else if (!streak.loggedToday) {
      note = 'Log today to keep your streak.';
    } else if (streak.frozenDays.isNotEmpty) {
      final covered = streak.frozenDays.reduce((a, b) => a.isAfter(b) ? a : b);
      note = 'A streak freeze covered ${DateFormat('EEEE').format(covered)}.';
    } else {
      note = 'Nice work. Keep it going.';
    }
    return Row(
      children: [
        MilestoneMedal(
          icon: Icons.local_fire_department_rounded,
          tier: tier,
          earned: tier != null,
          size: 56,
          semanticLabel: tier == null
              ? 'No streak medal yet'
              : '${tier.label} streak medal',
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  RollingNumber(
                    value: current,
                    style: tokens.metric,
                    semanticsLabel: 'Current streak',
                  ),
                  const SizedBox(width: 6),
                  Text('day streak', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  Text('Best ${streak.best}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                ],
              ),
              const SizedBox(height: 2),
              Text(note,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
