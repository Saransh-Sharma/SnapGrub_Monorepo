import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final mealVisualRemoteServiceProvider =
    Provider<MealVisualRemoteService>((ref) {
  return MealVisualRemoteService(ref.watch(supabaseClientProvider));
});

class MealVisualRemoteService {
  const MealVisualRemoteService(this._client);

  final dynamic _client;

  bool get isConfigured => _client != null;

  Future<Map<String, dynamic>> create({
    required Map<String, Object?> payload,
    required String clientRequestId,
  }) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'meal-visuals',
      method: HttpMethod.post,
      headers: {'Idempotency-Key': clientRequestId},
      body: {...payload, 'client_request_id': clientRequestId},
    );
    return Map<String, dynamic>.from(
      (response.data as Map)['meal_visual'] as Map,
    );
  }
}
