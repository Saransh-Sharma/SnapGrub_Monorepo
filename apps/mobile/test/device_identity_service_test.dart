import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/data/services/device_identity_service.dart';

void main() {
  test('install id is stable after first creation', () async {
    SharedPreferences.setMockInitialValues({});
    const service = DeviceIdentityService();

    final first = await service.installId();
    final second = await service.installId();

    expect(first, isNotEmpty);
    expect(second, first);
  });
}
