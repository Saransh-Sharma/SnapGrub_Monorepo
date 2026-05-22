import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/photo_analysis/data/photo_analysis_repository.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

class PhotoAnalysisScreen extends ConsumerStatefulWidget {
  const PhotoAnalysisScreen({required this.asset, super.key});

  final CaptureAsset asset;

  @override
  ConsumerState<PhotoAnalysisScreen> createState() =>
      _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends ConsumerState<PhotoAnalysisScreen> {
  static const _stages = [
    'Checking the photo...',
    'Identifying foods...',
    'Estimating portions...',
    'Preparing your editable log...',
  ];

  Timer? _timer;
  int _stage = 0;
  bool _started = false;
  bool _failed = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() =>
          _stage = ((_stage + 1).clamp(0, _stages.length - 1) as num).toInt());
    });
    _run();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Photo analysis',
      child: ListView(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(widget.asset.localPath),
              fit: BoxFit.cover,
              height: 260,
              errorBuilder: (_, __, ___) => Container(
                height: 260,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.restaurant, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_failed) ...[
            LinearProgressIndicator(value: (_stage + 1) / _stages.length),
            const SizedBox(height: 12),
            Text(_stages[_stage],
                style: Theme.of(context).textTheme.titleMedium),
          ] else ...[
            Text('Analysis needs attention',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error ??
                'The photo could not be analyzed. You can retry or log it manually.'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/meal-editor'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Manual'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _run() async {
    setState(() {
      _failed = false;
      _error = null;
      _stage = 0;
    });
    try {
      final profile =
          (await ref.read(profileControllerProvider.future)).profile;
      if (profile == null) throw StateError('Profile is not available.');
      final draft =
          await ref.read(photoAnalysisRepositoryProvider).analyzeAsset(
                asset: widget.asset,
                profile: profile,
              );
      if (mounted) context.go('/meal-editor', extra: draft);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _error = error.toString();
      });
    }
  }

  void _retry() {
    _run();
  }
}
