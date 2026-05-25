import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/network/snapgrub_api_exception.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseFunctionClientProvider = Provider<SnapGrubFunctionClient>((ref) {
  return SnapGrubFunctionClient(ref.watch(supabaseClientProvider));
});

class SnapGrubFunctionClient {
  const SnapGrubFunctionClient(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Future<JsonMap> invokeJson(
    String functionName, {
    HttpMethod method = HttpMethod.post,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = _client;
    if (client == null) {
      throw SnapGrubApiException(
        status: 503,
        code: 'NOT_CONFIGURED',
        message: 'Supabase is not configured.',
        userMessage: 'This feature is unavailable in this build.',
        retryable: false,
        requestId: '',
      );
    }
    try {
      final response = await client.functions.invoke(
        functionName,
        method: method,
        headers: headers,
        body: body,
      );
      return _jsonMap(response.data, status: response.status);
    } on FunctionException catch (error) {
      final data = error.details;
      if (data is Map) {
        final json = Map<String, dynamic>.from(data);
        if (json['code'] is String && json['request_id'] is String) {
          throw SnapGrubApiException.fromEnvelope(
            ErrorEnvelope.fromJson(json),
            status: error.status,
          );
        }
      }
      throw SnapGrubApiException(
        status: error.status,
        code: 'UNKNOWN',
        message: error.toString(),
        userMessage: 'Something went wrong. Please try again.',
        retryable: error.status >= 500,
        requestId: '',
      );
    }
  }

  JsonMap _jsonMap(Object? data, {required int status}) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw SnapGrubApiException(
      status: status,
      code: 'INVALID_RESPONSE',
      message: 'Function returned a non-object response.',
      userMessage: 'Something went wrong. Please try again.',
      retryable: true,
      requestId: '',
    );
  }
}
