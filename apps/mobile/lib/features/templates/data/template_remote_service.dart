import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final templateRemoteServiceProvider = Provider<TemplateRemoteService>((ref) {
  return TemplateRemoteService(ref.watch(supabaseClientProvider));
});

class TemplateRemoteService {
  const TemplateRemoteService(this._client);

  final dynamic _client;

  bool get isConfigured => _client != null;

  Future<Map<String, dynamic>> upsert(Map<String, Object?> payload) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final clientRequestId = payload['client_request_id'] as String?;
    final response = await _client.functions.invoke(
      'meal-templates',
      method: HttpMethod.post,
      headers:
          clientRequestId == null ? null : {'Idempotency-Key': clientRequestId},
      body: payload,
    );
    return Map<String, dynamic>.from(
        (response.data as Map)['meal_template'] as Map);
  }

  Future<Map<String, dynamic>> softDelete({
    required String userId,
    required String clientId,
    required DateTime deletedAt,
    required String clientRequestId,
  }) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'meal-templates',
      method: HttpMethod.post,
      headers: {'Idempotency-Key': clientRequestId},
      body: {
        'client_request_id': clientRequestId,
        'user_id': userId,
        'client_id': clientId,
        'deleted_at': deletedAt.toUtc().toIso8601String(),
      },
    );
    return Map<String, dynamic>.from(
        (response.data as Map)['meal_template'] as Map);
  }
}
