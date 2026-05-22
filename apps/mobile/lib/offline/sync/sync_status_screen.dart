import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/offline/outbox/outbox_repository.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

final conflictCommandsProvider = FutureProvider.autoDispose((ref) async {
  final auth = await ref.watch(authControllerProvider.future);
  final userId = auth.userId;
  if (userId == null) return const [];
  return ref.watch(outboxRepositoryProvider).conflictCommands(userId);
});

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        ref.watch(syncControllerProvider).valueOrNull ?? SyncStatus.idle;
    final conflicts = ref.watch(conflictCommandsProvider);
    return AppScaffold(
      title: 'Sync',
      actions: [
        IconButton(
          tooltip: 'Sync now',
          onPressed: () => ref.read(syncControllerProvider.notifier).syncNow(),
          icon: const Icon(Icons.sync),
        ),
      ],
      child: ListView(
        children: [
          ListTile(
            leading: Icon(_iconFor(status)),
            title: Text(_titleFor(status)),
            subtitle: Text(_subtitleFor(status)),
          ),
          const SizedBox(height: 12),
          Text('Needs attention',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          conflicts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(error.toString()),
            data: (items) {
              if (items.isEmpty) return const Text('No sync conflicts.');
              return Column(
                children: [
                  for (final command in items)
                    Card(
                      child: ListTile(
                        title: Text(command.commandType),
                        subtitle:
                            Text(command.lastError ?? 'Conflict needs review.'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Retry',
                              onPressed: () async {
                                await ref
                                    .read(outboxRepositoryProvider)
                                    .retryCommand(command.id);
                                ref.invalidate(conflictCommandsProvider);
                                await ref
                                    .read(syncControllerProvider.notifier)
                                    .syncNow();
                              },
                              icon: const Icon(Icons.refresh),
                            ),
                            IconButton(
                              tooltip: 'Discard local command',
                              onPressed: () async {
                                await ref
                                    .read(outboxRepositoryProvider)
                                    .discardCommand(command.id);
                                ref.invalidate(conflictCommandsProvider);
                              },
                              icon: const Icon(Icons.check),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _iconFor(SyncStatus status) => switch (status) {
        SyncStatus.syncing => Icons.sync,
        SyncStatus.synced => Icons.cloud_done_outlined,
        SyncStatus.pending => Icons.cloud_queue_outlined,
        SyncStatus.failed => Icons.error_outline,
        SyncStatus.conflict => Icons.report_problem_outlined,
        SyncStatus.idle => Icons.cloud_off_outlined,
      };

  String _titleFor(SyncStatus status) => switch (status) {
        SyncStatus.syncing => 'Syncing',
        SyncStatus.synced => 'Synced',
        SyncStatus.pending => 'Pending changes',
        SyncStatus.failed => 'Sync failed',
        SyncStatus.conflict => 'Conflict found',
        SyncStatus.idle => 'Sync idle',
      };

  String _subtitleFor(SyncStatus status) => switch (status) {
        SyncStatus.syncing =>
          'Saving pending changes and refreshing server state.',
        SyncStatus.synced => 'Local data matches the latest server state.',
        SyncStatus.pending =>
          'Changes are saved locally and will sync when network is available.',
        SyncStatus.failed => 'Some changes will retry automatically.',
        SyncStatus.conflict => 'Review the affected commands below.',
        SyncStatus.idle => 'Sign in to sync data.',
      };
}
