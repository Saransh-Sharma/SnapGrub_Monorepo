import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub/features/capture/domain/capture_asset.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final photoAnalysisRemoteServiceProvider =
    Provider<PhotoAnalysisRemoteService>((ref) {
  return PhotoAnalysisRemoteService(ref.watch(supabaseClientProvider));
});

class PhotoAnalysisRemoteService {
  const PhotoAnalysisRemoteService(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Future<void> uploadAsset(CaptureAsset asset) async {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured.');
    await client.storage.from(asset.storageBucket).uploadBinary(
          asset.storagePath,
          await File(asset.localPath).readAsBytes(),
          fileOptions: FileOptions(contentType: asset.mimeType, upsert: true),
        );
    if (asset.thumbLocalPath != null && asset.thumbStoragePath != null) {
      await client.storage.from('meal-thumbnails-private').uploadBinary(
            asset.thumbStoragePath!,
            await File(asset.thumbLocalPath!).readAsBytes(),
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
    }
  }

  Future<PhotoAnalysisResponseDto> createAnalysis(
      PhotoAnalysisCreateRequestDto request) async {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured.');
    final response = await client.functions.invoke(
      'analysis-photo-create',
      body: request.toJson(),
    );
    return PhotoAnalysisResponseDto.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<PhotoAnalysisResponseDto> getAnalysis(String analysisId) async {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured.');
    final response = await client.functions.invoke(
      'analysis-get/$analysisId',
      method: HttpMethod.get,
    );
    return PhotoAnalysisResponseDto.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }
}
