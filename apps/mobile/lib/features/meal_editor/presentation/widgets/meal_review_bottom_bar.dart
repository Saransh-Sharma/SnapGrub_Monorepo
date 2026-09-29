import 'package:flutter/material.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';

/// Sticky footer: running totals and the primary Log / Save action.
class MealReviewBottomBar extends StatelessWidget {
  const MealReviewBottomBar({
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.actionLabel,
    required this.saving,
    required this.onSave,
    this.errorMessage,
    super.key,
  });

  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String actionLabel;
  final bool saving;
  final VoidCallback? onSave;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.sg;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.4;

    final summary = Semantics(
      label: '${caloriesKcal.round()} calories. Protein ${proteinG.round()} '
          'grams, carbs ${carbsG.round()} grams, fat ${fatG.round()} grams',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Labels.kcal(caloriesKcal),
            style: tokens.metricSmall.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            'P ${proteinG.round()} g · C ${carbsG.round()} g · '
            'F ${fatG.round()} g',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    final button = E2eId(
      id: 'meal.save',
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(140, 52),
        ),
        onPressed: saving ? null : onSave,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saving) ...[
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onSurface.withValues(alpha: .6),
                ),
              ),
              const SizedBox(width: SnapGrubDesignTokens.space8),
            ] else ...[
              const Icon(Icons.check_rounded, size: SnapGrubDesignTokens.iconMd),
              const SizedBox(width: SnapGrubDesignTokens.space8),
            ],
            Text(saving ? 'Saving…' : actionLabel),
          ],
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
        ),
        boxShadow: tokens.elevation2,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          SnapGrubDesignTokens.space16,
          SnapGrubDesignTokens.space12,
          SnapGrubDesignTokens.space16,
          SnapGrubDesignTokens.space12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null) ...[
              InlineError(message: errorMessage!),
              const SizedBox(height: SnapGrubDesignTokens.space12),
            ],
            if (stacked) ...[
              summary,
              const SizedBox(height: SnapGrubDesignTokens.space12),
              button,
            ] else
              Row(
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: SnapGrubDesignTokens.space12),
                  button,
                ],
              ),
          ],
        ),
      ),
    );
  }
}
