import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/data/repositories/analytics_repository.dart';
import 'package:snapgrub/features/insights/application/weekly_checkin_summary_mapper.dart';

class WeeklyCheckInCard extends ConsumerStatefulWidget {
  const WeeklyCheckInCard({
    required this.summary,
    this.onReviewRepeatFoods,
    super.key,
  });

  final WeeklyCheckInSummary? summary;
  final VoidCallback? onReviewRepeatFoods;

  @override
  ConsumerState<WeeklyCheckInCard> createState() => _WeeklyCheckInCardState();
}

class _WeeklyCheckInCardState extends ConsumerState<WeeklyCheckInCard> {
  String? _trackedWeek;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _trackView();
    });
  }

  @override
  void didUpdateWidget(covariant WeeklyCheckInCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _trackView();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    if (summary == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.insights_outlined),
          title: Text('Weekly check-in'),
          subtitle: Text('A weekly view appears after a few logged meals.'),
        ),
      );
    }
    if (!summary.hasEnoughData) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.insights_outlined),
          title: const Text('Weekly check-in'),
          subtitle: Text(summary.loggingRhythm),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined),
                const SizedBox(width: 8),
                Text(
                  'Weekly check-in',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary.primaryActionTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(summary.primaryActionBody),
            const SizedBox(height: 12),
            _MetricRow(label: 'Rhythm', value: summary.loggingRhythm),
            _MetricRow(label: 'Calories', value: summary.calorieDelta),
            _MetricRow(label: 'Protein', value: summary.proteinConsistency),
            _MetricRow(label: 'Pattern', value: summary.repeatPattern),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reviewRepeatFoods,
              icon: const Icon(Icons.repeat),
              label: const Text('Review repeat foods'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reviewRepeatFoods() async {
    final summary = widget.summary;
    if (summary != null) {
      await ref.read(analyticsRepositoryProvider).track(
        'weekly_checkin_action_tapped',
        properties: {
          'action_id': summary.actionId,
          'week_start': _weekKey(summary.weekStart),
        },
      );
    }
    widget.onReviewRepeatFoods?.call();
  }

  void _trackView() {
    final summary = widget.summary;
    if (summary == null) return;
    final key = _weekKey(summary.weekStart);
    if (_trackedWeek == key) return;
    _trackedWeek = key;
    ref.read(analyticsRepositoryProvider).track(
      'weekly_checkin_viewed',
      properties: {
        'week_start': key,
        'status': summary.status,
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _weekKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
