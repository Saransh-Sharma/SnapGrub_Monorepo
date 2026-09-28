import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/photo_analysis/application/analysis_queue_controller.dart';
import 'package:snapgrub/features/photo_analysis/presentation/photo_analysis_error.dart';

/// A photo being analyzed in the background. Scan beam while working, then
/// the detected foods pop in and the card offers Review.
class PendingAnalysisCard extends ConsumerWidget {
  const PendingAnalysisCard({required this.job, super.key});

  final AnalysisJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final queue = ref.read(analysisQueueProvider.notifier);
    final draft = job.draft;
    final failure = job.status == AnalysisJobStatus.failed
        ? photoAnalysisError(job.error)
        : null;
    final status = switch (job.status) {
      AnalysisJobStatus.uploading => 'Uploading photo…',
      AnalysisJobStatus.analyzing => 'Identifying foods…',
      AnalysisJobStatus.ready => 'Ready to review',
      AnalysisJobStatus.failed => failure!.title,
    };

    Future<void> review() async {
      if (draft == null) return;
      SgHaptics.tap();
      final saved = await context.push<Object?>('/meal-editor', extra: draft);
      // The editor announces the logged meal itself (with Undo).
      if (saved != null) queue.dismiss(job.id);
    }

    return E2eId(
      id: 'today.analysis.${job.id}',
      child: SgCard(
        variant: SgCardVariant.raised,
        padding: const EdgeInsets.all(12),
        onTap: job.status == AnalysisJobStatus.ready ? review : null,
        child: Semantics(
          liveRegion: true,
          label: 'Photo meal. $status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox.square(
                      dimension: 76,
                      child: Hero(
                        tag: 'analysis-photo-${job.id}',
                        child: ScanBeam(
                          active: job.isWorking,
                          confidence: job.status == AnalysisJobStatus.analyzing
                              ? .35
                              : 0,
                          child: Image.file(
                            File(job.asset.thumbLocalPath ?? job.asset.localPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                ColoredBox(color: tokens.energy.soft),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (job.isWorking) ...[
                              const _PulseDot(),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: SgMotion.of(context).settle,
                                child: Text(
                                  status,
                                  key: ValueKey(status),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: job.status == AnalysisJobStatus.failed
                                        ? tokens.warning
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (draft != null) ...[
                          Text(draft.title.isEmpty ? 'Photo meal' : draft.title,
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          RollingNumber(
                            value: draft.caloriesKcal.round(),
                            suffix: ' kcal',
                            style: tokens.metricSmall,
                          ),
                        ] else if (job.status == AnalysisJobStatus.failed)
                          Text(
                            failure!.message,
                            style: theme.textTheme.bodySmall,
                          )
                        else
                          SgSkeleton.lines(count: 2, spacing: 8),
                      ],
                    ),
                  ),
                ],
              ),
              if (draft != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < draft.items.length && i < 6; i++)
                      SgEntrance(
                        index: i,
                        scale: .8,
                        offset: Offset.zero,
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(draft.items[i].name),
                        ),
                      ),
                  ],
                ),
              ],
              if (job.status == AnalysisJobStatus.ready ||
                  job.status == AnalysisJobStatus.failed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        SgHaptics.tap();
                        queue.dismiss(job.id);
                      },
                      child: const Text('Discard'),
                    ),
                    const Spacer(),
                    if (job.status == AnalysisJobStatus.failed) ...[
                      OutlinedButton(
                        onPressed: () => context.push('/meal-editor'),
                        child: const Text('Enter manually'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => queue.retry(job.id),
                        child: const Text('Try again'),
                      ),
                    ] else
                      E2eId(
                        id: 'today.analysis.review',
                        child: FilledButton.icon(
                          onPressed: review,
                          icon: const Icon(Icons.checklist_rounded, size: 18),
                          label: const Text('Review'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SgEffectsScope.of(context).animates) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return FadeTransition(
      opacity: Tween(begin: .35, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
