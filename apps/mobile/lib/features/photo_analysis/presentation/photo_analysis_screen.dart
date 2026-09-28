import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/router/nav.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/photo_analysis/data/photo_analysis_repository.dart';
import 'package:snapgrub/features/photo_analysis/presentation/photo_analysis_error.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

enum _Step { uploading, analyzing, failed }

/// Analyses one photo in the foreground and opens the estimate for review.
///
/// Progress reflects the repository's real stages (upload → analysis), not a
/// timer. Cancel abandons the result; nothing is saved from this screen.
class PhotoAnalysisScreen extends ConsumerStatefulWidget {
  const PhotoAnalysisScreen({required this.asset, super.key});

  final CaptureAsset asset;

  @override
  ConsumerState<PhotoAnalysisScreen> createState() =>
      _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends ConsumerState<PhotoAnalysisScreen> {
  _Step _step = _Step.uploading;
  FriendlyError? _error;

  /// Incremented per attempt and on cancel so stale results are ignored.
  int _run = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
  }

  @override
  void dispose() {
    _run++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = _step == _Step.failed;
    return AppScaffold(
      title: 'Analyzing photo',
      e2eId: 'scaffold.photo_analysis',
      onBack: _cancel,
      child: ListView(
        padding: const EdgeInsets.only(bottom: SnapGrubDesignTokens.space32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ScanBeam(
                active: !failed,
                child: Image.file(
                  File(widget.asset.localPath),
                  fit: BoxFit.cover,
                  semanticLabel: 'Your meal photo',
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: SnapGrubDesignTokens.space20),
          if (!failed) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _step == _Step.uploading
                    ? 'Uploading photo…'
                    : 'Identifying foods…',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space4),
            Text(
              'You can edit everything before saving.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space16),
            SgCard(
              padding: const EdgeInsets.symmetric(
                horizontal: SnapGrubDesignTokens.space16,
                vertical: SnapGrubDesignTokens.space8,
              ),
              child: Column(
                children: [
                  _StepRow(
                    label: 'Upload',
                    state: _step == _Step.uploading
                        ? _StepState.active
                        : _StepState.done,
                  ),
                  _StepRow(
                    label: 'Identify foods',
                    state: _step == _Step.analyzing
                        ? _StepState.active
                        : _StepState.upcoming,
                  ),
                  const _StepRow(
                    label: 'Review estimate',
                    state: _StepState.upcoming,
                  ),
                ],
              ),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space8),
            Center(
              child: E2eId(
                id: 'photo_analysis.cancel',
                child: TextButton(
                  onPressed: _cancel,
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ] else ...[
            E2eId(
              id: 'photo_analysis.error',
              child: Semantics(
                liveRegion: true,
                child: SgCard(
                  color: context.sg.warning.withValues(alpha: .10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _error?.offline == true
                            ? Icons.wifi_off_rounded
                            : Icons.image_search_rounded,
                        color: context.sg.warning,
                      ),
                      const SizedBox(width: SnapGrubDesignTokens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _error?.title ?? 'Couldn’t read this photo',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: SnapGrubDesignTokens.space4),
                            Text(
                              _error?.message ??
                                  'Try again or enter it manually.',
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
            ),
            const SizedBox(height: SnapGrubDesignTokens.space16),
            if (_error?.retryable ?? true)
              E2eId(
                id: 'photo_analysis.retry',
                child: FilledButton.icon(
                  onPressed: _analyze,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ),
            const SizedBox(height: SnapGrubDesignTokens.space8),
            E2eId(
              id: 'photo_analysis.manual',
              child: OutlinedButton.icon(
                onPressed: () {
                  SgHaptics.tap();
                  context.continueTo('/meal-editor');
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Enter manually'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _analyze() async {
    final run = ++_run;
    setState(() {
      _step = _Step.uploading;
      _error = null;
    });
    try {
      final profile =
          (await ref.read(profileControllerProvider.future)).profile;
      if (profile == null) throw StateError('Profile is not available.');
      final draft =
          await ref.read(photoAnalysisRepositoryProvider).analyzeAsset(
                asset: widget.asset,
                profile: profile,
                onStage: (stage) {
                  if (!mounted || run != _run) return;
                  setState(() => _step = stage == PhotoAnalysisStage.uploading
                      ? _Step.uploading
                      : _Step.analyzing);
                },
              );
      if (!mounted || run != _run) return;
      SgHaptics.logged();
      context.continueTo('/meal-editor', extra: draft);
    } catch (error) {
      if (!mounted || run != _run) return;
      SgHaptics.warn();
      setState(() {
        _step = _Step.failed;
        _error = photoAnalysisError(error);
      });
    }
  }

  void _cancel() {
    _run++;
    SgHaptics.tick();
    context.popOrGo('/home');
  }
}

enum _StepState { done, active, upcoming }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Widget leading = switch (state) {
      _StepState.done =>
        Icon(Icons.check_circle_rounded, size: 22, color: context.sg.success),
      _StepState.active => SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: scheme.primary,
          ),
        ),
      _StepState.upcoming => Icon(Icons.radio_button_unchecked_rounded,
          size: 22, color: scheme.outline),
    };
    return Semantics(
      label: '$label, ${switch (state) {
        _StepState.done => 'done',
        _StepState.active => 'in progress',
        _StepState.upcoming => 'waiting',
      }}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: SnapGrubDesignTokens.space8,
        ),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: leading)),
            const SizedBox(width: SnapGrubDesignTokens.space12),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: SgMotion.of(context).settle,
                style:
                    (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
                  color: state == _StepState.upcoming
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                  fontWeight: state == _StepState.active
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
