import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/app/e2e/e2e_data.dart';
import 'package:snapgrub/app/theme/app_theme.dart';
import 'package:snapgrub/core/preferences/ui_preferences.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/features/milestones/application/streak_provider.dart';
import 'package:snapgrub/features/milestones/domain/streak.dart';
import 'package:snapgrub/features/onboarding/domain/onboarding_draft.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/features/profile/domain/profile_state.dart';
import 'package:snapgrub/features/profile/presentation/profile_labels.dart';
import 'package:snapgrub/features/profile/presentation/settings_screen.dart';
import 'package:snapgrub/features/progress/data/body_measurement_repository.dart';
import 'package:snapgrub/features/progress/data/goal_weight_store.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

import '../../../helpers/mobile_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _FakeProfileController.reset();
    _FakeAuthController.signOuts = 0;
  });

  group('ProfileLabels', () {
    test('humanises locale and units', () {
      expect(ProfileLabels.locale('en-IN'), 'English (India)');
      expect(ProfileLabels.locale('EN_us'), 'English (United States)');
      expect(ProfileLabels.locale('xx-QQ'), 'XX (QQ)');
      expect(ProfileLabels.units('metric'), 'Metric');
      expect(ProfileLabels.summary(testProfile()),
          'English (India) · Metric · Kolkata');
    });
  });

  group('You tab', () {
    testWidgets('shows profile, streak, plan and human sync state',
        (tester) async {
      await _pump(tester);

      expect(find.byKey(const ValueKey('scaffold.settings')), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('English (India) · Metric · Kolkata'), findsOneWidget);
      expect(find.text('8-day streak'), findsOneWidget);
      expect(find.textContaining('2,000', findRichText: true), findsOneWidget);
      expect(find.textContaining('EN-IN'), findsNothing);

      await tester.scrollUntilVisible(find.text('Synced'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('plan card opens the goal editor route', (tester) async {
      await _pump(tester);

      await tester.tap(find.byKey(const ValueKey('settings.goal')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Goal & targets'), findsOneWidget);
      expect(find.byKey(const ValueKey('scaffold.edit_goal')), findsOneWidget);
    });

    testWidgets('missing goal shows a Set your targets call to action',
        (tester) async {
      _FakeProfileController.goal = false;
      await _pump(tester);

      expect(find.text('Set your targets'), findsOneWidget);
      await tester.tap(find.text('Set targets'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Goal & targets'), findsOneWidget);
    });

    testWidgets('sign out asks first', (tester) async {
      _usePhoneSize(tester);
      await _pump(tester);

      final signOut = find.byKey(const ValueKey('settings.sign_out'));
      await tester.scrollUntilVisible(signOut, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(signOut);
      await tester.pumpAndSettle();
      await tester.tap(signOut);
      await tester.pumpAndSettle();

      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_FakeAuthController.signOuts, 0);

      await tester.tap(signOut);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(_FakeAuthController.signOuts, 1);
      expect(find.text('auth-route'), findsOneWidget);
    });

    testWidgets('appearance controls update preferences', (tester) async {
      final container = await _pump(tester);

      final dark = find.text('Dark');
      await tester.scrollUntilVisible(dark, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(dark);
      await tester.pumpAndSettle();
      expect(container.read(uiPreferencesProvider).themeMode, ThemeMode.dark);

      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();
      expect(container.read(uiPreferencesProvider).effects,
          VisualEffectsLevel.off);
      expect(find.text('Flat colors. Best for battery.'), findsOneWidget);

      await tester.tap(find.text('Eaten'));
      await tester.pumpAndSettle();
      expect(container.read(uiPreferencesProvider).calorieFraming,
          CalorieFraming.eaten);
    });

    testWidgets('meets tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('lays out at 2x text scale', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, textScale: 2);
      expect(tester.takeException(), isNull);

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings.sign_out')),
        400,
        scrollable: scrollable,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Goal editor', () {
    testWidgets('validates inline instead of crashing', (tester) async {
      await _pump(tester, initial: '/settings/goal');

      final calories = find.descendant(
        of: find.byKey(const ValueKey('settings.goal.calories')),
        matching: find.byType(TextField),
      );
      await tester.enterText(calories, '9000');
      await tester.pump();
      expect(find.text('Use 500–6,000 kcal'), findsOneWidget);

      await tester.enterText(calories, '');
      await tester.pump();
      await tester.tap(find.text('Save targets'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your calorie target'), findsOneWidget);
      expect(_FakeProfileController.saved, isEmpty);
    });

    testWidgets('saves, toasts and returns to the You tab', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('settings.goal')));
      await tester.pumpAndSettle();

      final protein = find.descendant(
        of: find.byKey(const ValueKey('settings.goal.protein')),
        matching: find.byType(TextField),
      );
      await tester.enterText(protein, '150');
      await tester.pump();
      await tester.tap(find.text('Save targets'));
      await tester.pumpAndSettle();

      expect(_FakeProfileController.saved, hasLength(1));
      final draft = _FakeProfileController.saved.single;
      expect(draft.proteinG, 150);
      expect(draft.caloriesKcal, 2000);
      expect(find.text('Targets saved'), findsOneWidget);
      expect(find.byKey(const ValueKey('scaffold.settings')), findsOneWidget);
      expect(find.byKey(const ValueKey('scaffold.edit_goal')), findsNothing);
    });

    testWidgets('unsaved changes ask before leaving', (tester) async {
      _usePhoneSize(tester);
      await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('settings.goal')));
      await tester.pumpAndSettle();

      final fat = find.descendant(
        of: find.byKey(const ValueKey('settings.goal.fat')),
        matching: find.byType(TextField),
      );
      await tester.scrollUntilVisible(fat, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(fat, '70');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scaffold.edit_goal')), findsNothing);
      expect(_FakeProfileController.saved, isEmpty);
    });

    testWidgets('lays out on a phone at 2x text scale', (tester) async {
      _usePhoneSize(tester);
      await _pump(tester,
          initial: '/settings/goal', textScale: 2, weightKg: 70);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings.goal.fat')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Save targets'), findsOneWidget);
    });

    testWidgets('recalculate preview is hidden without a known weight',
        (tester) async {
      await _pump(tester, initial: '/settings/goal');
      expect(find.text('Recalculate targets'), findsNothing);
    });

    testWidgets('recalculate preview fills targets from latest weight',
        (tester) async {
      await _pump(tester, initial: '/settings/goal', weightKg: 80);
      expect(find.text('Recalculate targets'), findsOneWidget);

      final height = find.descendant(
        of: find.byKey(const ValueKey('settings.goal.recalculate')),
        matching: find.byType(TextField),
      );
      await tester.enterText(height, '175');
      await tester.pumpAndSettle();

      final use = find.text('Use these targets');
      await tester.ensureVisible(use);
      await tester.pumpAndSettle();
      await tester.tap(use);
      await tester.pumpAndSettle();

      final calories = tester.widget<TextField>(find.descendant(
        of: find.byKey(const ValueKey('settings.goal.calories')),
        matching: find.byType(TextField),
      ));
      expect(calories.controller!.text, isNot('2000'));
      expect(double.parse(calories.controller!.text), greaterThan(1200));
    });
  });
}

/// A typical phone viewport; the confirmation sheet needs real phone height.
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String initial = '/settings',
  double textScale = 1,
  double? weightKg,
}) async {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/goal',
        builder: (context, state) => const GoalEditScreen(),
      ),
      for (final path in [
        '/auth',
        '/milestones',
        '/templates',
        '/custom-foods',
        '/sync',
        '/settings/privacy',
      ])
        GoRoute(
          path: path,
          builder: (context, state) => Scaffold(
            body: Text('${path.substring(1).split('/').last}-route'),
          ),
        ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      profileControllerProvider.overrideWith(_FakeProfileController.new),
      authControllerProvider.overrideWith(_FakeAuthController.new),
      syncControllerProvider.overrideWith(StaticSyncController.new),
      streakProvider.overrideWithValue(
        const StreakSummary(
          current: 8,
          best: 12,
          loggedToday: true,
          frozenDays: <DateTime>{},
        ),
      ),
      latestWeightKgProvider.overrideWithValue(weightKg),
      goalWeightProvider.overrideWith((ref) async => null),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildSnapGrubTheme(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

class _FakeProfileController extends ProfileController {
  static bool goal = true;
  static final saved = <OnboardingDraft>[];

  static void reset() {
    goal = true;
    saved.clear();
  }

  @override
  Future<ProfileState> build() async => ProfileState(
        profile: testProfile(),
        activeGoal: goal ? testGoal() : null,
        featureFlags: E2eData.enabledFlags,
        syncStatus: ProfileSyncStatus.synced,
      );

  @override
  Future<void> completeOnboarding(String userId, OnboardingDraft draft) async {
    draft.validate();
    saved.add(draft);
  }

  @override
  Future<void> refresh() async {}
}

class _FakeAuthController extends AuthController {
  static int signOuts = 0;

  @override
  Future<AuthState> build() async => const AuthState.signedIn(testUserId);

  @override
  Future<void> signOut() async {
    signOuts++;
    state = const AsyncData(AuthState.signedOut());
  }
}
