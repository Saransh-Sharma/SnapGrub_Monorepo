import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';

/// One answer to a food search. [offline] is true when the results come
/// from the phone's own foods because the catalog could not be reached.
class FoodSearchPage {
  const FoodSearchPage(this.results, {this.offline = false});

  final List<FoodSearchResultDto> results;
  final bool offline;
}

typedef FoodSearch = Future<FoodSearchPage> Function(String query);

/// Search the food catalog and the user's own foods in an SgSheet. Returns
/// the picked food, or null if the sheet is dismissed.
Future<FoodSearchResultDto?> showFoodSearchSheet(
  BuildContext context, {
  required FoodSearch search,
}) {
  return showSgSheet<FoodSearchResultDto>(
    context: context,
    title: 'Search foods',
    builder: (context) => FoodSearchSheet(search: search),
  );
}

class FoodSearchSheet extends StatefulWidget {
  const FoodSearchSheet({required this.search, super.key});

  final FoodSearch search;

  @override
  State<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<FoodSearchSheet> {
  static const _debounce = Duration(milliseconds: 350);
  static const _minQueryLength = 2;

  Timer? _timer;
  String _query = '';
  bool _loading = false;
  Object? _error;
  bool _offline = false;
  List<FoodSearchResultDto>? _results;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    final query = value.trim();
    _timer?.cancel();
    setState(() {
      _query = query;
      _error = null;
      if (query.length < _minQueryLength) {
        _results = null;
        _loading = false;
      } else {
        _loading = true;
      }
    });
    if (query.length < _minQueryLength) return;
    _timer = Timer(_debounce, () => _run(query));
  }

  Future<void> _run(String query) async {
    try {
      final page = await widget.search(query);
      // A newer query has been typed since this one was sent.
      if (!mounted || query != _query) return;
      setState(() {
        _results = page.results;
        _offline = page.offline;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || query != _query) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        E2eId(
          id: 'meal.food_search.field',
          child: TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            decoration: const InputDecoration(
              hintText: 'Food or brand',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space8),
        ..._buildBody(),
      ],
    );
  }

  List<Widget> _buildBody() {
    if (_query.length < _minQueryLength) {
      return const [
        EmptyState(
          compact: true,
          illustration: SgIllustrationKind.plate,
          title: 'Find a food',
          message: 'Type a name, like “dal” or “roti.”',
        ),
      ];
    }
    if (_loading) {
      return [
        Semantics(
          label: 'Searching',
          child: const Column(
            children: [
              SgSkeleton(height: 64, radius: SnapGrubDesignTokens.radiusXs),
              SizedBox(height: SnapGrubDesignTokens.space8),
              SgSkeleton(height: 64, radius: SnapGrubDesignTokens.radiusXs),
            ],
          ),
        ),
      ];
    }
    final error = _error;
    if (error != null) {
      return [
        EmptyState(
          compact: true,
          illustration: SgIllustrationKind.plate,
          title: 'Search didn’t load',
          message: friendlyError(error).message,
          actionLabel: 'Try again',
          onAction: () => _onChanged(_query),
        ),
      ];
    }
    final results = _results ?? const [];
    if (results.isEmpty) {
      return [
        EmptyState(
          compact: true,
          illustration: SgIllustrationKind.plate,
          title: 'No matches',
          message: _offline
              ? 'You’re offline, so only your own foods are searched.'
              : 'Nothing called “$_query.” Enter it manually instead.',
        ),
      ];
    }
    return [
      if (_offline) const _OfflineNote(),
      for (final food in results) _ResultRow(food: food),
    ];
  }
}

/// Says the list is the phone's own foods, not the full catalog.
class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SnapGrubDesignTokens.space8,
        vertical: SnapGrubDesignTokens.space4,
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded,
              size: SnapGrubDesignTokens.iconSm,
              color: scheme.onSurfaceVariant),
          const SizedBox(width: SnapGrubDesignTokens.space8),
          Expanded(
            child: Text(
              'Offline. Showing your foods.',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.food});

  final FoodSearchResultDto food;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final serving = [
      if (food.servingQuantity != null)
        '${formatNumber(food.servingQuantity, decimals: 2)} '
            '${food.servingUnit ?? 'serving'}',
      if (food.servingGrams != null) '${food.servingGrams!.round()} g',
    ].join(' · ');
    final brand = food.brand?.trim() ?? '';
    final subtitle = [
      Labels.kcal(food.caloriesKcal),
      if (serving.isNotEmpty) serving,
      if (brand.isNotEmpty) brand,
    ].join(' · ');
    final source = Labels.foodResult(food.resultType);
    void pick() {
      SgHaptics.tick();
      Navigator.of(context).pop(food);
    }

    return Semantics(
      button: true,
      label: '${food.name}, ${food.caloriesKcal.round()} calories, $source',
      onTap: pick,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
        onTap: pick,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              minHeight: SnapGrubDesignTokens.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SnapGrubDesignTokens.space8,
              vertical: SnapGrubDesignTokens.space12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: SnapGrubDesignTokens.space4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: SnapGrubDesignTokens.space4),
                      Text(
                        source,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: SnapGrubDesignTokens.space8),
                Icon(Icons.add_circle_outline_rounded, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
