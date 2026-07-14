import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/app/theme/app_theme.dart';
import 'package:snapgrub/features/auth/presentation/auth_screen.dart';
import 'package:snapgrub/features/meal_editor/presentation/meal_editor_screen.dart';
import 'package:snapgrub/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:snapgrub/features/privacy/presentation/privacy_settings_screen.dart';
import 'package:snapgrub/offline/sync/sync_status_screen.dart';

import '../../helpers/mobile_test_harness.dart';

void main() {
  testWidgets('critical screens keep primary controls visible with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);

    await _pumpLargeText(tester, harness, const AuthScreen());
    await _expectVisible(tester, 'Sign in');

    await _pumpLargeText(tester, harness, const OnboardingFlowScreen());
    await _expectVisible(tester, 'Next');

    await _pumpLargeText(
      tester,
      harness,
      MealEditorScreen(initialDraft: testMealDraft()),
    );
    await _expectVisible(tester, 'Save meal');

    await _pumpLargeText(tester, harness, const ExportDataScreen());
    await _expectVisible(tester, 'Create export');

    await _pumpLargeText(tester, harness, const DeleteAccountScreen());
    await _expectVisible(tester, 'Delete account');

    await _pumpLargeText(tester, harness, const SyncStatusScreen());
    expect(find.byTooltip('Sync now'), findsOneWidget);
  });
}

Future<void> _expectVisible(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpLargeText(
  WidgetTester tester,
  MobileTestHarness harness,
  Widget screen,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        theme: buildSnapGrubTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
