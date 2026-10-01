import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/features/capture/domain/capture_state.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

import '../../../helpers/mobile_test_harness.dart';

void main() {
  setUp(() {
    StaticSyncController.initialStatus = SyncStatus.synced;
    StaticCaptureController.initialState =
        const CaptureState(status: CaptureStatus.permissionNeeded);
  });

  Future<MobileTestHarness> pumpToday(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await harness.pumpRouter(tester);
    harness.container.read(appRouterProvider).go('/home');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    return harness;
  }

  testWidgets('Today shows the dashboard, tab bar and an inviting empty log',
      (tester) async {
    await pumpToday(tester);

    expect(find.byKey(const ValueKey('screen.day_thread')), findsOneWidget);
    expect(find.byKey(const ValueKey('today.calorie_hero')), findsOneWidget);
    expect(find.text('CALORIES'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Snap your first meal'), findsOneWidget);
    expect(find.byKey(const ValueKey('shell.tab_bar')), findsOneWidget);
    expect(find.bySemanticsLabel('Log a meal'), findsOneWidget);
  });

  testWidgets('a logged meal appears as a card with macros', (tester) async {
    final harness = await pumpToday(tester);
    final draft = testMealDraft(title: 'Paneer bowl')
      ..loggedAt = DateTime(2026, 5, 30, 13);
    await harness.container.read(mealRepositoryProvider).saveDraft(draft);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.drag(find.byKey(const ValueKey('today.calorie_hero')),
        const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Paneer bowl'), findsOneWidget);
    expect(find.text('Midday'), findsOneWidget);
    expect(find.text('Snap your first meal'), findsNothing);
  });

  testWidgets('tapping the hero flips between left and eaten', (tester) async {
    await pumpToday(tester);
    expect(find.text('left'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('today.calorie_hero')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('eaten'), findsOneWidget);
  });
}
