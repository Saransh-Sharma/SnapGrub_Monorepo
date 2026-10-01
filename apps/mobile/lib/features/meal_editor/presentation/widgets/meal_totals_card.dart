import 'package:flutter/material.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';

/// The one hero number on Meal Review: live calories plus the macro split.
class MealTotalsCard extends StatelessWidget {
  const MealTotalsCard({
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    super.key,
  });

  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    final muted =
        theme.textTheme.labelLarge?.copyWith(color: tokens.onHeroMuted);
    return E2eId(
      id: 'meal.totals',
      child: SgCard(
        variant: SgCardVariant.hero,
        padding: const EdgeInsets.all(SnapGrubDesignTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total', style: muted),
            const SizedBox(height: SnapGrubDesignTokens.space8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RollingNumber(
                      value: caloriesKcal.round(),
                      semanticsLabel: 'Total calories',
                      style: tokens.heroNumber.copyWith(
                        color: tokens.onHero,
                        fontSize: 52,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: SnapGrubDesignTokens.space8),
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: SnapGrubDesignTokens.space4),
                  child: ExcludeSemantics(child: Text('kcal', style: muted)),
                ),
              ],
            ),
            const SizedBox(height: SnapGrubDesignTokens.space16),
            MacroBar(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            Wrap(
              spacing: SnapGrubDesignTokens.space20,
              runSpacing: SnapGrubDesignTokens.space8,
              children: [
                _MacroValue(macro: Macro.protein, grams: proteinG),
                _MacroValue(macro: Macro.carbs, grams: carbsG),
                _MacroValue(macro: Macro.fat, grams: fatG),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroValue extends StatelessWidget {
  const _MacroValue({required this.macro, required this.grams});

  final Macro macro;
  final double grams;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    return Semantics(
      label: '${macroLabel(macro)} ${grams.round()} grams',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: tokens.macro(macro).color, shape: BoxShape.circle),
          ),
          const SizedBox(width: SnapGrubDesignTokens.space8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${macroLabel(macro)} ',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: tokens.onHeroMuted),
                  ),
                  TextSpan(
                    text: '${grams.round()} g',
                    style: tokens.metricSmall.copyWith(color: tokens.onHero),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Calorie share of each macro as a stacked bar. Mirrors [MacroBar] but
/// subtracts the hairline gaps from the available width so the segments
/// never overflow.
