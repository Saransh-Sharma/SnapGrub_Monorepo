import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/app/theme/app_theme.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_region.dart';
import 'package:snapgrub/features/onboarding/presentation/onboarding_flow_screen.dart';

/// Deterministic region so tests don't depend on the host locale.
class FakeRegionDetector extends RegionDetector {
  const FakeRegionDetector({
    this.region = const DetectedRegion(
      locale: 'en-GB',
      countryCode: 'GB',
      timezone: 'Europe/London',
    ),
  });

  final DetectedRegion region;

  @override
  Future<DetectedRegion> detect() async => region;
}

Finder byId(String id) => find.byKey(ValueKey(id));

/// Scrolls [id] into view if needed, taps it and settles.
Future<void> tapOnboarding(WidgetTester tester, String id) async {
  final finder = byId(id);
  expect(finder, findsOneWidget, reason: id);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Pumps the flow on its own (no router) at phone size.
Future<ProviderContainer> pumpOnboardingFlow(
  WidgetTester tester, {
  double textScale = 1,
  bool reduceMotion = false,
  Size size = const Size(390, 844),
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  Celebration.resetSession();
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [
    regionDetectorProvider.overrideWithValue(const FakeRegionDetector()),
    ...overrides,
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSnapGrubTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: const OnboardingFlowScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
