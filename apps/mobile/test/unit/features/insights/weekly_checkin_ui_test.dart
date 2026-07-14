import 'dart:convert';

import 'package:drift/drift.dart';
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
      title: 'Logging rhythm',
      summary: '4 days had meals logged this week.',
      payload: {'logged_days': 4, 'meal_count': 12},
    );
    await _seedInsight(
      harness.db,
      type: 'average_intake_vs_target',
      title: 'Average intake',
      summary: 'Average was below target.',
      payload: {'delta_kcal': -120},
    );
    await _seedInsight(
      harness.db,
      type: 'protein_target_hit_rate',
      title: 'Protein consistency',
      summary: 'Protein landed near target.',
      payload: {'hit_rate': 0.75},
    );
    await _seedInsight(
      harness.db,
      type: 'most_repeated_meal',
      title: 'Reliable repeat',
      summary: 'Dal repeated.',
      payload: {'title': 'Dal', 'count': 3},
    );
    await _seedInsight(
      harness.db,
      type: 'next_week_suggestion',
      title: 'Next week',
      summary: 'Keep Dal handy.',
      payload: {
        'action_id': 'reuse_repeat_meal',
        'action_title': 'Keep a reliable repeat handy',
        'action_body': 'Keep Dal handy.',
      },
    );

    await harness.pumpScreen(tester, const ProgressScreen());

    expect(find.text('Weekly check-in'), findsOneWidget);
    expect(find.text('Keep a reliable repeat handy'), findsOneWidget);
    expect(find.text('4 logged days · 12 meals'), findsOneWidget);
    expect(find.text('Review repeat foods'), findsOneWidget);
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
