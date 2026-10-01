import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/core/time/clock.dart';
import 'package:snapgrub/features/photo_analysis/application/analysis_queue_controller.dart';

import '../../../../integration_test/marketing/marketing_seed.dart';
import '../../../helpers/mobile_test_harness.dart';

void main() {
  // Regression: several non-meal rows (chat, proposal, photo job) used to
  // share one GlobalKey because `null == null` marked them all as the anchor.
  testWidgets(
      'Today timeline with chat + photo rows scrolls without key clashes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 956));
    final harness = await MobileTestHarness.create(overrides: [
      clockProvider.overrideWithValue(() => marketingNow),
      analysisQueueProvider.overrideWith(() => MarketingAnalysisQueue(
          [heroJob(testUserId, '/tmp', AnalysisJobStatus.analyzing)])),
    ]);
    addTearDown(harness.dispose);
    await tester.runAsync(() => seedMarketingData(
        db: harness.db,
        container: harness.container,
        userId: testUserId,
        timezone: testTimezone));
    await harness.pumpRouter(tester);
    harness.container.read(appRouterProvider).go('/home');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.dragFrom(const Offset(220, 520), const Offset(0, -1500));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  });
}
