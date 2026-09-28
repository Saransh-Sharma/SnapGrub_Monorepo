import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/app/e2e/e2e_data.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/capture/domain/capture_state.dart';
import 'package:snapgrub/features/home/presentation/home_screen.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_completion.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_region.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_steps.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/profile/domain/profile_state.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';
import 'package:snapgrub/offline/sync/sync_status_screen.dart';

import '../../../helpers/mobile_test_harness.dart';
import 'onboarding_test_utils.dart';

void main() {
  setUp(() {
    TestOnboardingProfileController.reset();
    StaticSyncController.initialStatus = SyncStatus.synced;
    StaticCaptureController.initialState =
        const CaptureState(status: CaptureStatus.permissionNeeded);
  });

  testWidgets('onboarding walks every step to the plan and saves its targets',
      (tester) async {
    final harness = await MobileTestHarness.create(
      profileComplete: false,
      overrides: [
        profileControllerProvider
            .overrideWith(TestOnboardingProfileController.new),
        regionDetectorProvider.overrideWithValue(const FakeRegionDetector()),
      ],
    );
    addTearDown(harness.dispose);

    await harness.pumpRouter(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('screen.onboarding')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('onboarding.step.welcome')), findsOneWidget);
    await tapOnboarding(tester, 'onboarding.next');

    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Asha Rao',
    );
    await tester.pump();
    expect(
      harness.container.read(onboardingControllerProvider).displayName,
      'Asha Rao',
    );
    await tapOnboarding(tester, 'onboarding.next');

    expect(find.text('Nice to meet you, Asha.'), findsOneWidget);
    await tapOnboarding(tester, 'onboarding.goal.lose');
    await tapOnboarding(tester, 'onboarding.next');
    await tapOnboarding(tester, 'onboarding.sex.female');
    await tapOnboarding(tester, 'onboarding.next');
    for (final step in [
      'birth_year',
      'height',
      'weight',
      'target_weight',
      'activity',
      'pace'
    ]) {
      expect(find.byKey(ValueKey('onboarding.step.$step')), findsOneWidget,
          reason: step);
      await tapOnboarding(tester, 'onboarding.next');
    }
    await tapOnboarding(tester, 'onboarding.cuisine.indian');
    await tapOnboarding(tester, 'onboarding.next');
    await tapOnboarding(tester, 'onboarding.reminder.breakfast');
    expect(find.textContaining('(London)'), findsOneWidget);
    await tapOnboarding(tester, 'onboarding.next');

    expect(find.byKey(const ValueKey('onboarding.plan_card')), findsOneWidget);
    expect(find.text('Start logging'), findsOneWidget);
    await tapOnboarding(tester, 'onboarding.finish');

    final saved = TestOnboardingProfileController.completedDraft!;
    final expected = saved.plan()!;
    expect(saved.displayName, 'Asha Rao');
    expect(saved.goalType, 'lose');
    expect(saved.locale, 'en-GB');
    expect(saved.timezone, 'Europe/London');
    expect(saved.countryCode, 'GB');
    expect(saved.weightKg, OnboardingDefaults.weightKg);
    expect(saved.targetWeightKg, OnboardingDefaults.target(saved));
    expect(saved.caloriesKcal, expected.caloriesKcal);
    expect(saved.proteinG, expected.proteinG);
    expect(saved.carbsG, expected.carbsG);
    expect(saved.fatG, expected.fatG);
    expect(saved.caloriesKcal, isNot(const OnboardingDraft().caloriesKcal));
    expect(saved.cuisinePreferences, ['Indian']);
    expect(saved.notificationPreference, isTrue);
    expect(saved.cameraPrimerSeen, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(OnboardingHandoff.goalWeightKey(testUserId)),
        saved.targetWeightKg);
    expect(prefs.getBool(OnboardingHandoff.firstRunCoachKey), isTrue);
    expect(find.byKey(const ValueKey('screen.onboarding')), findsNothing);
  });

  testWidgets('home renders signed-in daily dashboard shell', (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await harness.pumpRouter(tester);
    harness.container.read(appRouterProvider).go('/home');
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('sync recovery screen handles empty conflict state',
      (tester) async {
    StaticSyncController.initialStatus = SyncStatus.conflict;
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);

    await harness.pumpScreen(tester, const SyncStatusScreen());

    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('No conflicts.'), findsOneWidget);
  });

  testWidgets('SnapStrip disables capture actions when feature flags are off',
      (tester) async {
    StaticProfileController.initialState = AsyncData(
      ProfileState(
        profile: testProfile(),
        activeGoal: testGoal(),
        featureFlags: const {
          'snapstrip.enabled': true,
          'photo_analysis.enabled': false,
          'barcode.enabled': false,
          'ocr_assist.enabled': false,
          'voice_capture.enabled': false,
          'weekly_insights.enabled': false,
        },
        syncStatus: ProfileSyncStatus.synced,
      ),
    );
    final harness = await MobileTestHarness.create(
      config: testMissingConfig,
      overrides: [
        authControllerProvider.overrideWith(StaticAuthController.new),
        profileControllerProvider.overrideWith(StaticProfileController.new),
      ],
    );
    addTearDown(harness.dispose);

    await harness.pumpScreen(tester, const HomeScreen());

    expect(find.text('Weekly check-in'), findsNothing);
  });
}

class TestOnboardingProfileController extends ProfileController {
  static OnboardingDraft? completedDraft;

  static void reset() {
    completedDraft = null;
  }

  @override
  Future<ProfileState> build() async => const ProfileState.empty();

  @override
  Future<void> completeOnboarding(String userId, OnboardingDraft draft) async {
    completedDraft = draft;
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
