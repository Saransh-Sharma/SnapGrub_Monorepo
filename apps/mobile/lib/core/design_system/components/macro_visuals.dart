import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/motion.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

String macroLabel(Macro macro) => switch (macro) {
      Macro.energy => 'Calories',
      Macro.protein => 'Protein',
      Macro.carbs => 'Carbs',
      Macro.fat => 'Fat',
    };

String macroShort(Macro macro) => switch (macro) {
      Macro.energy => 'kcal',
      Macro.protein => 'P',
      Macro.carbs => 'C',
      Macro.fat => 'F',
    };

/// Compact P / C / F chips with fixed macro colours.
class MacroChips extends StatelessWidget {
  const MacroChips({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.dense = false,
    super.key,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final style = Theme.of(context).textTheme.labelMedium;
    Widget chip(Macro macro, double grams) {
      final palette = tokens.macro(macro);
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: dense ? 7 : 9, vertical: dense ? 3 : 5),
        decoration: BoxDecoration(
          color: palette.soft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${macroShort(macro)} ${grams.round()} g',
          style: style?.copyWith(
            color: palette.onSoft,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    return Semantics(
      label: 'Protein ${proteinG.round()} grams, carbs ${carbsG.round()} '
          'grams, fat ${fatG.round()} grams',
      excludeSemantics: true,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          chip(Macro.protein, proteinG),
          chip(Macro.carbs, carbsG),
          chip(Macro.fat, fatG),
        ],
      ),
    );
  }
}

/// Horizontal stacked bar showing the calorie share of each macro.
class MacroBar extends StatelessWidget {
  const MacroBar({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.height = 10,
    super.key,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final motion = SgMotion.of(context);
    final p = proteinG * 4;
    final c = carbsG * 4;
    final f = fatG * 9;
    final total = p + c + f;
    final segments = total <= 0
        ? const <(Macro, double)>[]
        : [(Macro.protein, p / total), (Macro.carbs, c / total), (Macro.fat, f / total)];
    return Semantics(
      label: total <= 0
          ? 'No macros yet'
          : 'Protein ${(p / total * 100).round()} percent, carbs '
              '${(c / total * 100).round()} percent, fat '
              '${(f / total * 100).round()} percent of calories',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 1.5;
                final usable = (constraints.maxWidth -
                        gap * math.max(0, segments.length - 1))
                    .clamp(0.0, double.infinity);
                return Row(
                  children: [
                    for (var i = 0; i < segments.length; i++)
                      AnimatedContainer(
                        duration: motion.reveal,
                        curve: motion.standard,
                        width: usable * segments[i].$2,
                        margin: EdgeInsets.only(
                            right: i == segments.length - 1 ? 0 : gap),
                        color: tokens.macro(segments[i].$1).color,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A small legend dot + label, used under charts and bars.
class MacroLegend extends StatelessWidget {
  const MacroLegend({required this.macro, required this.text, super.key});

  final Macro macro;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.sg.macro(macro);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: palette.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
