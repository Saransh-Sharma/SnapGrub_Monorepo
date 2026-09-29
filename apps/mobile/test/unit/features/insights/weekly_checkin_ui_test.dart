import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';
import 'package:snapgrub/features/progress/presentation/progress_screen.dart';

import '../../../helpers/mobile_test_harness.dart';

void main() {
  testWidgets('weekly check-in renders V1.5 summary when enabled',
      (tester) async {
    final harness = await MobileTestHarness.create();
    addTearDown(harness.dispose);
    await _seedInsight(
      harness.db,
      type: 'logging_streak',
      title: 'Logging',
      summary: 'Logged 4 days this week.',
      payload: {'logged_days': 4, 'meal_count': 12},
    );
    await _seedInsight(
      harness.db,
      type: 'average_intake_vs_target',
      title: 'Calories',
      summary: '120 kcal below target.',
      payload: {'delta_kcal': -120},
    );
    await _seedInsight(
      harness.db,
      type: 'protein_target_hit_rate',
      title: 'Protein',
      summary: 'Protein was near target on 75% of days.',
      payload: {'hit_rate': 0.75},
    );
    await _seedInsight(
      harness.db,
      type: 'most_repeated_meal',
      title: 'Top repeat',
      summary: 'Dal came up 3 times.',
      payload: {'title': 'Dal', 'count': 3},
    );
    await _seedInsight(
      harness.db,
      type: 'next_week_suggestion',
      title: 'Next week',
      summary: 'Log Dal again when the week gets busy.',
      payload: {
        'action_id': 'reuse_repeat_meal',
        'action_title': 'Keep a go-to handy',
        'action_body': 'Log Dal again when the week gets busy.',
      },
    );

    await harness.pumpScreen(tester, const ProgressScreen());
    // The check-in sits below the charts; scroll the lazy list to it.
    await tester.scrollUntilVisible(
      find.text('See repeats'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly check-in'), findsOneWidget);
    expect(find.text('Keep a go-to handy'), findsOneWidget);
    expect(find.text('4 days · 12 meals'), findsOneWidget);
    expect(find.text('Logging'), findsOneWidget);
    expect(find.text('See repeats'), findsOneWidget);
  });
}

Future<void> _seedInsight(
  AppDatabase db, {
  required String type,
  required String title,
  required String summary,
  required Map<String, Object?> payload,
}) async {
  await db.into(db.weeklyInsightsLocal).insertOnConflictUpdate(
        WeeklyInsightsLocalCompanion.insert(
          id: 'insight-$type',
          userId: testUserId,
          weekStart: DateTime(2026, 5, 18),
          insightType: type,
          title: title,
          summary: summary,
          payloadJson: Value(jsonEncode(payload)),
          status: const Value('ready'),
        ),
      );
}
