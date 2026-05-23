import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/data/services/supabase_function_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final privacyRemoteServiceProvider = Provider<PrivacyRemoteService>((ref) {
  return PrivacyRemoteService(
    ref.watch(supabaseFunctionClientProvider),
    e2eMock: ref.watch(appConfigProvider).isE2eMock,
  );
});

class PrivacyRemoteService {
  const PrivacyRemoteService(this._functions, {this.e2eMock = false});

  final SnapGrubFunctionClient _functions;
  final bool e2eMock;

  bool get isConfigured => _functions.isConfigured;

  Future<Map<String, dynamic>> createExport({
    required String clientRequestId,
    required String exportType,
  }) async {
    if (e2eMock) {
      return _e2eExport(clientRequestId, exportType);
    }
    return _functions.invokeJson(
      'exports-create',
      method: HttpMethod.post,
      headers: {'Idempotency-Key': clientRequestId},
      body: {
        'client_request_id': clientRequestId,
        'export_type': exportType,
      },
    );
  }

  Future<Map<String, dynamic>> getExport(String exportRequestId) async {
    if (e2eMock) {
      return _e2eExport(exportRequestId, 'nutrition_json');
    }
    return _functions.invokeJson(
      'exports-create/$exportRequestId',
      method: HttpMethod.get,
    );
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    if (e2eMock) {
      return {'status': 'deleted'};
    }
    return _functions.invokeJson(
      'account-delete',
      method: HttpMethod.post,
      body: {'confirmation': 'DELETE'},
    );
  }

  Map<String, dynamic> _e2eExport(String id, String exportType) {
    return {
      'export_request': {
        'id': id,
        'status': 'completed',
        'export_type': exportType,
        'signed_url': 'https://example.invalid/snapgrub-e2e-export',
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 15))
            .toIso8601String(),
      },
    };
  }
}
