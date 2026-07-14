import 'package:snapgrub/features/insights/domain/weekly_insight.dart';

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
          'Log one familiar meal a few times next week.',
      actionId: _string(action?.payload['action_id']) ?? 'review_repeat_foods',
      loggingRhythm: _loggingLabel(logging),
      calorieDelta: _calorieLabel(calories),
      proteinConsistency: _proteinLabel(protein),
      repeatPattern: _repeatLabel(repeat, variance),
    );
  }

  String _loggingLabel(WeeklyInsight? insight) {
    if (insight == null) return 'Log a few meals to see your weekly rhythm.';
    final loggedDays = _number(insight.payload['logged_days'])?.round();
    final mealCount = _number(insight.payload['meal_count'])?.round();
    if (loggedDays != null && mealCount != null) {
      return '$loggedDays logged day${loggedDays == 1 ? '' : 's'} · '
          '$mealCount meal${mealCount == 1 ? '' : 's'}';
    }
    return insight.summary;
  }

  String _calorieLabel(WeeklyInsight? insight) {
    if (insight == null) return 'Calorie trend appears after more logs.';
    final delta = _number(insight.payload['delta_kcal']);
    final band = _string(insight.payload['band']);
    if (delta != null) {
      if (delta.abs() < 75) return 'Average stayed close to target';
      final direction = delta > 0 ? 'above' : 'below';
      return '${delta.abs().round()} kcal $direction target';
    }
    if (band != null) return 'Average was $band target';
    return insight.summary;
  }

  String _proteinLabel(WeeklyInsight? insight) {
    if (insight == null) return 'Set a protein target to see consistency.';
    final hitRate = _number(insight.payload['hit_rate']);
    if (hitRate != null) {
      return '${(hitRate * 100).round()}% of logged days near target';
    }
    return insight.summary;
  }

  String _repeatLabel(WeeklyInsight? repeat, WeeklyInsight? variance) {
    final repeatTitle = _string(repeat?.payload['title']);
    final repeatCount = _number(repeat?.payload['count'])?.round();
    if (repeatTitle != null && repeatCount != null && repeatCount > 1) {
      return '$repeatTitle repeated $repeatCount times';
    }
    final mealType = _string(variance?.payload['meal_type']);
    if (mealType != null && mealType.isNotEmpty) {
      return '${_label(mealType)} varied most';
    }
    return repeat?.summary ??
        variance?.summary ??
        'Patterns appear after more logged meals.';
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

  String _label(String value) {
    final spaced = value.replaceAll('_', ' ');
    return spaced.isEmpty
        ? value
        : spaced[0].toUpperCase() + spaced.substring(1);
  }
}
