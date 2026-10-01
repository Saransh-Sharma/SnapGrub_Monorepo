import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/core/design_system/design_system.dart';

/// Protein · Carbs · Fat cards with liquid rings. The first time a macro
/// reaches its target on a day, its ring catches a one-time metal glint.
class MacroCardsRow extends StatelessWidget {
  const MacroCardsRow({
    required this.day,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.proteinGoal,
    this.carbsGoal,
    this.fatGoal,
    super.key,
  });

  final DateTime day;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? proteinGoal;
  final double? carbsGoal;
  final double? fatGoal;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.35;
    final cards = [
      _MacroCard(
          day: day, macro: Macro.protein, grams: proteinG, goal: proteinGoal),
      _MacroCard(day: day, macro: Macro.carbs, grams: carbsG, goal: carbsGoal),
      _MacroCard(day: day, macro: Macro.fat, grams: fatG, goal: fatGoal),
    ];
    if (large) {
      return Column(
        children: [
          for (final card in cards)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _MacroCard extends StatefulWidget {
  const _MacroCard({
    required this.day,
    required this.macro,
    required this.grams,
    required this.goal,
  });

  final DateTime day;
  final Macro macro;
  final double grams;
  final double? goal;

  @override
  State<_MacroCard> createState() => _MacroCardState();
}

class _MacroCardState extends State<_MacroCard>
    with SingleTickerProviderStateMixin {
  static final Set<String> _glinted = {};
  late final AnimationController _glint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  final ValueNotifier<double> _glintValue = ValueNotifier(-1);

  @override
  void initState() {
    super.initState();
    _glint.addListener(() {
      _glintValue.value = _glint.isAnimating ? _glint.value : -1;
    });
  }

  @override
  void didUpdateWidget(covariant _MacroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final goal = widget.goal;
    if (goal == null || goal <= 0) return;
    final crossed = oldWidget.grams < goal && widget.grams >= goal;
    if (crossed) _maybeGlint();
  }

  Future<void> _maybeGlint() async {
    final key =
        'glint.${widget.macro.name}.${DateUtils.dateOnly(widget.day).toIso8601String()}';
    if (_glinted.contains(key)) return;
    _glinted.add(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) ?? false) return;
      await prefs.setBool(key, true);
    } catch (_) {}
    if (!mounted || !SgEffectsScope.of(context).animates) return;
    SgHaptics.tick();
    _glint.forward(from: 0);
  }

  @override
  void dispose() {
    _glint.dispose();
    _glintValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    final palette = tokens.macro(widget.macro);
    final goal = widget.goal;
    final hasGoal = goal != null && goal > 0;
    final progress = hasGoal ? widget.grams / goal : 0.0;
    final left = hasGoal ? math.max(0, goal - widget.grams) : 0;
    final over = hasGoal && widget.grams > goal;
    final label = macroLabel(widget.macro);
    final status = !hasGoal
        ? '${widget.grams.round()} g'
        : over
            ? '${(widget.grams - goal).round()} g over'
            : '${left.round()} g left';

    return SgCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      semanticLabel: hasGoal
          ? '$label ${widget.grams.round()} of ${goal.round()} grams, '
              '${over ? '${(widget.grams - goal).round()} grams over' : '${left.round()} grams left'}'
          : '$label ${widget.grams.round()} grams',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox.square(
                dimension: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SgRing(
                      size: 64,
                      thickness: 7,
                      progress: progress,
                      liquid: true,
                      color: palette.color,
                      trackColor: palette.soft,
                      child: FittedBox(
                        child: Text(
                          '${widget.grams.round()}',
                          style: tokens.metricSmall
                              .copyWith(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _glintValue,
                        builder: (context, value, _) => value < 0
                            ? const SizedBox.shrink()
                            : MetalSurface(
                                metal: palette.metal,
                                shape: MetalShape.ring,
                                ringWidth: .2,
                                glint: _glintValue,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: over ? tokens.overTarget : theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (hasGoal)
              Text(
                'of ${goal.round()} g',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}
