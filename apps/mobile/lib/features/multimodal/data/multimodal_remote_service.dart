import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub/features/meal_editor/data/meal_draft_mapper.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/profile/domain/profile.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final multimodalRemoteServiceProvider = Provider<MultimodalRemoteService>((ref) {
  return MultimodalRemoteService(ref.watch(supabaseClientProvider));
});

class MultimodalRemoteService {
  const MultimodalRemoteService(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Future<MealDraft> parseText({
    required String userId,
    required UserProfile profile,
    required String text,
  }) async {
    final response = await _invokeMultimodal(
      'analysis-text-create',
      TextAnalysisCreateRequestDto(
        clientRequestId: const Uuid().v4(),
        text: text,
        locale: profile.locale,
        timezone: profile.timezone,
        cuisineHints: profile.cuisinePreferences,
      ).toJson(),
    );
    return mealDraftFromEditableDto(
      result: response.result,
      userId: userId,
      source: MealSource.text,
      provenanceType: 'text_parser',
    );
  }

  Future<MealDraft> parseVoiceTranscript({
    required String userId,
    required UserProfile profile,
    required String transcript,
    double? transcriptConfidence,
  }) async {
    final response = await _invokeMultimodal(
      'analysis-voice-create',
      VoiceAnalysisCreateRequestDto(
        clientRequestId: const Uuid().v4(),
        transcript: transcript,
        transcriptConfidence: transcriptConfidence,
        locale: profile.locale,
        timezone: profile.timezone,
        cuisineHints: profile.cuisinePreferences,
      ).toJson(),
    );
    return mealDraftFromEditableDto(
      result: response.result,
      userId: userId,
      source: MealSource.voice,
      provenanceType: 'voice_parser',
    );
  }

  Future<MealDraft> parseLabelText({
    required String userId,
    required UserProfile profile,
    required String ocrText,
    String? barcode,
    String? productNameHint,
  }) async {
    final response = await _invokeMultimodal(
      'analysis-label-create',
      LabelAnalysisCreateRequestDto(
        clientRequestId: const Uuid().v4(),
        ocrText: ocrText,
        barcode: barcode,
        productNameHint: productNameHint,
        locale: profile.locale,
        timezone: profile.timezone,
      ).toJson(),
    );
    return mealDraftFromEditableDto(
      result: response.result,
      userId: userId,
      source: MealSource.barcode,
      provenanceType: 'label_ocr',
    );
  }

  Future<BarcodeResolveResponseDto> resolveBarcode({
    required String barcode,
    required UserProfile profile,
  }) async {
    final client = _requireClient();
    final response = await client.functions.invoke(
      'barcode-resolve',
      body: BarcodeResolveRequestDto(
        barcode: barcode,
        locale: profile.locale,
        timezone: profile.timezone,
        region: profile.countryCode,
      ).toJson(),
    );
    return BarcodeResolveResponseDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  MealDraft barcodeDraft({
    required String userId,
    required BarcodeResolveResponseDto response,
  }) {
    final draft = response.draft;
    if (draft == null) {
      throw StateError(response.fallbackReason ?? 'Barcode was not found.');
    }
    return mealDraftFromEditableDto(
      result: draft,
      userId: userId,
      source: MealSource.barcode,
      provenanceType: 'barcode',
    );
  }

  Future<MultimodalAnalysisResponseDto> _invokeMultimodal(String functionName, JsonMap body) async {
    final client = _requireClient();
    final response = await client.functions.invoke(functionName, body: body);
    return MultimodalAnalysisResponseDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured.');
    return client;
  }
}
