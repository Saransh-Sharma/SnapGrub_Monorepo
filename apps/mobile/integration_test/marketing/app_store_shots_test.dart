// App Store / marketing captures. Prints `SHOT:<theme>_<nn>_<name>` at each
// stop; tool/marketing/capture.sh screenshots the Simulator on every marker.
//
//   flutter test integration_test/marketing/app_store_shots_test.dart -d <udid> \
//     --dart-define=MARKETING_ART_DIR=<abs path to marketing/illustrations> ...
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/app/theme/app_theme.dart';
import 'package:snapgrub/core/design_system/effects/effects_scope.dart';
import 'package:snapgrub/core/design_system/effects/shader_library.dart';
import 'package:snapgrub/core/preferences/ui_preferences.dart';
import 'package:snapgrub/core/time/clock.dart';
import 'package:snapgrub/features/meal_visuals/data/meal_visual_repository.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_region.dart';
import 'package:snapgrub/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:snapgrub/features/photo_analysis/application/analysis_queue_controller.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';
import 'package:snapgrub/features/conversation/presentation/widgets/conversation_meal_card.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../test/helpers/mobile_test_harness.dart';
import '../../test/unit/features/onboarding/onboarding_test_utils.dart'
    show FakeRegionDetector;
import 'marketing_seed.dart';

const artDir = String.fromEnvironment('MARKETING_ART_DIR');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> hold(WidgetTester tester, [int ms = 1200]) =>
      tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

  Future<void> shot(WidgetTester tester, String name, {int settle = 1800}) async {
    await hold(tester, settle);
    // ignore: avoid_print
    print('SHOT:$name');
    await hold(tester, 1600);
  }

  Future<void> tapId(WidgetTester tester, String id, {int wait = 700}) async {
    final finder = find.byKey(ValueKey(id));
    await tester.ensureVisible(finder.first);
    await tester.tap(finder.first, warnIfMissed: false);
    await hold(tester, wait);
  }

  bool visible(String id) => find.byKey(ValueKey(id)).evaluate().isNotEmpty;

  Widget app(ProviderContainer container, {Widget? home}) =>
      UncontrolledProviderScope(
        container: container,
        child: Consumer(builder: (context, ref, _) {
          final mode = ref.watch(uiPreferencesProvider).themeMode;
          Widget wrap(BuildContext context, Widget? child) =>
              AnnotatedRegion<SystemUiOverlayStyle>(
                value: Theme.of(context).brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                child: SgEffectsScope(
                  preference: VisualEffectsLevel.full,
                  enableWatchdog: false,
                  child: child!,
                ),
              );
          if (home != null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildSnapGrubTheme(),
              darkTheme: buildSnapGrubTheme(brightness: Brightness.dark),
              themeMode: mode,
              builder: wrap,
              home: home,
            );
          }
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: buildSnapGrubTheme(),
            darkTheme: buildSnapGrubTheme(brightness: Brightness.dark),
            themeMode: mode,
            routerConfig: ref.watch(appRouterProvider),
            builder: wrap,
          );
        }),
      );

  setUpAll(() async {
    // The app does this in bootstrap; without it user-local times fall back
    // to UTC and the greeting reads the wrong part of the day.
    tzdata.initializeTimeZones();
    await ShaderLibrary.preloadAll();
  });

  /// Scrolls the nearest Scrollable so [finder] sits at [alignment]
  /// (0 = top of the viewport, 1 = bottom).
  Future<void> reveal(WidgetTester tester, Finder finder,
      {double alignment = .2}) async {
    await Scrollable.ensureVisible(tester.element(finder.first),
        alignment: alignment, duration: const Duration(milliseconds: 500));
    await hold(tester, 800);
  }

  testWidgets('05 onboarding plan reveal', (tester) async {
    final container = ProviderContainer(overrides: [
      regionDetectorProvider.overrideWithValue(const FakeRegionDetector()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(app(container, home: const OnboardingFlowScreen()));
    await hold(tester, 1500);
    container.read(onboardingControllerProvider.notifier)
      ..updateName('Maya')
      ..updateGoal('lose')
      ..updateWeightKg(68.5)
      ..updateHeightCm(168)
      ..updateTargetWeightKg(63)
      ..updatePace(.5);
    await hold(tester, 300);
    await tapId(tester, 'onboarding.next');
    await tester.enterText(find.byType(TextField).first, 'Maya');
    await hold(tester, 300);
    await tapId(tester, 'onboarding.next');
    await tapId(tester, 'onboarding.goal.lose');
    await tapId(tester, 'onboarding.next');
    await tapId(tester, 'onboarding.sex.female');
    for (var i = 0; i < 14 && !visible('onboarding.plan_card'); i++) {
      if (visible('onboarding.next')) {
        await tapId(tester, 'onboarding.next', wait: 900);
      } else {
        await hold(tester, 800); // "Building your plan" auto-advances.
      }
    }
    expect(find.byKey(const ValueKey('onboarding.plan_card')), findsOneWidget);
    await shot(tester, 'light_05_plan', settle: 3200);
  });

  testWidgets('app store tour', (tester) async {
    StaticSyncController.initialStatus = SyncStatus.synced;
    final harness = await MobileTestHarness.create(overrides: [
      clockProvider.overrideWithValue(() => marketingNow),
      mealVisualProvider.overrideWith(
          (ref, meal) => Stream.value(marketingVisual(meal, artDir))),
      mealAssetPathProvider.overrideWith((ref, id) async =>
          id == marketingHeroAssetId ? '$artDir/hero-plate.png' : null),
      analysisQueueProvider.overrideWith(() => MarketingAnalysisQueue(
          [heroJob(testUserId, artDir, AnalysisJobStatus.analyzing)])),
    ]);
    addTearDown(harness.dispose);
    await tester.runAsync(() => seedMarketingData(
          db: harness.db,
          container: harness.container,
          userId: testUserId,
          timezone: testTimezone,
        ));
    final prefs = harness.container.read(uiPreferencesProvider.notifier);
    await prefs.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(app(harness.container));
    final router = harness.container.read(appRouterProvider);
    final queue = harness.container.read(analysisQueueProvider.notifier)
        as MarketingAnalysisQueue;

    // Drag from screen coordinates: the hero card may already be scrolled
    // away and disposed by the lazy list.
    Future<void> scrollToday(double dy) async {
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.dragFrom(
          Offset(size.width / 2, size.height * .55), Offset(0, dy));
      await hold(tester, 900);
    }

    Future<void> review() async {
      queue.show(heroJob(testUserId, artDir, AnalysisJobStatus.ready));
      router.push('/meal-editor',
          extra: queue.state.first.draft);
      await hold(tester, 1800);
      if (visible('meal.item.1')) await tapId(tester, 'meal.item.1', wait: 900);
    }

    Future<void> progressTop() async {
      router.go('/progress');
      await hold(tester, 600);
    }

    // ---- Light ----------------------------------------------------------
    router.go('/home');
    await shot(tester, 'light_01_today', settle: 4200);

    // 02: the photo card, finished, with the foods it found.
    queue.show(heroJob(testUserId, artDir, AnalysisJobStatus.ready));
    await scrollToday(-700);
    await reveal(tester, find.byKey(const ValueKey('today.analysis.marketing-job')),
        alignment: .12);
    await shot(tester, 'light_02_snap', settle: 1400);

    // 03: the chat and its proposal, fully above the composer.
    await reveal(tester, find.byType(ProposalMealCard), alignment: .98);
    await shot(tester, 'light_03_chat', settle: 1200);

    await review();
    await shot(tester, 'light_04_review');
    router.pop();

    await progressTop();
    await shot(tester, 'light_06_progress', settle: 2800);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await hold(tester, 600);
    await reveal(tester, find.text('Macro averages'), alignment: .02);
    await shot(tester, 'light_07_consistency', settle: 1600);

    router.push('/milestones');
    await hold(tester, 1600);
    final gold = find.bySemanticsLabel(RegExp('30-day'));
    if (gold.evaluate().isNotEmpty) {
      await tester.tap(gold.first, warnIfMissed: false);
    }
    await shot(tester, 'light_08_milestones', settle: 2600);
    router.pop();
    await hold(tester, 600);
    if (router.canPop()) router.pop();

    router.push('/recap');
    await hold(tester, 1800);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(size.width * .85, size.height * .5));
    await shot(tester, 'light_09_recap', settle: 1800);
    router.pop();

    router.go('/atlas');
    await shot(tester, 'light_10_atlas', settle: 2400);

    // ---- Dark (★ shots) ------------------------------------------------
    await prefs.setThemeMode(ThemeMode.dark);
    router.go('/home');
    await hold(tester, 400);
    await scrollToday(1500);
    await shot(tester, 'dark_01_today', settle: 3000);

    await review();
    await shot(tester, 'dark_04_review');
    router.pop();

    await progressTop();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
    await shot(tester, 'dark_06_progress', settle: 2600);

    router.go('/atlas');
    await shot(tester, 'dark_10_atlas', settle: 2200);
  });
}
