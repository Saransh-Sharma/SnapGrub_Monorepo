import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:snapgrub/app/e2e/e2e_data.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/profile/domain/profile_state.dart';

import '../../test/helpers/mobile_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(MockOnboardingProfileController.reset);

  testWidgets('mock auth onboarding manual meal privacy smoke', (tester) async {
    final harness = await MobileTestHarness.create(
      signedIn: false,
      profileComplete: false,
      overrides: [
        profileControllerProvider
            .overrideWith(MockOnboardingProfileController.new),
      ],
    );
    addTearDown(harness.dispose);

    await harness.pumpRouter(tester);
    expect(find.byKey(const ValueKey('screen.auth')), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'smoke@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump(const Duration(milliseconds: 500));

    await harness.container
        .read(profileControllerProvider.notifier)
        .completeOnboarding(
          'e2e-smoke-example-com',
          const OnboardingDraft(displayName: 'Smoke Tester'),
        );
    harness.container.read(appRouterProvider).go('/home');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Today'), findsWidgets);

    await harness.container.read(mealRepositoryProvider).saveDraft(
        testMealDraft(userId: 'e2e-smoke-example-com', title: 'Smoke dal'));
    harness.container.read(appRouterProvider).go('/journal');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Smoke dal'), findsOneWidget);

    harness.container.read(appRouterProvider).go('/progress');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('420 / 2000 kcal'), findsOneWidget);

    harness.container.read(appRouterProvider).go('/settings/privacy');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Export data'), findsOneWidget);

    harness.container
        .read(appRouterProvider)
        .go('/settings/privacy/clear-local-data');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(FilledButton, 'Clear local data'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('screen.auth')), findsOneWidget);
  });
}

class MockOnboardingProfileController extends ProfileController {
  static void reset() {}

  @override
  Future<ProfileState> build() async => const ProfileState.empty();

  @override
  Future<void> completeOnboarding(String userId, OnboardingDraft draft) async {
    state = AsyncData(
      ProfileState(
        profile: testProfile(userId: userId),
        activeGoal: testGoal(userId: userId),
        featureFlags: E2eData.enabledFlags,
        syncStatus: ProfileSyncStatus.pending,
      ),
    );
  }
}
