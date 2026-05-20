import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

void main() {
  test('signed-out auth state returns empty profile state', () async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(SignedOutAuthController.new),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(profileControllerProvider.future);

    expect(state.profile, isNull);
    expect(state.activeGoal, isNull);
    expect(state.featureFlags, isEmpty);
  });
}

class SignedOutAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.signedOut();
}
