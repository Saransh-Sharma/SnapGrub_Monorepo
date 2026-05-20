import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final mealRemoteServiceProvider = Provider<MealRemoteService>((ref) {
  return MealRemoteService(ref.watch(supabaseClientProvider));
});

class MealRemoteService {
  const MealRemoteService(this._client);

  final dynamic _client;

  bool get isConfigured => _client != null;

  Future<MealListResponseDto> listMeals({String? day}) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      day == null ? 'meals' : 'meals?day=$day',
      method: HttpMethod.get,
    );
    return MealListResponseDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<MealWriteResponseDto> createMeal({
    required String clientRequestId,
    required MealWriteRequestDto request,
  }) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'meals',
      headers: {'Idempotency-Key': clientRequestId},
      body: request.toJson(),
    );
    return MealWriteResponseDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<MealWriteResponseDto> updateMeal({
    required String mealId,
    required String clientRequestId,
    required MealWriteRequestDto request,
  }) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'meals/$mealId',
      method: HttpMethod.patch,
      headers: {'Idempotency-Key': clientRequestId},
      body: request.toJson(),
    );
    return MealWriteResponseDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<MealWriteResponseDto> deleteMeal({
    required String mealId,
    required String clientRequestId,
    int? expectedRevision,
  }) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'meals/$mealId',
      method: HttpMethod.delete,
      headers: {'Idempotency-Key': clientRequestId},
      body: {
        'client_request_id': clientRequestId,
        if (expectedRevision != null) 'expected_revision': expectedRevision,
      },
    );
    return MealWriteResponseDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
