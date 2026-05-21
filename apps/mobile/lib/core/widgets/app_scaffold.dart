import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    this.actions,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncControllerProvider).valueOrNull ?? SyncStatus.idle;
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: Column(
          children: [
            if (syncStatus == SyncStatus.pending ||
                syncStatus == SyncStatus.syncing ||
                syncStatus == SyncStatus.failed ||
                syncStatus == SyncStatus.conflict)
              _SyncBanner(status: syncStatus),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (status) {
      SyncStatus.syncing => (Icons.sync, 'Syncing changes...'),
      SyncStatus.pending => (Icons.cloud_queue_outlined, 'Saved locally. Sync pending.'),
      SyncStatus.failed => (Icons.error_outline, 'Sync needs a retry.'),
      SyncStatus.conflict => (Icons.report_problem_outlined, 'Sync conflict needs review.'),
      _ => (Icons.cloud_done_outlined, ''),
    };
    final color = status == SyncStatus.conflict || status == SyncStatus.failed
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.secondaryContainer;
    return Material(
      color: color,
      child: InkWell(
        onTap: () => context.go('/sync'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
