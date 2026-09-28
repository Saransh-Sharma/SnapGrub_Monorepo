import 'package:flutter/material.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/custom_foods/domain/custom_food.dart';

/// Searchable list of the user's saved foods ("My foods") in an SgSheet.
Future<CustomFood?> showCustomFoodPicker(
  BuildContext context,
  List<CustomFood> foods,
) {
  return showSgSheet<CustomFood>(
    context: context,
    title: 'My foods',
    subtitle: foods.isEmpty ? null : 'Tap one to add it.',
    builder: (context) => CustomFoodPicker(foods: foods),
  );
}

class CustomFoodPicker extends StatefulWidget {
  const CustomFoodPicker({required this.foods, super.key});

  final List<CustomFood> foods;

  @override
  State<CustomFoodPicker> createState() => _CustomFoodPickerState();
}

class _CustomFoodPickerState extends State<CustomFoodPicker> {
  String _query = '';

  List<CustomFood> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.foods;
    return widget.foods
        .where((food) =>
            food.name.toLowerCase().contains(query) ||
            (food.brand?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.foods.isEmpty) {
      return const EmptyState(
        compact: true,
        illustration: SgIllustrationKind.notebook,
        title: 'No saved foods yet',
        message: 'Add foods in You › My foods.',
      );
    }
    final results = _filtered;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        E2eId(
          id: 'meal.custom_food.search',
          child: TextField(
            autofocus: widget.foods.length > 6,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search my foods',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space8),
        if (results.isEmpty)
          EmptyState(
            compact: true,
            illustration: SgIllustrationKind.plate,
            title: 'No matches',
            message: 'Nothing called “${_query.trim()}.”',
          )
        else
          for (final food in results) _FoodRow(food: food),
      ],
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food});

  final CustomFood food;

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
    final subtitle = [
      Labels.kcal(food.caloriesKcal),
      if (serving.isNotEmpty) serving,
      if (food.brand?.trim().isNotEmpty ?? false) food.brand!.trim(),
    ].join(' · ');
    void pick() {
      SgHaptics.tick();
      Navigator.of(context).pop(food);
    }

    return Semantics(
      button: true,
      label: '${food.name}, ${food.caloriesKcal.round()} calories',
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
                      const SizedBox(height: SnapGrubDesignTokens.space8),
                      MacroChips(
                        proteinG: food.proteinG,
                        carbsG: food.carbsG,
                        fatG: food.fatG,
                        dense: true,
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
