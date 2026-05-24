import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/data/repositories/profile_repository.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/privacy/data/local_data_repository.dart';
import 'package:snapgrub/features/privacy/data/privacy_remote_service.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull?.profile;

    return AppScaffold(
      title: 'Privacy',
      child: ListView(
        children: [
          E2eId(
            id: 'privacy.ai_consent',
            child: ListTile(
              leading: const Icon(Icons.psychology_alt_outlined),
              title: const Text('AI consent'),
              subtitle: Text(profile?.aiImprovementConsent == true
                  ? 'Improvement consent is on'
                  : 'Improvement consent is off'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/privacy/ai-consent'),
            ),
          ),
          E2eId(
            id: 'privacy.media_retention',
            child: ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Media retention'),
              subtitle: Text(profile?.cloudMediaStorage == true
                  ? 'Cloud media storage is on'
                  : 'Cloud media storage is off'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/privacy/media-retention'),
            ),
          ),
          const Divider(),
          E2eId(
            id: 'privacy.export',
            child: ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export data'),
              subtitle: const Text('Create a private JSON or CSV export'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/privacy/export'),
            ),
          ),
          E2eId(
            id: 'privacy.clear_local_data',
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Clear local data'),
              subtitle: const Text(
                  'Remove this device cache without deleting cloud data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/privacy/clear-local-data'),
            ),
          ),
          E2eId(
            id: 'privacy.delete_account',
            child: ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Delete account'),
              subtitle: const Text('Permanently delete your SnapGrub account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/privacy/delete-account'),
            ),
          ),
        ],
      ),
    );
  }
}

class AIConsentScreen extends ConsumerStatefulWidget {
  const AIConsentScreen({super.key});

  @override
  ConsumerState<AIConsentScreen> createState() => _AIConsentScreenState();
}

class _AIConsentScreenState extends ConsumerState<AIConsentScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).valueOrNull?.profile;
    final enabled = profile?.aiImprovementConsent ?? false;

    return AppScaffold(
      title: 'AI Consent',
      child: ListView(
        children: [
          E2eId(
            id: 'privacy.ai_consent.toggle',
            child: SwitchListTile(
              value: enabled,
              title: const Text('Help improve food analysis'),
              subtitle: const Text(
                  'Uses your explicit consent setting for future improvement workflows.'),
              onChanged: profile == null || _saving
                  ? null
                  : (value) => _save(
                        cloudMediaStorage: profile.cloudMediaStorage,
                        saveOriginalPhotos: profile.saveOriginalPhotos,
                        aiImprovementConsent: value,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save({
    required bool cloudMediaStorage,
    required bool saveOriginalPhotos,
    required bool aiImprovementConsent,
  }) async {
    final profile = ref.read(profileControllerProvider).valueOrNull?.profile;
    if (profile == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).savePrivacySettings(
            userId: profile.id,
            cloudMediaStorage: cloudMediaStorage,
            saveOriginalPhotos: saveOriginalPhotos,
            aiImprovementConsent: aiImprovementConsent,
          );
      ref.invalidate(profileControllerProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class MediaRetentionScreen extends ConsumerStatefulWidget {
  const MediaRetentionScreen({super.key});

  @override
  ConsumerState<MediaRetentionScreen> createState() =>
      _MediaRetentionScreenState();
}

class _MediaRetentionScreenState extends ConsumerState<MediaRetentionScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).valueOrNull?.profile;

    return AppScaffold(
      title: 'Media Retention',
      child: ListView(
        children: [
          E2eId(
            id: 'privacy.media_retention.cloud_storage',
            child: SwitchListTile(
              value: profile?.cloudMediaStorage ?? true,
              title: const Text('Cloud media storage'),
              subtitle: const Text(
                  'Allow meal images needed for analysis and sync to be stored privately.'),
              onChanged: profile == null || _saving
                  ? null
                  : (value) => _save(
                        cloudMediaStorage: value,
                        saveOriginalPhotos: profile.saveOriginalPhotos,
                        aiImprovementConsent: profile.aiImprovementConsent,
                      ),
            ),
          ),
          E2eId(
            id: 'privacy.media_retention.save_originals',
            child: SwitchListTile(
              value: profile?.saveOriginalPhotos ?? false,
              title: const Text('Save original photos'),
              subtitle: const Text(
                  'Keep original captures beyond the analysis workflow when enabled.'),
              onChanged: profile == null || _saving
                  ? null
                  : (value) => _save(
                        cloudMediaStorage: profile.cloudMediaStorage,
                        saveOriginalPhotos: value,
                        aiImprovementConsent: profile.aiImprovementConsent,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save({
    required bool cloudMediaStorage,
    required bool saveOriginalPhotos,
    required bool aiImprovementConsent,
  }) async {
    final profile = ref.read(profileControllerProvider).valueOrNull?.profile;
    if (profile == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).savePrivacySettings(
            userId: profile.id,
            cloudMediaStorage: cloudMediaStorage,
            saveOriginalPhotos: saveOriginalPhotos,
            aiImprovementConsent: aiImprovementConsent,
          );
      ref.invalidate(profileControllerProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

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
    return AppScaffold(
      title: 'Export Data',
      child: ListView(
        children: [
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
          const SizedBox(height: 16),
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
              label: Text(_loading ? 'Preparing export...' : 'Create export'),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_exportRequest != null) ...[
            const SizedBox(height: 24),
            _ExportStatusCard(
              exportRequest: _exportRequest!,
              onRefresh: _pollExport,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestExport() async {
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
      setState(() {
        _exportRequest =
            Map<String, dynamic>.from(response['export_request'] as Map);
      });
    } catch (error) {
      setState(() => _error = error.toString());
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
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ExportStatusCard extends StatelessWidget {
  const _ExportStatusCard({
    required this.exportRequest,
    required this.onRefresh,
  });

  final Map<String, dynamic> exportRequest;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final signedUrl = exportRequest['signed_url'] as String?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            E2eId(
              id: 'privacy.export.status',
              child: Text('Status: ${exportRequest['status']}',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Text('Type: ${exportRequest['export_type']}'),
            if (exportRequest['expires_at'] != null)
              Text('Expires: ${exportRequest['expires_at']}'),
            if (signedUrl != null) ...[
              const SizedBox(height: 12),
              SelectableText(signedUrl),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(signedUrl),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: signedUrl)),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy link'),
                    ),
                    TextButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final canDelete = _controller.text == 'DELETE' && !_deleting;
    return AppScaffold(
      title: 'Delete Account',
      child: ListView(
        children: [
          Text(
            'This permanently deletes your cloud account, saved meals, profile data, exports, and stored meal media.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          E2eId(
            id: 'privacy.delete.confirmation',
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 16),
          E2eId(
            id: 'privacy.delete.submit',
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: canDelete ? _deleteAccount : null,
              icon: _deleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(_deleting ? 'Deleting...' : 'Delete account'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
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
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

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
    return AppScaffold(
      title: 'Clear Local Data',
      child: ListView(
        children: [
          Text(
            'This removes cached SnapGrub data from this device. It does not delete your cloud account.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
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
              label: Text(_clearing ? 'Clearing...' : 'Clear local data'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clear() async {
    setState(() => _clearing = true);
    await ref.read(localDataRepositoryProvider).clearAll();
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/auth');
  }
}
