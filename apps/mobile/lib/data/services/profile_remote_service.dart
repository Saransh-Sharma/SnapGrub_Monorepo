import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_client_provider.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRemoteServiceProvider = Provider<ProfileRemoteService>((ref) {
  return ProfileRemoteService(ref.watch(supabaseClientProvider));
});

class ProfileRemoteService {
  const ProfileRemoteService(this._client);

  final dynamic _client;

  bool get isConfigured => _client != null;

  Future<ProfileBootstrapResponseDto> bootstrap({
    required ProfileBootstrapRequestDto request,
  }) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'profile-bootstrap',
      body: request.toJson(),
    );
    return ProfileBootstrapResponseDto.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SettingsPatchResponseDto> patchSettings({
    required String clientRequestId,
    required SettingsPatchRequestDto request,
  }) async {
    if (_client == null) throw StateError('Supabase is not configured.');
    final response = await _client.functions.invoke(
      'settings-patch',
      method: HttpMethod.patch,
      headers: {'Idempotency-Key': clientRequestId},
      body: request.toJson(),
    );
    return SettingsPatchResponseDto.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
