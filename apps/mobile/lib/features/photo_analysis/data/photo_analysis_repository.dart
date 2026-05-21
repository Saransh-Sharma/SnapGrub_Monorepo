import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/features/capture/data/capture_asset_repository.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub/features/meal_editor/data/meal_draft_mapper.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/photo_analysis/data/photo_analysis_remote_service.dart';
import 'package:snapgrub/features/profile/domain/profile.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:uuid/uuid.dart';

final photoAnalysisRepositoryProvider = Provider<PhotoAnalysisRepository>((ref) {
  return PhotoAnalysisRepository(
    remote: ref.watch(photoAnalysisRemoteServiceProvider),
    assets: ref.watch(captureAssetRepositoryProvider),
  );
});

class PhotoAnalysisRepository {
  const PhotoAnalysisRepository({
    required PhotoAnalysisRemoteService remote,
    required CaptureAssetRepository assets,
  })  : _remote = remote,
        _assets = assets;

  final PhotoAnalysisRemoteService _remote;
  final CaptureAssetRepository _assets;

  Future<MealDraft> analyzeAsset({
    required CaptureAsset asset,
    required UserProfile profile,
    String? mealTypeHint,
    String? userHintText,
  }) async {
    if (!_remote.isConfigured) {
      throw StateError('Supabase is not configured.');
    }
    await _remote.uploadAsset(asset);
    await _assets.markUploaded(asset.id);
    final response = await _remote.createAnalysis(
      PhotoAnalysisCreateRequestDto(
        clientRequestId: const Uuid().v4(),
        storageBucket: asset.storageBucket,
        storagePath: asset.storagePath,
        thumbStoragePath: asset.thumbStoragePath,
        assetSha256: asset.sha256,
        mimeType: asset.mimeType,
        width: asset.width,
        height: asset.height,
        sizeBytes: asset.sizeBytes,
        mealTypeHint: mealTypeHint,
        locale: profile.locale,
        timezone: profile.timezone,
        cuisineHints: profile.cuisinePreferences,
        userHintText: userHintText,
      ),
    );
    if (response.status != 'completed' || response.result == null) {
      throw StateError(response.errorCode ?? 'Photo analysis did not complete.');
    }
    if (response.assetId == null) {
      throw StateError('Photo analysis did not return an asset id.');
    }
    return mealDraftFromEditableDto(
      userId: asset.userId,
      source: MealSource.photo,
      result: response.result!,
      provenanceType: 'ai_photo',
      analysisJobId: response.analysisId,
      photoAssetId: response.assetId,
    );
  }
}
