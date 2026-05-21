import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';

final customFoodRemoteServiceProvider = Provider<CustomFoodRemoteService>((ref) {
  return CustomFoodRemoteService(ref.watch(supabaseClientProvider));
});

class CustomFoodRemoteService {
  const CustomFoodRemoteService(this._client);

  final dynamic _client;

  bool get isConfigured => _client != null;

  Future<Map<String, dynamic>> upsert(Map<String, Object?> payload) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client
        .from('custom_foods')
        .upsert(payload, onConflict: 'user_id,client_id')
        .select()
        .single();
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> softDelete({
    required String userId,
    required String clientId,
    required DateTime deletedAt,
  }) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client
        .from('custom_foods')
        .update({'deleted_at': deletedAt.toUtc().toIso8601String()})
        .eq('user_id', userId)
        .eq('client_id', clientId)
        .select()
        .single();
    return Map<String, dynamic>.from(response as Map);
  }
}
