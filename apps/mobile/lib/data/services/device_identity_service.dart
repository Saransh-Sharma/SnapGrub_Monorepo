import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  return const DeviceIdentityService();
});

class DeviceIdentityService {
  const DeviceIdentityService();

  static const _installIdKey = 'snapgrub.install_id';

  Future<String> installId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final created = const Uuid().v4();
    await prefs.setString(_installIdKey, created);
    return created;
  }
}
