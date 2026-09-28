import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/insights/domain/weekly_insight.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class WeeklyCheckInSummary {
  const WeeklyCheckInSummary({
    required this.weekStart,
    required this.status,
    required this.primaryActionTitle,
    required this.primaryActionBody,
    required this.actionId,
    required this.loggingRhythm,
    required this.calorieDelta,
    required this.proteinConsistency,
    required this.repeatPattern,
  });

  final DateTime weekStart;
  final String status;
  final String primaryActionTitle;
  final String primaryActionBody;
  final String actionId;
  final String loggingRhythm;
  final String calorieDelta;
  final String proteinConsistency;
  final String repeatPattern;

  bool get hasEnoughData => status == 'ready';
}

class WeeklyCheckInSummaryMapper {
  const WeeklyCheckInSummaryMapper();

  WeeklyCheckInSummary? fromInsights(List<WeeklyInsight> insights) {
    if (insights.isEmpty) return null;
    final latestWeek = insights
        .map((insight) => insight.weekStart)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final latest = [
      for (final insight in insights)
        if (_sameDay(insight.weekStart, latestWeek)) insight,
    ];
    final byType = {
      for (final insight in latest) insight.insightType: insight,
    };
    final status = latest.any((insight) => insight.status == 'ready')
        ? 'ready'
        : latest.first.status;

    final action = byType['next_week_suggestion'];
    final logging = byType['logging_streak'];
    final calories = byType['average_intake_vs_target'];
    final protein = byType['protein_target_hit_rate'];
    final repeat = byType['most_repeated_meal'];
    final variance = byType['highest_variance_meal_slot'];

    return WeeklyCheckInSummary(
      weekStart: latestWeek,
      status: status,
      primaryActionTitle: _string(action?.payload['action_title']) ??
          action?.title ??
          'Next week',
      primaryActionBody: _string(action?.payload['action_body']) ??
          action?.summary ??
          'Try logging one go-to meal a few times.',
      actionId: _string(action?.payload['action_id']) ?? 'review_repeat_foods',
      loggingRhythm: _loggingLabel(logging),
      calorieDelta: _calorieLabel(calories),
      proteinConsistency: _proteinLabel(protein),
      repeatPattern: _repeatLabel(repeat, variance),
    );
  }

  String _loggingLabel(WeeklyInsight? insight) {
    if (insight == null) return 'Log a few meals to see your week.';
    final loggedDays = _number(insight.payload['logged_days'])?.round();
    final mealCount = _number(insight.payload['meal_count'])?.round();
    if (loggedDays != null && mealCount != null) {
      return '${Labels.count(loggedDays, 'day')} · '
          '${Labels.count(mealCount, 'meal')}';
    }
    return insight.summary;
  }

  String _calorieLabel(WeeklyInsight? insight) {
    if (insight == null) return 'Log more to see your calorie trend.';
    final delta = _number(insight.payload['delta_kcal']);
    if (delta != null) {
      if (delta.abs() < 75) return 'Close to target';
      final direction = delta > 0 ? 'above' : 'below';
      return '${Labels.kcal(delta.abs())} $direction target';
    }
    // `band` is a machine value from the server: near | above | below.
    return switch (_string(insight.payload['band'])) {
      'near' => 'Close to target',
      'above' => 'Above target',
      'below' => 'Below target',
      _ => insight.summary,
    };
  }

  String _proteinLabel(WeeklyInsight? insight) {
    if (insight == null) return 'Set a protein target to track this.';
    final hitRate = _number(insight.payload['hit_rate']);
    if (hitRate != null) {
      return 'Near target on ${(hitRate * 100).round()}% of days';
    }
    return insight.summary;
  }

  String _repeatLabel(WeeklyInsight? repeat, WeeklyInsight? variance) {
    final repeatTitle = _string(repeat?.payload['title']);
    final repeatCount = _number(repeat?.payload['count'])?.round();
    if (repeatTitle != null && repeatCount != null && repeatCount > 1) {
      return '$repeatTitle logged ${Labels.count(repeatCount, 'time')}';
    }
    final slot = _string(variance?.payload['meal_type']);
    if (slot != null) return '${_slotLabel(slot)} varied most';
    return repeat?.summary ??
        variance?.summary ??
        'Log more meals to see patterns.';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String? _string(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  /// The server sends meal slots as raw names ("dinner"). Known slots go
  /// through [Labels.mealType]; anything else is humanized, never printed raw.
  String _slotLabel(String value) {
    final type = MealType.values.asNameMap()[value.toLowerCase()];
    if (type != null) return Labels.mealType(type);
    final spaced = value.replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
