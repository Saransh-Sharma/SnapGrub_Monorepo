import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/progress/domain/intake_summary.dart';

/// Average protein / carbs / fat per logged day as three liquid rings
/// against the user's targets. Without targets the rings stay empty and the
/// averages are still shown (no invented defaults).
class MacroAveragesCard extends StatelessWidget {
  const MacroAveragesCard({
    required this.summary,
    required this.targets,
    super.key,
  });

  final IntakeSummary summary;
  final ProgressTargets targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SgCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Text('Macro averages', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('Per logged day',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MacroRing(
                  macro: Macro.protein,
                  average: summary.avgProteinG,
                  target: targets.proteinG,
                ),
              ),
              Expanded(
                child: _MacroRing(
                  macro: Macro.carbs,
                  average: summary.avgCarbsG,
                  target: targets.carbsG,
                ),
              ),
              Expanded(
                child: _MacroRing(
                  macro: Macro.fat,
                  average: summary.avgFatG,
                  target: targets.fatG,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRing extends StatelessWidget {
  const _MacroRing({
    required this.macro,
    required this.average,
    required this.target,
  });

  final Macro macro;
  final double average;
  final double? target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final palette = tokens.macro(macro);
    final t = target != null && target! > 0 ? target : null;
    final progress = t == null ? 0.0 : average / t;
    final name = macroLabel(macro);
    return Column(
      children: [
        SgRing(
          progress: progress,
          color: palette.color,
          size: 84,
          thickness: 9,
          liquid: true,
          semanticsLabel: '$name average',
          semanticsValue: t == null
              ? '${average.round()} grams, no target set'
              : '${average.round()} of ${t.round()} grams, '
                  '${(progress * 100).round()} percent',
          child: FittedBox(
            child: Text(
              '${average.round()} g',
              style: tokens.metricSmall,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: theme.textTheme.labelLarge),
        Text(
          t == null ? 'No target' : 'of ${t.round()} g',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
