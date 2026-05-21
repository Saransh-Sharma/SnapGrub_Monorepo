import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';

final templateRemoteServiceProvider = Provider<TemplateRemoteService>((ref) {
  return TemplateRemoteService(ref.watch(supabaseClientProvider));
});

class TemplateRemoteService {
  const TemplateRemoteService(this._client);

  final dynamic _client;

  bool get isConfigured => _client != null;

  Future<Map<String, dynamic>> upsert(Map<String, Object?> payload) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client
        .from('meal_templates')
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
        .from('meal_templates')
        .update({'deleted_at': deletedAt.toUtc().toIso8601String()})
        .eq('user_id', userId)
        .eq('client_id', clientId)
        .select()
        .single();
    return Map<String, dynamic>.from(response as Map);
  }
}
