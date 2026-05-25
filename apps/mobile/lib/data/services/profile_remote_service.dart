import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/services/supabase_function_client.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRemoteServiceProvider = Provider<ProfileRemoteService>((ref) {
  return ProfileRemoteService(ref.watch(supabaseFunctionClientProvider));
});

class ProfileRemoteService {
  const ProfileRemoteService(this._functions);

  final SnapGrubFunctionClient _functions;

  bool get isConfigured => _functions.isConfigured;

  Future<ProfileBootstrapResponseDto> bootstrap({
    required ProfileBootstrapRequestDto request,
  }) async {
    final response = await _functions.invokeJson(
      'profile-bootstrap',
      body: request.toJson(),
    );
    return ProfileBootstrapResponseDto.fromJson(response);
  }

  Future<SettingsPatchResponseDto> patchSettings({
    required String clientRequestId,
    required SettingsPatchRequestDto request,
  }) async {
    final response = await _functions.invokeJson(
      'settings-patch',
      method: HttpMethod.patch,
      headers: {'Idempotency-Key': clientRequestId},
      body: request.toJson(),
    );
    return SettingsPatchResponseDto.fromJson(response);
  }
}
