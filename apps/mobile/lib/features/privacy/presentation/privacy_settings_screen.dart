import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/data/repositories/profile_repository.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/privacy/data/local_data_repository.dart';
import 'package:snapgrub/features/privacy/data/privacy_remote_service.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';
import 'package:snapgrub/offline/sync/sync_status_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

const _pagePadding = EdgeInsets.only(bottom: SnapGrubDesignTokens.space32);

// ---------------------------------------------------------------------------
// Privacy hub
// ---------------------------------------------------------------------------

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull?.profile;
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Privacy & data',
      backLocation: '/settings',
      child: ListView(
        padding: _pagePadding,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Text(
              'Control what SnapGrub keeps, export your data, or delete it.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SgSectionHeader(title: 'Controls'),
          _RowGroup(children: [
            E2eId(
              id: 'privacy.ai_consent',
              child: AppRow(
                icon: Icons.psychology_alt_outlined,
                title: 'Improve food analysis',
                subtitle: profile?.aiImprovementConsent == true ? 'On' : 'Off',
                onTap: () => context.push('/settings/privacy/ai-consent'),
              ),
            ),
            E2eId(
              id: 'privacy.media_retention',
              child: AppRow(
                icon: Icons.photo_library_outlined,
                title: 'Photo storage',
                subtitle: profile?.cloudMediaStorage == false
                    ? 'Photos stay on this phone'
                    : 'Photos stored privately in the cloud',
                onTap: () => context.push('/settings/privacy/media-retention'),
              ),
            ),
          ]),
          const SgSectionHeader(title: 'Your data'),
          _RowGroup(children: [
            E2eId(
              id: 'privacy.export',
              child: AppRow(
                icon: Icons.file_download_outlined,
                title: 'Export data',
                subtitle: 'Download a JSON or CSV file',
                onTap: () => context.push('/settings/privacy/export'),
              ),
            ),
            E2eId(
              id: 'privacy.clear_local_data',
              child: AppRow(
                icon: Icons.cleaning_services_outlined,
                title: 'Clear this phone',
                subtitle: 'Remove data from this device only',
                onTap: () => context.push('/settings/privacy/clear-local-data'),
              ),
            ),
          ]),
          const SgSectionHeader(title: 'Account'),
          _RowGroup(children: [
            E2eId(
              id: 'privacy.delete_account',
              child: AppRow(
                icon: Icons.delete_forever_outlined,
                title: 'Delete account',
                subtitle: 'Permanently delete your account and data',
                destructive: true,
                onTap: () => context.push('/settings/privacy/delete-account'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// A card holding [AppRow]s separated by inset hairlines.
class _RowGroup extends StatelessWidget {
  const _RowGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      indent: SnapGrubDesignTokens.space12 +
          SnapGrubDesignTokens.space40 +
          SnapGrubDesignTokens.space12,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return SgCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) divider,
            children[i],
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared save logic for the two toggle screens
// ---------------------------------------------------------------------------

mixin _PrivacySettingsSaver<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool saving = false;

  Future<void> savePrivacy({
    bool? cloudMediaStorage,
    bool? saveOriginalPhotos,
    bool? aiImprovementConsent,
  }) async {
    final profile = ref.read(profileControllerProvider).valueOrNull?.profile;
    if (profile == null || saving) return;
    SgHaptics.tick();
    setState(() => saving = true);
    try {
      await ref.read(profileRepositoryProvider).savePrivacySettings(
            userId: profile.id,
            cloudMediaStorage: cloudMediaStorage ?? profile.cloudMediaStorage,
            saveOriginalPhotos:
                saveOriginalPhotos ?? profile.saveOriginalPhotos,
            aiImprovementConsent:
                aiImprovementConsent ?? profile.aiImprovementConsent,
          );
      ref.invalidate(profileControllerProvider);
    } catch (error) {
      if (mounted) {
        showSgToast(
          context,
          'Couldn’t save. ${friendlyError(error).message}',
          icon: Icons.info_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, SnapGrubDesignTokens.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: SnapGrubDesignTokens.iconMd,
              color: theme.colorScheme.primary),
          const SizedBox(width: SnapGrubDesignTokens.space12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI consent
// ---------------------------------------------------------------------------

class AIConsentScreen extends ConsumerStatefulWidget {
  const AIConsentScreen({super.key});

  @override
  ConsumerState<AIConsentScreen> createState() => _AIConsentScreenState();
}

class _AIConsentScreenState extends ConsumerState<AIConsentScreen>
    with _PrivacySettingsSaver {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).valueOrNull?.profile;
    final enabled = profile?.aiImprovementConsent ?? false;

    return AppScaffold(
      title: 'Improve food analysis',
      e2eId: 'scaffold.ai_consent',
      backLocation: '/settings/privacy',
      child: ListView(
        padding: _pagePadding,
        children: [
          const _Explainer(
            icon: Icons.psychology_alt_outlined,
            text: 'Let SnapGrub use your meal logs to improve food '
                'recognition. Off unless you turn it on.',
          ),
          SgCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              type: MaterialType.transparency,
              child: E2eId(
                id: 'privacy.ai_consent.toggle',
                child: SwitchListTile(
                  value: enabled,
                  title: const Text('Help improve food analysis'),
                  subtitle: Text(enabled ? 'On' : 'Off'),
                  onChanged: profile == null || saving
                      ? null
                      : (value) => savePrivacy(aiImprovementConsent: value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media retention
// ---------------------------------------------------------------------------

class MediaRetentionScreen extends ConsumerStatefulWidget {
  const MediaRetentionScreen({super.key});

  @override
  ConsumerState<MediaRetentionScreen> createState() =>
      _MediaRetentionScreenState();
}

class _MediaRetentionScreenState extends ConsumerState<MediaRetentionScreen>
    with _PrivacySettingsSaver {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).valueOrNull?.profile;
    final cloud = profile?.cloudMediaStorage ?? true;

    return AppScaffold(
      title: 'Photo storage',
      e2eId: 'scaffold.media_retention',
      backLocation: '/settings/privacy',
      child: ListView(
        padding: _pagePadding,
        children: [
          const _Explainer(
            icon: Icons.photo_library_outlined,
            text: 'Choose whether meal photos stay in your private cloud '
                'storage after analysis.',
          ),
          SgCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  E2eId(
                    id: 'privacy.media_retention.cloud_storage',
                    child: SwitchListTile(
                      value: cloud,
                      title: const Text('Cloud photo storage'),
                      subtitle: const Text(
                          'Keep analyzed photos in private storage for sync.'),
                      onChanged: profile == null || saving
                          ? null
                          : (value) => savePrivacy(cloudMediaStorage: value),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  E2eId(
                    id: 'privacy.media_retention.save_originals',
                    child: SwitchListTile(
                      value: profile?.saveOriginalPhotos ?? false,
                      title: const Text('Keep original photos'),
                      subtitle: const Text('Also keep full-size originals.'),
                      onChanged: profile == null || saving
                          ? null
                          : (value) => savePrivacy(saveOriginalPhotos: value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Export
// ---------------------------------------------------------------------------

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  String _exportType = 'nutrition_json';
  bool _loading = false;
  Map<String, dynamic>? _exportRequest;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = _exportType == 'journal_csv'
        ? 'Your meal log as a spreadsheet.'
        : 'All your data, for other apps.';
    return AppScaffold(
      title: 'Export data',
      e2eId: 'scaffold.export_data',
      backLocation: '/settings/privacy',
      child: ListView(
        padding: _pagePadding,
        children: [
          const _Explainer(
            icon: Icons.file_download_outlined,
            text: 'We’ll create a private download link. It expires, so save '
                'the file.',
          ),
          SgCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Format', style: theme.textTheme.titleMedium),
                const SizedBox(height: SnapGrubDesignTokens.space12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'nutrition_json', label: Text('JSON')),
                    ButtonSegment(value: 'journal_csv', label: Text('CSV')),
                  ],
                  selected: {_exportType},
                  onSelectionChanged: _loading
                      ? null
                      : (value) => setState(() => _exportType = value.single),
                ),
                const SizedBox(height: SnapGrubDesignTokens.space8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SnapGrubDesignTokens.space16),
                E2eId(
                  id: 'privacy.export.create',
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _requestExport,
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined),
                    label: Text(_loading ? 'Preparing…' : 'Create export'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: SnapGrubDesignTokens.space16),
            InlineError(message: _error!),
          ],
          if (_exportRequest != null) ...[
            const SizedBox(height: SnapGrubDesignTokens.space16),
            _ExportStatusCard(
              exportRequest: _exportRequest!,
              refreshing: _loading,
              onRefresh: _pollExport,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestExport() async {
    SgHaptics.tap();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await ref.read(privacyRemoteServiceProvider).createExport(
                clientRequestId: const Uuid().v4(),
                exportType: _exportType,
              );
      if (!mounted) return;
      setState(() {
        _exportRequest =
            Map<String, dynamic>.from(response['export_request'] as Map);
      });
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pollExport() async {
    final id = _exportRequest?['id'] as String?;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await ref.read(privacyRemoteServiceProvider).getExport(id);
      if (!mounted) return;
      setState(() {
        _exportRequest =
            Map<String, dynamic>.from(response['export_request'] as Map);
      });
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ExportStatusCard extends StatelessWidget {
  const _ExportStatusCard({
    required this.exportRequest,
    required this.refreshing,
    required this.onRefresh,
  });

  final Map<String, dynamic> exportRequest;
  final bool refreshing;
  final VoidCallback onRefresh;

  static String _normalizedStatus(String? status) => switch (status) {
        'completed' || 'ready' => 'completed',
        'failed' || 'error' => 'failed',
        'expired' => 'expired',
        _ => 'preparing',
      };

  static String _typeLabel(String? type) => switch (type) {
        'journal_csv' => 'CSV file',
        'nutrition_json' => 'JSON file',
        _ => 'Data file',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signedUrl = exportRequest['signed_url'] as String?;
    final status = _normalizedStatus(exportRequest['status'] as String?);
    final ready = status == 'completed' && signedUrl != null;
    final (tone, icon, headline) = switch (status) {
      'completed' => (
          StatusTone.positive,
          Icons.check_circle_rounded,
          'Export ready',
        ),
      'failed' => (
          StatusTone.attention,
          Icons.error_outline_rounded,
          'Export failed',
        ),
      'expired' => (
          StatusTone.neutral,
          Icons.timer_off_outlined,
          'Link expired',
        ),
      _ => (
          StatusTone.info,
          Icons.hourglass_top_rounded,
          'Preparing export…',
        ),
    };
    final expires = DateTime.tryParse('${exportRequest['expires_at'] ?? ''}');

    return Semantics(
      liveRegion: true,
      child: SgCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: E2eId(
                    id: 'privacy.export.status',
                    child: Text(headline, style: theme.textTheme.titleMedium),
                  ),
                ),
                StatusPill(
                  label: _typeLabel(exportRequest['export_type'] as String?),
                  icon: icon,
                  tone: tone,
                ),
              ],
            ),
            if (expires != null) ...[
              const SizedBox(height: SnapGrubDesignTokens.space4),
              Text(
                'Link expires ${DateFormat.MMMd().add_jm().format(expires.toLocal())}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: SnapGrubDesignTokens.space12),
            Wrap(
              spacing: SnapGrubDesignTokens.space8,
              runSpacing: SnapGrubDesignTokens.space4,
              children: [
                if (ready) ...[
                  FilledButton.tonalIcon(
                    onPressed: () => _open(context, signedUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: signedUrl));
                      SgHaptics.tick();
                      if (context.mounted) showSgToast(context, 'Link copied');
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy link'),
                  ),
                ],
                if (!ready && status == 'preparing')
                  TextButton.icon(
                    onPressed: refreshing ? null : onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String signedUrl) async {
    final uri = Uri.tryParse(signedUrl);
    if (uri == null) {
      showSgToast(context, 'This link isn’t valid. Create a new export.',
          icon: Icons.info_outline_rounded);
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showSgToast(context, 'Couldn’t open the link. Copy it instead.',
          icon: Icons.info_outline_rounded);
    }
  }
}

// ---------------------------------------------------------------------------
// Delete account
// ---------------------------------------------------------------------------

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _controller = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _confirmed => _controller.text.trim() == 'DELETE';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canDelete = _confirmed && !_deleting;
    return AppScaffold(
      title: 'Delete account',
      e2eId: 'scaffold.delete_account',
      backLocation: '/settings/privacy',
      child: ListView(
        padding: _pagePadding,
        children: [
          SgCard(
            color: scheme.errorContainer.withValues(alpha: .35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.error),
                    const SizedBox(width: SnapGrubDesignTokens.space8),
                    Expanded(
                      child: Text('This can’t be undone',
                          style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: SnapGrubDesignTokens.space8),
                Text(
                  'This permanently deletes:',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: SnapGrubDesignTokens.space4),
                for (final item in const [
                  'Your profile, goal and targets',
                  'Every meal you’ve logged',
                  'Meal photos and exports',
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: theme.textTheme.bodyLarge),
                        Expanded(
                          child: Text(item, style: theme.textTheme.bodyLarge),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/settings/privacy/export'),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Export your data first'),
            ),
          ),
          const SizedBox(height: SnapGrubDesignTokens.space8),
          E2eId(
            id: 'privacy.delete.confirmation',
            child: TextField(
              controller: _controller,
              enabled: !_deleting,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: SnapGrubDesignTokens.space16),
            InlineError(message: _error!),
          ],
          const SizedBox(height: SnapGrubDesignTokens.space16),
          E2eId(
            id: 'privacy.delete.submit',
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: canDelete ? _deleteAccount : null,
              icon: _deleting
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onError,
                      ),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(_deleting ? 'Deleting…' : 'Delete account'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    SgHaptics.warn();
    FocusScope.of(context).unfocus();
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(privacyRemoteServiceProvider).deleteAccount();
      await ref.read(localDataRepositoryProvider).clearAll();
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) context.go('/auth');
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = 'Account not deleted. ${friendlyError(error).message}');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Clear local data
// ---------------------------------------------------------------------------

class ClearLocalDataScreen extends ConsumerStatefulWidget {
  const ClearLocalDataScreen({super.key});

  @override
  ConsumerState<ClearLocalDataScreen> createState() =>
      _ClearLocalDataScreenState();
}

class _ClearLocalDataScreenState extends ConsumerState<ClearLocalDataScreen> {
  bool _clearing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unsynced = ref.watch(unsyncedChangeCountProvider).valueOrNull ?? 0;
    final syncing =
        ref.watch(syncControllerProvider).valueOrNull == SyncStatus.syncing;
    return AppScaffold(
      title: 'Clear this phone',
      e2eId: 'scaffold.clear_local_data',
      backLocation: '/settings/privacy',
      child: ListView(
        padding: _pagePadding,
        children: [
          const _Explainer(
            icon: Icons.cleaning_services_outlined,
            text: 'Removes SnapGrub data from this phone and signs you out. '
                'Synced data stays in your account.',
          ),
          if (unsynced > 0) ...[
            E2eId(
              id: 'privacy.clear_local_data.unsynced',
              child: SgCard(
                color: context.sg.warning.withValues(alpha: .12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            color: context.sg.warning),
                        const SizedBox(width: SnapGrubDesignTokens.space12),
                        Expanded(
                          child: Text(
                            '${Labels.count(unsynced, 'change')} '
                            '${unsynced == 1 ? 'hasn’t' : 'haven’t'} synced. '
                            'Clearing now will lose '
                            '${unsynced == 1 ? 'it' : 'them'}.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: syncing
                            ? null
                            : () async {
                                await ref
                                    .read(syncControllerProvider.notifier)
                                    .syncNow();
                                ref.invalidate(unsyncedChangeCountProvider);
                              },
                        child: Text(syncing ? 'Syncing…' : 'Sync first'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space16),
          ],
          E2eId(
            id: 'privacy.clear_local_data.submit',
            child: FilledButton.icon(
              onPressed: _clearing ? null : _clear,
              icon: _clearing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cleaning_services_outlined),
              label: Text(_clearing ? 'Clearing…' : 'Clear this phone'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clear() async {
    SgHaptics.warn();
    setState(() => _clearing = true);
    try {
      await ref.read(localDataRepositoryProvider).clearAll();
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) context.go('/auth');
    } catch (error) {
      if (mounted) {
        setState(() => _clearing = false);
        showSgToast(
          context,
          'Couldn’t clear this phone. ${friendlyError(error).message}',
          icon: Icons.info_outline_rounded,
        );
      }
    }
  }
}
