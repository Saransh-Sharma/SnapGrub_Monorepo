import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/data/repositories/analytics_repository.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/insights/application/smart_food_draft_factory.dart';
import 'package:snapgrub/features/insights/domain/smart_food_suggestion.dart';

class SmartFoodsSection extends ConsumerStatefulWidget {
  const SmartFoodsSection({
    required this.suggestions,
    required this.contextData,
    this.maxItems,
    this.showHeader = true,
    super.key,
  });

  final List<SmartFoodSuggestion> suggestions;
  final HomeUserContext contextData;
  final int? maxItems;
  final bool showHeader;

  @override
  ConsumerState<SmartFoodsSection> createState() => _SmartFoodsSectionState();
}

class _SmartFoodsSectionState extends ConsumerState<SmartFoodsSection> {
  final _trackedViews = <String>{};

  @override
  void didUpdateWidget(covariant SmartFoodsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _trackVisibleSuggestions();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _trackVisibleSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.suggestions
        .take(widget.maxItems ?? widget.suggestions.length)
        .toList(growable: false);
    if (visible.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.repeat),
          title: Text('Smart repeats'),
          subtitle:
              Text('Repeat foods will appear here after a few logged meals.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Text('Smart repeats', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        for (var i = 0; i < visible.length; i++)
          _SmartFoodTile(
            suggestion: visible[i],
            rank: i + 1,
            onReview: () => _openSuggestion(visible[i], rank: i + 1),
          ),
      ],
    );
  }

  Future<void> _openSuggestion(
    SmartFoodSuggestion suggestion, {
    required int rank,
  }) async {
    await ref.read(analyticsRepositoryProvider).track(
      'smart_food_suggestion_opened',
      properties: {
        'origin': smartFoodOriginName(suggestion.origin),
        'rank': rank,
        'suggestion_id': suggestion.id,
      },
    );
    if (!mounted) return;
    final draft = const SmartFoodDraftFactory().toDraft(
      suggestion: suggestion,
      userId: widget.contextData.userId,
      timezone: widget.contextData.timezone,
      now: DateTime.now(),
    );
    context.go('/meal-editor', extra: draft);
  }

  void _trackVisibleSuggestions() {
    final visible = widget.suggestions
        .take(widget.maxItems ?? widget.suggestions.length)
        .toList(growable: false);
    for (var i = 0; i < visible.length; i++) {
      final suggestion = visible[i];
      if (!_trackedViews.add(suggestion.id)) continue;
      ref.read(analyticsRepositoryProvider).track(
        'smart_food_suggestion_viewed',
        properties: {
          'origin': smartFoodOriginName(suggestion.origin),
          'rank': i + 1,
          'meal_type_hint': suggestion.mealTypeHint?.name,
        },
      );
    }
  }
}

class _SmartFoodTile extends StatelessWidget {
  const _SmartFoodTile({
    required this.suggestion,
    required this.rank,
    required this.onReview,
  });

  final SmartFoodSuggestion suggestion;
  final int rank;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(rank.toString())),
        title: Text(suggestion.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${suggestion.reasonLabel} · ${suggestion.caloriesKcal.round()} kcal',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton(
          onPressed: onReview,
          child: const Text('Review'),
        ),
        onTap: onReview,
      ),
    );
  }
}
