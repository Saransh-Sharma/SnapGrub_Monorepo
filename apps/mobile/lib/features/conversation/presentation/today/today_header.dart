import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/milestones/application/streak_provider.dart';
import 'package:snapgrub/features/milestones/domain/streak.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

/// Day title with prev/next, a calendar jump, the streak medallion and a
/// quiet sync dot.
class TodayHeader extends ConsumerWidget {
  const TodayHeader({
    required this.day,
    required this.today,
    required this.onPrevious,
    required this.onNext,
    required this.onCalendar,
    super.key,
  });

  final DateTime day;
  final DateTime today;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onCalendar;

  String get _label {
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(day);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final label = _label;
    final dayIdentifier =
        label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final streak = ref.watch(streakProvider);
    final sync = ref.watch(syncControllerProvider).valueOrNull ?? SyncStatus.idle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 2),
      child: Row(
        children: [
          E2eId(
            id: 'conversation.previous_day',
            child: IconButton(
              tooltip: 'Previous day',
              onPressed: () {
                SgHaptics.tick();
                onPrevious();
              },
              icon: const Icon(Icons.chevron_left_rounded),
            ),
          ),
          Flexible(
            child: E2eId(
              id: 'conversation.date.$dayIdentifier',
              child: Semantics(
                button: true,
                label: '$label. Choose another day',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onCalendar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          E2eId(
            id: 'conversation.next_day',
            child: IconButton(
              tooltip: 'Next day',
              onPressed: onNext == null
                  ? null
                  : () {
                      SgHaptics.tick();
                      onNext!();
                    },
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const Spacer(),
          if (sync == SyncStatus.pending ||
              sync == SyncStatus.syncing ||
              sync == SyncStatus.failed ||
              sync == SyncStatus.conflict)
            _SyncDot(status: sync),
          const SizedBox(width: 6),
          StreakBadge(streak: streak),
        ],
      ),
    );
  }
}

class _SyncDot extends StatelessWidget {
  const _SyncDot({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final attention =
        status == SyncStatus.failed || status == SyncStatus.conflict;
    final label = switch (status) {
      SyncStatus.pending => 'Saved on phone',
      SyncStatus.syncing => 'Syncing…',
      SyncStatus.failed => 'Not synced',
      SyncStatus.conflict => 'Needs review',
      _ => 'Synced',
    };
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: () => context.push('/sync'),
          radius: 24,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              attention
                  ? Icons.sync_problem_rounded
                  : Icons.cloud_upload_outlined,
              size: 18,
              color: attention
                  ? tokens.warning
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Flame + day count on a metal medallion whose tier shifts silver → copper
/// → gold → holo as the logging streak grows.
class StreakBadge extends StatelessWidget {
  const StreakBadge({required this.streak, super.key});

  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = streak.tier;
    final metal = tier.metal;
    final days = streak.current;
    final label = days == 0
        ? 'Log a meal to start a streak.'
        : '$days-day streak${streak.loggedToday ? '' : '. Log today to keep it.'}';
    Widget medal = SizedBox.square(
      dimension: 30,
      child: metal == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHigh,
              ),
              child: Icon(Icons.local_fire_department_outlined,
                  size: 17, color: theme.colorScheme.onSurfaceVariant),
            )
          : MetalSurface(
              metal: metal,
              shape: MetalShape.disc,
              child: Icon(Icons.local_fire_department_rounded,
                  size: 17, color: metal.shadow),
            ),
    );
    if (tier == StreakTier.holo) {
      medal = HoloFoil(borderRadius: 999, child: medal);
    }
    return E2eId(
      id: 'today.streak',
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () {
              SgHaptics.tap();
              context.push('/milestones');
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: streak.loggedToday || days == 0 ? 1 : .55,
                    child: medal,
                  ),
                  const SizedBox(width: 6),
                  RollingNumber(
                    value: days,
                    style: context.sg.metricSmall.copyWith(fontSize: 15),
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
