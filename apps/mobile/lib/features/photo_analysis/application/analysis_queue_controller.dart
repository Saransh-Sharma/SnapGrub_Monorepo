import 'package:flutter/material.dart' show DateUtils, immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/photo_analysis/data/photo_analysis_repository.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:uuid/uuid.dart';

enum AnalysisJobStatus { uploading, analyzing, ready, failed }

/// One photo being analysed in the background. The user never waits on it:
/// the capture screen enqueues and returns to Today, where a pending card
/// shows the live state and turns into a reviewable draft.
@immutable
class AnalysisJob {
  const AnalysisJob({
    required this.id,
    required this.asset,
    required this.day,
    required this.status,
    required this.startedAt,
    this.draft,
    this.error,
  });

  final String id;
  final CaptureAsset asset;

  /// The user-day the meal belongs to.
  final DateTime day;
  final AnalysisJobStatus status;
  final DateTime startedAt;
  final MealDraft? draft;
  final Object? error;

  bool get isWorking =>
      status == AnalysisJobStatus.uploading ||
      status == AnalysisJobStatus.analyzing;

  AnalysisJob copyWith({
    AnalysisJobStatus? status,
    MealDraft? draft,
    Object? error,
    bool clearError = false,
  }) =>
      AnalysisJob(
        id: id,
        asset: asset,
        day: day,
        startedAt: startedAt,
        status: status ?? this.status,
        draft: draft ?? this.draft,
        error: clearError ? null : error ?? this.error,
      );
}

final analysisQueueProvider =
    NotifierProvider<AnalysisQueueController, List<AnalysisJob>>(
  AnalysisQueueController.new,
);

class AnalysisQueueController extends Notifier<List<AnalysisJob>> {
  @override
  List<AnalysisJob> build() => const [];

  List<AnalysisJob> jobsFor(DateTime day) => state
      .where((job) => DateUtils.isSameDay(job.day, day))
      .toList(growable: false);

  /// Starts analysing [asset] in the background and returns the job id.
  String enqueue(CaptureAsset asset, {required DateTime day}) {
    final job = AnalysisJob(
      id: const Uuid().v4(),
      asset: asset,
      day: DateUtils.dateOnly(day),
      status: AnalysisJobStatus.uploading,
      startedAt: DateTime.now(),
    );
    state = [...state, job];
    _run(job.id);
    return job.id;
  }

  Future<void> retry(String id) async {
    _update(
        id,
        (job) => job.copyWith(
              status: AnalysisJobStatus.uploading,
              clearError: true,
            ));
    await _run(id);
  }

  void dismiss(String id) {
    state = [
      for (final job in state)
        if (job.id != id) job
    ];
  }

  Future<void> _run(String id) async {
    final job = _find(id);
    if (job == null) return;
    try {
      final profile =
          (await ref.read(profileControllerProvider.future)).profile;
      if (profile == null) throw StateError('Profile is not available.');
      final draft =
          await ref.read(photoAnalysisRepositoryProvider).analyzeAsset(
                asset: job.asset,
                profile: profile,
                onStage: (stage) => _update(
                  id,
                  (current) => current.copyWith(
                    status: stage == PhotoAnalysisStage.uploading
                        ? AnalysisJobStatus.uploading
                        : AnalysisJobStatus.analyzing,
                  ),
                ),
              );
      _update(
          id,
          (current) => current.copyWith(
                status: AnalysisJobStatus.ready,
                draft: draft,
              ));
    } catch (error) {
      _update(
          id,
          (current) => current.copyWith(
                status: AnalysisJobStatus.failed,
                error: error,
              ));
    }
  }

  AnalysisJob? _find(String id) {
    for (final job in state) {
      if (job.id == id) return job;
    }
    return null;
  }

  void _update(String id, AnalysisJob Function(AnalysisJob job) change) {
    state = [
      for (final job in state)
        if (job.id == id) change(job) else job
    ];
  }
}
