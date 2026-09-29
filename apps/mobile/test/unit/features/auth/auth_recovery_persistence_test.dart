import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/app/env/app_config.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('password recovery marker stores and clears by user id', () async {
    await AuthController.storePasswordRecoveryUserForTesting('user-1');

    expect(await AuthController.isStoredPasswordRecoveryUser('user-1'), isTrue);
    expect(
        await AuthController.isStoredPasswordRecoveryUser('user-2'), isFalse);

    await AuthController.clearPasswordRecoveryUserForTesting();

    expect(
        await AuthController.isStoredPasswordRecoveryUser('user-1'), isFalse);
  });

  test('sign out clears password recovery marker', () async {
    await AuthController.storePasswordRecoveryUserForTesting('user-1');
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            environment: 'dev',
            supabaseUrl: '',
            supabaseAnonKey: '',
            e2eEnabled: true,
            e2eBackend: 'mock',
            e2eAuth: 'password',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).signOut();

    expect(
        await AuthController.isStoredPasswordRecoveryUser('user-1'), isFalse);
  });
}
