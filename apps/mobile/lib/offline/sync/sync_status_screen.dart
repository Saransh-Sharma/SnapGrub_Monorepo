import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

final conflictCommandsProvider = FutureProvider.autoDispose((ref) async {
  // Re-query whenever sync state moves.
  ref.watch(syncControllerProvider);
  final auth = await ref.watch(authControllerProvider.future);
  final userId = auth.userId;
  if (userId == null) return const <OutboxCommand>[];
  return ref.watch(outboxRepositoryProvider).conflictCommands(userId);
});

/// Changes saved on this phone that the server hasn't accepted yet
/// (pending, failed, blocked or in conflict).
final unsyncedChangeCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  ref.watch(syncControllerProvider);
  final auth = await ref.watch(authControllerProvider.future);
  final userId = auth.userId;
  if (userId == null) return 0;
  return ref.watch(outboxRepositoryProvider).pendingCount(userId);
});

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        ref.watch(syncControllerProvider).valueOrNull ?? SyncStatus.idle;
    final conflicts = ref.watch(conflictCommandsProvider);
    final unsynced = ref.watch(unsyncedChangeCountProvider).valueOrNull ?? 0;
    final syncing = status == SyncStatus.syncing;

    Future<void> syncNow() async {
      SgHaptics.tap();
      await ref.read(syncControllerProvider.notifier).syncNow();
    }

    return AppScaffold(
      title: 'Sync',
      e2eId: 'scaffold.sync',
      showSyncBanner: false,
      actions: [
        E2eId(
          id: 'sync.now',
          child: IconButton(
            tooltip: 'Sync now',
            onPressed: syncing ? null : syncNow,
            icon: const Icon(Icons.sync_rounded),
          ),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: syncNow,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: SnapGrubDesignTokens.space32),
          children: [
            _StatusCard(status: status, unsynced: unsynced),
            const SgSectionHeader(title: 'Needs attention'),
            conflicts.when(
              skipLoadingOnReload: true,
              loading: () => SgCard(child: SgSkeleton.lines(count: 2)),
              error: (_, __) => const InlineError(
                message: 'Couldn’t load conflicts. Pull to retry.',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SgCard(
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: context.sg.success),
                        const SizedBox(width: SnapGrubDesignTokens.space12),
                        const Expanded(child: Text('No conflicts.')),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final command in items) ...[
                      _ConflictCard(command: command),
                      const SizedBox(height: SnapGrubDesignTokens.space12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.unsynced});

  final SyncStatus status;
  final int unsynced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final changes = Labels.count(unsynced, 'change');
    final (icon, color, title, message) = switch (status) {
      SyncStatus.syncing => (
          Icons.sync_rounded,
          tokens.info,
          'Syncing…',
          'Sending changes and getting updates.',
        ),
      SyncStatus.synced => (
          Icons.cloud_done_rounded,
          tokens.success,
          'All synced',
          'Everything is backed up to your account.',
        ),
      SyncStatus.pending => (
          Icons.cloud_upload_outlined,
          theme.colorScheme.onSurfaceVariant,
          'Saved on your phone',
          unsynced > 0
              ? '$changes will sync when you’re online.'
              : 'Your changes will sync when you’re online.',
        ),
      SyncStatus.failed => (
          Icons.sync_problem_rounded,
          tokens.warning,
          'Some changes didn’t sync',
          'Nothing is lost. We’ll retry, or tap Sync now.',
        ),
      SyncStatus.conflict => (
          Icons.rule_rounded,
          tokens.warning,
          'A change needs review',
          'This was edited in two places. Choose which to keep.',
        ),
      SyncStatus.idle => (
          Icons.cloud_off_rounded,
          theme.colorScheme.onSurfaceVariant,
          'Not syncing',
          'Sign in to back up your meals.',
        ),
    };

    return E2eId(
      id: 'sync.status.${status.name}',
      child: Semantics(
        liveRegion: true,
        child: SgCard(
          variant: SgCardVariant.raised,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: SnapGrubDesignTokens.space40 + 8,
                height: SnapGrubDesignTokens.space40 + 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: status == SyncStatus.syncing
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color),
              ),
              const SizedBox(width: SnapGrubDesignTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: SnapGrubDesignTokens.space4),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConflictCard extends ConsumerStatefulWidget {
  const _ConflictCard({required this.command});

  final OutboxCommand command;

  @override
  ConsumerState<_ConflictCard> createState() => _ConflictCardState();
}

class _ConflictCardState extends ConsumerState<_ConflictCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final command = widget.command;
    return E2eId(
      id: 'sync.conflict.${command.id}',
      child: SgCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule_rounded, color: context.sg.warning),
                const SizedBox(width: SnapGrubDesignTokens.space8),
                Expanded(
                  child: Text(
                    Labels.outboxCommand(command.commandType),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  Labels.relative(command.updatedAt.toLocal()),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SnapGrubDesignTokens.space8),
            Text(
              'Changed on another device too. Send yours again, or keep the '
              'server version.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            Wrap(
              spacing: SnapGrubDesignTokens.space8,
              runSpacing: SnapGrubDesignTokens.space4,
              children: [
                E2eId(
                  id: 'sync.conflict.${command.id}.retry',
                  child: FilledButton.tonalIcon(
                    onPressed: _busy ? null : _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Send mine again'),
                  ),
                ),
                E2eId(
                  id: 'sync.conflict.${command.id}.discard',
                  child: TextButton(
                    onPressed: _busy ? null : _discard,
                    child: const Text('Discard mine'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      await ref.read(outboxRepositoryProvider).retryCommand(widget.command.id);
      ref.invalidate(conflictCommandsProvider);
      await ref.read(syncControllerProvider.notifier).syncNow();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Discard your change?',
      message: 'The server version will be kept.',
      confirmLabel: 'Discard',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(outboxRepositoryProvider)
          .discardCommand(widget.command.id);
      ref
        ..invalidate(conflictCommandsProvider)
        ..invalidate(unsyncedChangeCountProvider);
      if (mounted) showSgToast(context, 'Kept server version');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
