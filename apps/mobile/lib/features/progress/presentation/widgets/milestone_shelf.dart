import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/milestones/application/milestones_provider.dart';
import 'package:snapgrub/features/milestones/domain/milestone.dart';
import 'package:snapgrub/features/milestones/presentation/milestone_medal.dart';

/// Horizontal shelf of earned medals; tapping anywhere opens the gallery.
class MilestoneShelf extends ConsumerWidget {
  const MilestoneShelf({super.key});

  static const _maxLive = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final all = ref.watch(milestonesProvider);
    final earned = ref.watch(earnedMilestonesProvider);
    void open() => context.push('/milestones');

    return E2eId(
      id: 'progress.milestones',
      child: SgCard(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 16),
        onTap: open,
        semanticLabel: 'Milestones, ${earned.length} of ${kMilestones.length} '
            'earned. Opens the gallery.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Milestones', style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Text(
                  '${earned.length} of ${kMilestones.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
            ),
            const SizedBox(height: 12),
            if (all.isLoading && earned.isEmpty)
              const SizedBox(
                height: 92,
                child: Row(
                  children: [
                    SgSkeleton(width: 60, height: 60, circle: true),
                    SizedBox(width: 14),
                    SgSkeleton(width: 60, height: 60, circle: true),
                    SizedBox(width: 14),
                    SgSkeleton(width: 60, height: 60, circle: true),
                  ],
                ),
              )
            else if (earned.isEmpty)
              _EmptyShelf(next: _nextUp(all.valueOrNull ?? const []))
            else
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: earned.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final m = earned[i];
                    return SgEntrance(
                      index: i,
                      scale: .85,
                      offset: const Offset(12, 0),
                      child: SizedBox(
                        width: 68,
                        child: Column(
                          children: [
                            MilestoneMedal(
                              icon: m.definition.icon,
                              tier: m.definition.tier,
                              size: 60,
                              live: i < _maxLive,
                              semanticLabel: medalSemantics(m),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m.definition.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  MilestoneStatus? _nextUp(List<MilestoneStatus> all) {
    MilestoneStatus? best;
    for (final m in all) {
      if (m.earned) continue;
      if (best == null || m.progress > best.progress) best = m;
    }
    return best;
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({required this.next});

  final MilestoneStatus? next;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = next?.definition ?? kMilestones.first;
    return Row(
      children: [
        MilestoneMedal(icon: def.icon, earned: false, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next: ${def.title}', style: theme.textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(
                def.howTo,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
