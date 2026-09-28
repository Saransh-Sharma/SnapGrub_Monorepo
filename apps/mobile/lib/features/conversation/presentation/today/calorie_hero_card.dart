import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/preferences/ui_preferences.dart';

/// The one big number on Today: calories left (or eaten) with a liquid ring
/// in a titanium bezel. Tap flips the framing; long-press shows the maths.
class CalorieHeroCard extends ConsumerStatefulWidget {
  const CalorieHeroCard({
    required this.eaten,
    required this.goal,
    required this.mealCount,
    super.key,
  });

  final double eaten;
  final double? goal;
  final int mealCount;

  @override
  ConsumerState<CalorieHeroCard> createState() => _CalorieHeroCardState();
}

class _CalorieHeroCardState extends ConsumerState<CalorieHeroCard> {
  bool _showEquation = false;

  void _flip() {
    SgHaptics.tick();
    final prefs = ref.read(uiPreferencesProvider);
    ref.read(uiPreferencesProvider.notifier).setCalorieFraming(
          prefs.calorieFraming == CalorieFraming.remaining
              ? CalorieFraming.eaten
              : CalorieFraming.remaining,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    final motion = SgMotion.of(context);
    final goal = widget.goal;
    final framing = ref.watch(uiPreferencesProvider).calorieFraming;
    final fmt = NumberFormat.decimalPattern();

    if (goal == null || goal <= 0) {
      return SgCard(
        variant: SgCardVariant.hero,
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RollingNumber(
                    value: widget.eaten.round(),
                    style: tokens.heroNumber.copyWith(color: tokens.onHero),
                    semanticsLabel: 'Calories eaten',
                  ),
                  Text('kcal today',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: tokens.onHeroMuted)),
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: () => context.push('/settings/goal'),
                    child: const Text('Set a calorie target'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final remaining = goal - widget.eaten;
    final over = remaining < 0;
    final progress = widget.eaten / goal;
    final showRemaining = framing == CalorieFraming.remaining;
    final value = showRemaining ? remaining.abs() : widget.eaten;
    final caption = showRemaining
        ? (over ? 'over' : 'left')
        : 'eaten';
    final sub = showRemaining
        ? 'Target ${fmt.format(goal.round())} · Eaten ${fmt.format(widget.eaten.round())}'
        : 'of ${fmt.format(goal.round())} · ${fmt.format(math.max(0, remaining).round())} left';
    final numberStyle = tokens.heroNumber.copyWith(
      color: tokens.onHero,
      fontSize: MediaQuery.textScalerOf(context).scale(1) > 1.4 ? 48 : 60,
    );

    return E2eId(
      id: 'today.calorie_hero',
      child: SgCard(
        variant: SgCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
        onTap: _flip,
        semanticLabel: showRemaining
            ? '${fmt.format(remaining.abs().round())} calories ${over ? 'over' : 'left'}. Target ${fmt.format(goal.round())}. Tap to show calories eaten.'
            : '${fmt.format(widget.eaten.round())} calories eaten. Target ${fmt.format(goal.round())}. Tap to show calories left.',
        child: GestureDetector(
          onLongPress: () {
            SgHaptics.impact();
            setState(() => _showEquation = !_showEquation);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showRemaining ? 'CALORIES' : 'EATEN TODAY',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.onHeroMuted,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: motion.settle,
                          transitionBuilder: (child, animation) =>
                              _FlipTransition(animation: animation, child: child),
                          child: Row(
                            key: ValueKey(framing),
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: RollingNumber(
                                    value: value.round(),
                                    style: numberStyle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                caption,
                                style: tokens.editorial.copyWith(
                                  color: over && showRemaining
                                      ? tokens.onHero
                                      : tokens.onHeroMuted,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sub,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: tokens.onHeroMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SgRing(
                    size: 104,
                    thickness: 11,
                    progress: progress,
                    liquid: true,
                    bezel: SgMetal.titanium,
                    // Sage lifted toward white so it glows on the ink hero.
                    color: Color.lerp(tokens.energy.color, Colors.white,
                        tokens.dark ? .1 : .42)!,
                    trackColor: tokens.onHero.withValues(alpha: .10),
                    semanticsLabel: 'Daily calories',
                    semanticsValue: '${(progress * 100).round()} percent',
                    child: Icon(
                      widget.mealCount == 0
                          ? Icons.restaurant_rounded
                          : Icons.local_fire_department_rounded,
                      color: tokens.onHeroMuted,
                      size: 26,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: motion.settle,
                curve: motion.standard,
                child: _showEquation
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _Equation(goal: goal, eaten: widget.eaten),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              if (over && showRemaining) ...[
                const SizedBox(height: 10),
                Text(
                  'Tomorrow’s a fresh start.',
                  style: tokens.editorial
                      .copyWith(color: tokens.onHeroMuted, fontSize: 17),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Equation extends StatelessWidget {
  const _Equation({required this.goal, required this.eaten});

  final double goal;
  final double eaten;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final fmt = NumberFormat.decimalPattern();
    final style = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(color: tokens.onHero, fontFeatures: const [FontFeature.tabularFigures()]);
    final muted = style?.copyWith(color: tokens.onHeroMuted);
    Widget cell(String value, String label) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: style),
            Text(label, style: muted?.copyWith(fontSize: 11)),
          ],
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.onHero.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          cell(fmt.format(goal.round()), 'Target'),
          Text('−', style: muted),
          cell(fmt.format(eaten.round()), 'Food'),
          Text('=', style: muted),
          cell(fmt.format((goal - eaten).round()), 'Left'),
        ],
      ),
    );
  }
}

class _FlipTransition extends StatelessWidget {
  const _FlipTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0015)
              ..rotateX((1 - t) * math.pi / 2.4),
            child: child,
          ),
        );
      },
    );
  }
}
