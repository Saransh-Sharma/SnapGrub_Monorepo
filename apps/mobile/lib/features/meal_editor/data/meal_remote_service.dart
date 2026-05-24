import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_function_client.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final mealRemoteServiceProvider = Provider<MealRemoteService>((ref) {
  return MealRemoteService(ref.watch(supabaseFunctionClientProvider));
});

class MealRemoteService {
  const MealRemoteService(this._functions);

  final SnapGrubFunctionClient _functions;

  bool get isConfigured => _functions.isConfigured;

  Future<MealListResponseDto> listMeals({String? day}) async {
    final response = await _functions.invokeJson(
      day == null ? 'meals' : 'meals?day=$day',
      method: HttpMethod.get,
    );
    return MealListResponseDto.fromJson(response);
  }

  Future<MealWriteResponseDto> createMeal({
    required String clientRequestId,
    required MealWriteRequestDto request,
  }) async {
    final response = await _functions.invokeJson(
      'meals',
      headers: {'Idempotency-Key': clientRequestId},
      body: request.toJson(),
    );
    return MealWriteResponseDto.fromJson(response);
  }

  Future<MealWriteResponseDto> updateMeal({
    required String mealId,
    required String clientRequestId,
    required MealWriteRequestDto request,
  }) async {
    final response = await _functions.invokeJson(
      'meals/$mealId',
      method: HttpMethod.patch,
      headers: {'Idempotency-Key': clientRequestId},
      body: request.toJson(),
    );
    return MealWriteResponseDto.fromJson(response);
  }

  Future<MealWriteResponseDto> deleteMeal({
    required String mealId,
    required String clientRequestId,
    int? expectedRevision,
  }) async {
    final response = await _functions.invokeJson(
      'meals/$mealId',
      method: HttpMethod.delete,
      headers: {'Idempotency-Key': clientRequestId},
      body: {
        'client_request_id': clientRequestId,
        if (expectedRevision != null) 'expected_revision': expectedRevision,
      },
    );
    return MealWriteResponseDto.fromJson(response);
  }
}
