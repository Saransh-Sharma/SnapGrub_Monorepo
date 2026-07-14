import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/insights/application/weekly_checkin_summary_mapper.dart';
import 'package:snapgrub/features/insights/domain/weekly_insight.dart';

void main() {
  const mapper = WeeklyCheckInSummaryMapper();

  test('maps ready enriched payload into V1.5 summary', () {
    final summary = mapper.fromInsights([
      _insight('logging_streak', payload: {'logged_days': 4, 'meal_count': 12}),
      _insight('average_intake_vs_target', payload: {'delta_kcal': -120}),
      _insight('protein_target_hit_rate', payload: {'hit_rate': 0.75}),
      _insight('most_repeated_meal', payload: {'title': 'Dal', 'count': 3}),
      _insight('next_week_suggestion', payload: {
        'action_id': 'reuse_repeat_meal',
        'action_title': 'Keep a reliable repeat handy',
        'action_body': 'Keep Dal handy.',
      }),
    ]);

    expect(summary, isNotNull);
    expect(summary!.hasEnoughData, true);
    expect(summary.primaryActionTitle, 'Keep a reliable repeat handy');
    expect(summary.loggingRhythm, '4 logged days · 12 meals');
    expect(summary.calorieDelta, '120 kcal below target');
    expect(summary.proteinConsistency, '75% of logged days near target');
    expect(summary.repeatPattern, 'Dal repeated 3 times');
  });

  test('falls back to legacy summaries when payload keys are absent', () {
    final summary = mapper.fromInsights([
      _insight('logging_streak', summary: 'Legacy rhythm'),
      _insight('next_week_suggestion', summary: 'Legacy action'),
    ]);

    expect(summary!.primaryActionBody, 'Legacy action');
    expect(summary.loggingRhythm, 'Legacy rhythm');
  });

  test('insufficient data remains insufficient', () {
    final summary = mapper.fromInsights([
      _insight('logging_streak', status: 'insufficient_data'),
    ]);

    expect(summary!.hasEnoughData, false);
  });
}

WeeklyInsight _insight(
  String type, {
  Map<String, Object?> payload = const {},
  String status = 'ready',
  String summary = 'Summary',
}) {
  return WeeklyInsight(
    id: 'insight-$type',
    userId: 'user-a',
    weekStart: DateTime(2026, 5, 18),
    insightType: type,
    title: type,
    summary: summary,
    payload: payload,
    status: status,
  );
}
