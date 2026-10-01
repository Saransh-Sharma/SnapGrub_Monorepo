// On-device visual tour: seeds realistic data, renders every major surface
// with effects at full quality and prints `SHOT:<name>` at each stop so an
// external `xcrun simctl io screenshot` watcher can capture real Metal frames.
//
//   flutter test integration_test/tour/visual_tour_test.dart -d <sim-udid>
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/app/theme/app_theme.dart';
import 'package:snapgrub/core/design_system/effects/effects_scope.dart';
import 'package:snapgrub/core/design_system/effects/shader_library.dart';
import 'package:snapgrub/core/preferences/ui_preferences.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

import '../../test/helpers/mobile_test_harness.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> hold(WidgetTester tester, [int ms = 1600]) =>
      tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

  Future<void> shot(WidgetTester tester, String name,
      {int settle = 1600}) async {
    await hold(tester, settle);
    // ignore: avoid_print
    print('SHOT:$name');
    await hold(tester, 1400);
  }

  MealDraft meal(String title, DateTime at, MealType type,
      List<(String, double, double, double, double)> items) {
    return MealDraft(
      userId: testUserId,
      timezone: testTimezone,
      title: title,
      source: MealSource.manual,
      mealType: type,
      loggedAt: at,
      items: [
        for (final (name, kcal, p, c, f) in items)
          MealDraftItem(
            name: name,
            quantity: 1,
            unit: 'serving',
            caloriesKcal: kcal,
            proteinG: p,
            carbsG: c,
            fatG: f,
          ),
      ],
    );
  }

  testWidgets('visual tour', (tester) async {
    await tester.runAsync(ShaderLibrary.preloadAll);
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    final repo = harness.container.read(mealRepositoryProvider);
    final today = DateTime(2026, 5, 30);
    await tester.runAsync(() async {
      // Eight days of history for streaks, charts and milestones.
      for (var d = 8; d >= 1; d--) {
        final day = today.subtract(Duration(days: d));
        await repo.saveDraft(meal(
            'Masala oats',
            day.add(const Duration(hours: 8)),
            MealType.breakfast,
            [('Masala oats', 320, 12, 48, 8)]));
        await repo.saveDraft(meal('Paneer tikka bowl',
            day.add(const Duration(hours: 13)), MealType.lunch, [
          ('Paneer tikka', 420, 28, 12, 26),
          ('Jeera rice', 260, 5, 52, 3)
        ]));
        await repo.saveDraft(meal(
            'Dal & roti',
            day.add(const Duration(hours: 20)),
            MealType.dinner,
            [('Toor dal', 230, 13, 32, 6), ('Roti ×2', 240, 8, 44, 4)]));
      }
      await repo.saveDraft(meal(
          'Greek yogurt & berries',
          today.add(const Duration(hours: 8, minutes: 10)),
          MealType.breakfast, [
        ('Greek yogurt', 150, 15, 8, 5),
        ('Blueberries', 60, 1, 14, 0),
        ('Honey', 60, 0, 17, 0)
      ]));
      await repo.saveDraft(meal(
          'Chicken biryani',
          today.add(const Duration(hours: 13, minutes: 20)),
          MealType.lunch,
          [('Chicken biryani', 610, 32, 70, 20), ('Raita', 90, 5, 7, 4)]));
      await repo.saveDraft(meal(
          'Masala chai',
          today.add(const Duration(hours: 16, minutes: 45)),
          MealType.snack,
          [('Masala chai', 110, 4, 14, 4)]));
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: harness.container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: buildSnapGrubTheme(),
            darkTheme: buildSnapGrubTheme(brightness: Brightness.dark),
            themeMode: ref.watch(uiPreferencesProvider).themeMode,
            routerConfig: ref.watch(appRouterProvider),
            builder: (context, child) => SgEffectsScope(
              preference: VisualEffectsLevel.full,
              enableWatchdog: false,
              child: child!,
            ),
          ),
        ),
      ),
    );
    final router = harness.container.read(appRouterProvider);

    router.go('/home');
    await shot(tester, '01_today', settle: 3200);

    await tester.drag(find.byKey(const ValueKey('today.calorie_hero')),
        const Offset(0, -520));
    await shot(tester, '02_today_log');

    router.go('/progress');
    await shot(tester, '03_progress', settle: 2600);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await shot(tester, '04_progress_more');

    router.go('/atlas');
    await shot(tester, '05_atlas');

    router.go('/settings');
    await shot(tester, '06_you');

    router.push('/milestones');
    await shot(tester, '07_milestones', settle: 2200);
    router.pop();

    router.go('/home');
    router.push('/meal-editor',
        extra: meal(
            'Chicken biryani',
            today.add(const Duration(hours: 13)),
            MealType.lunch,
            [('Chicken biryani', 610, 32, 70, 20), ('Raita', 90, 5, 7, 4)]));
    await shot(tester, '08_meal_review', settle: 2200);

    // Food search from the review screen, against the mock catalog.
    final searchButton = find.byKey(const ValueKey('meal.search_food'));
    // The buttons sit below the fold and the list builds lazily.
    await tester.scrollUntilVisible(
      searchButton,
      320,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('scaffold.meal_editor')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(searchButton);
    await shot(tester, '08b_food_search', settle: 1400);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('meal.food_search.field')),
        matching: find.byType(TextField),
      ),
      'dal',
    );
    await shot(tester, '08c_food_results', settle: 1600);
    await tester.tap(find.text('Dal tadka'));
    await shot(tester, '08d_food_added', settle: 1600);
    router.pop();

    router.push('/capture?mode=describe');
    await shot(tester, '09_capture_describe', settle: 2200);
    router.pop();

    router.push('/recap');
    await shot(tester, '10_recap', settle: 2600);
    router.pop();

    harness.container
        .read(uiPreferencesProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    router.go('/home');
    await shot(tester, '11_today_dark', settle: 2600);
    router.go('/progress');
    await shot(tester, '12_progress_dark', settle: 2400);
  });
}
