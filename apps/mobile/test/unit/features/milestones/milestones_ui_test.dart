import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/app/theme/app_theme.dart';
import 'package:snapgrub/features/milestones/presentation/milestones_screen.dart';
import 'package:snapgrub/features/recap/presentation/weekly_recap_screen.dart';

import '../../../helpers/mobile_test_harness.dart';

Future<void> _pump(
    WidgetTester tester, MobileTestHarness harness, Widget screen) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(theme: buildSnapGrubTheme(), home: screen),
    ),
  );
  // Medals and foil shimmer loop, so pump fixed frames instead of settling.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('milestones gallery shows locked medals and flips a focused one',
      (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);

    await _pump(tester, harness, const MilestonesScreen());

    expect(find.text('Milestones'), findsOneWidget);
    expect(find.text('3-day streak'), findsOneWidget);

    await tester.tap(find.text('3-day streak'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Focus layer lands and auto-flips to the back.
    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.text('Show front'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('LOCKED'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly recap shows a friendly empty state with no meals',
      (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);

    await _pump(tester, harness, const WeeklyRecapScreen());

    expect(find.text('A quiet week'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
