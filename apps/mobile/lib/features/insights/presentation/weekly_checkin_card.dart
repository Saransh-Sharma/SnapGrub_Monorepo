import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/data/repositories/analytics_repository.dart';
import 'package:snapgrub/features/insights/application/weekly_checkin_summary_mapper.dart';

/// Weekly check-in as a written, editorial summary: a serif headline for the
/// one suggestion that matters, then a compact visual metric row.
class WeeklyCheckInCard extends ConsumerStatefulWidget {
  const WeeklyCheckInCard({
    required this.summary,
    this.onReviewRepeatFoods,
    this.onSeeWeek,
    super.key,
  });

  final WeeklyCheckInSummary? summary;
  final VoidCallback? onReviewRepeatFoods;

  /// Opens the weekly recap story.
  final VoidCallback? onSeeWeek;

  @override
  ConsumerState<WeeklyCheckInCard> createState() => _WeeklyCheckInCardState();
}

class _WeeklyCheckInCardState extends ConsumerState<WeeklyCheckInCard> {
  String? _trackedWeek;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _trackView();
    });
  }

  @override
  void didUpdateWidget(covariant WeeklyCheckInCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _trackView();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;

    Widget header({String? trailing}) => Row(
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text('Weekly check-in',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
            if (trailing != null)
              Text(trailing,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        );

    final seeWeek = widget.onSeeWeek == null
        ? null
        : E2eId(
            id: 'progress.recap',
            child: FilledButton.tonalIcon(
              onPressed: widget.onSeeWeek,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('See your week'),
            ),
          );

    if (summary == null || !summary.hasEnoughData) {
      return SgCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(),
            const SizedBox(height: 12),
            Text(
              'Your first check-in is coming',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              summary?.loggingRhythm ??
                  'Log a few days and we’ll summarize your week here.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (seeWeek != null) ...[
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: seeWeek),
            ],
          ],
        ),
      );
    }

    final tokens = context.sg;
    return SgCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(trailing: 'Week of ${DateFormat('d MMM').format(summary.weekStart)}'),
          const SizedBox(height: 12),
          Text(summary.primaryActionTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            summary.primaryActionBody,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoUp = constraints.maxWidth >= 300;
              final tiles = [
                _MetricTile(
                  icon: Icons.event_available_rounded,
                  label: 'Logging',
                  value: summary.loggingRhythm,
                  palette: tokens.energy,
                ),
                _MetricTile(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Calories',
                  value: summary.calorieDelta,
                  palette: tokens.carbs,
                ),
                _MetricTile(
                  icon: Icons.egg_alt_outlined,
                  label: 'Protein',
                  value: summary.proteinConsistency,
                  palette: tokens.protein,
                ),
                _MetricTile(
                  icon: Icons.repeat_rounded,
                  label: 'Pattern',
                  value: summary.repeatPattern,
                  palette: tokens.fat,
                ),
              ];
              if (!twoUp) {
                return Column(
                  children: [
                    for (final t in tiles)
                      Padding(padding: const EdgeInsets.only(bottom: 8), child: t),
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < tiles.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: tiles[i]),
                            const SizedBox(width: 8),
                            Expanded(child: tiles[i + 1]),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (seeWeek != null) seeWeek,
              TextButton.icon(
                onPressed: _reviewRepeatFoods,
                icon: const Icon(Icons.repeat_rounded, size: 18),
                label: const Text('See repeats'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reviewRepeatFoods() async {
    final summary = widget.summary;
    if (summary != null) {
      await ref.read(analyticsRepositoryProvider).track(
        'weekly_checkin_action_tapped',
        properties: {
          'action_id': summary.actionId,
          'week_start': _weekKey(summary.weekStart),
        },
      );
    }
    widget.onReviewRepeatFoods?.call();
  }

  void _trackView() {
    final summary = widget.summary;
    if (summary == null) return;
    final key = _weekKey(summary.weekStart);
    if (_trackedWeek == key) return;
    _trackedWeek = key;
    ref.read(analyticsRepositoryProvider).track(
      'weekly_checkin_viewed',
      properties: {
        'week_start': key,
        'status': summary.status,
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final String value;
  final MacroPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: palette.soft.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: palette.onSoft),
                const SizedBox(width: 6),
                Text(label,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: palette.onSoft)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

String _weekKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
