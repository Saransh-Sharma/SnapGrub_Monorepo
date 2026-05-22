import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final privacyRemoteServiceProvider = Provider<PrivacyRemoteService>((ref) {
  return PrivacyRemoteService(ref.watch(supabaseClientProvider));
});

class PrivacyRemoteService {
  const PrivacyRemoteService(this._client);

  final dynamic _client;

  bool get isConfigured => _client != null;

  Future<Map<String, dynamic>> createExport({
    required String clientRequestId,
    required String exportType,
  }) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'exports-create',
      method: HttpMethod.post,
      headers: {'Idempotency-Key': clientRequestId},
      body: {
        'client_request_id': clientRequestId,
        'export_type': exportType,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getExport(String exportRequestId) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'exports-create/$exportRequestId',
      method: HttpMethod.get,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'account-delete',
      method: HttpMethod.post,
      body: {'confirmation': 'DELETE'},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
