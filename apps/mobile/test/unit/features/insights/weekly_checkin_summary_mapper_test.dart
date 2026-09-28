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
        'action_title': 'Keep a go-to handy',
        'action_body': 'Log Dal again when the week gets busy.',
      }),
    ]);

    expect(summary, isNotNull);
    expect(summary!.hasEnoughData, true);
    expect(summary.primaryActionTitle, 'Keep a go-to handy');
    expect(summary.loggingRhythm, '4 days · 12 meals');
    expect(summary.calorieDelta, '120 kcal below target');
    expect(summary.proteinConsistency, 'Near target on 75% of days');
    expect(summary.repeatPattern, 'Dal logged 3 times');
  });

  test('uses singulars and explicit band copy', () {
    final summary = mapper.fromInsights([
      _insight('logging_streak', payload: {'logged_days': 1, 'meal_count': 1}),
      _insight('average_intake_vs_target', payload: {'band': 'above'}),
    ]);

    expect(summary!.loggingRhythm, '1 day · 1 meal');
    expect(summary.calorieDelta, 'Above target');
  });

  test('close-to-target delta and band read the same', () {
    final byDelta = mapper.fromInsights([
      _insight('average_intake_vs_target', payload: {'delta_kcal': 40}),
    ]);
    final byBand = mapper.fromInsights([
      _insight('average_intake_vs_target', payload: {'band': 'near'}),
    ]);

    expect(byDelta!.calorieDelta, 'Close to target');
    expect(byBand!.calorieDelta, 'Close to target');
  });

  test('labels the varied slot through Labels.mealType, never raw', () {
    final dinner = mapper.fromInsights([
      _insight('highest_variance_meal_slot', payload: {'meal_type': 'dinner'}),
    ]);
    final unknown = mapper.fromInsights([
      _insight('highest_variance_meal_slot', payload: {'meal_type': 'unknown'}),
    ]);

    expect(dinner!.repeatPattern, 'Dinner varied most');
    expect(unknown!.repeatPattern, 'Other varied most');
  });

  test('empty tiles invite logging', () {
    final summary = mapper.fromInsights([
      _insight('next_week_suggestion'),
    ]);

    expect(summary!.loggingRhythm, 'Log a few meals to see your week.');
    expect(summary.calorieDelta, 'Log more to see your calorie trend.');
    expect(summary.proteinConsistency, 'Set a protein target to track this.');
    expect(summary.repeatPattern, 'Log more meals to see patterns.');
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
