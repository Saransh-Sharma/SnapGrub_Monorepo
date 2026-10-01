import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/milestones/domain/milestone.dart';
import 'package:snapgrub/features/milestones/domain/streak.dart';

/// Maps a streak tier to a medal tier (null for no streak).
MilestoneTier? medalTierForStreak(StreakTier tier) => switch (tier) {
      StreakTier.none => null,
      StreakTier.silver => MilestoneTier.silver,
      StreakTier.copper => MilestoneTier.copper,
      StreakTier.gold => MilestoneTier.gold,
      StreakTier.holo => MilestoneTier.holo,
    };

/// A round medal.
///
/// * Earned: a tilt-lit [MetalSurface] disc in the tier's metal with an
///   embossed icon; holo medals add a [HoloFoil] layer.
/// * Locked ([tier] null or [earned] false): a debossed porcelain silhouette.
///
/// Set [live] to false in grids and lists: the medal still renders its metal
/// (a single static frame) but runs no ticker and ignores tilt, which keeps the
/// number of continuously animated effects on screen within budget.
class MilestoneMedal extends StatelessWidget {
  const MilestoneMedal({
    required this.icon,
    this.tier,
    this.earned = true,
    this.size = 64,
    this.live = true,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final MilestoneTier? tier;
  final bool earned;
  final double size;
  final bool live;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tier = this.tier;
    final Widget medal =
        earned && tier != null ? _metal(context, tier) : _porcelain(context);
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: SizedBox.square(dimension: size, child: medal),
    );
  }

  Widget _metal(BuildContext context, MilestoneTier tier) {
    final metal = tier.metal;
    Widget disc = MetalSurface(
      metal: metal,
      shape: MetalShape.disc,
      child: Center(
        child: Container(
          width: size * .78,
          height: size * .78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: metal.shadow.withValues(alpha: .32),
              width: size < 48 ? 1 : 1.4,
            ),
          ),
          child:
              Center(child: _Emboss(icon: icon, size: size * .4, metal: metal)),
        ),
      ),
    );
    if (tier == MilestoneTier.holo) {
      disc = HoloFoil(borderRadius: size / 2, intensity: .9, child: disc);
    }
    disc = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: metal.shadow.withValues(alpha: .35),
            blurRadius: size * .18,
            offset: Offset(0, size * .06),
          ),
        ],
      ),
      child: disc,
    );
    return live ? disc : TickerMode(enabled: false, child: disc);
  }

  Widget _porcelain(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = context.sg.dark;
    final base = scheme.surfaceContainerHighest;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
                Colors.black.withValues(alpha: dark ? .35 : .09), base),
            Color.alphaBlend(
                Colors.white.withValues(alpha: dark ? .06 : .7), base),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * .07),
        child: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: base),
          child: Center(
            child: Icon(
              icon,
              size: size * .38,
              color: scheme.outline.withValues(alpha: .45),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon stamped into metal: a highlight edge below-right and a dark face.
class _Emboss extends StatelessWidget {
  const _Emboss({required this.icon, required this.size, required this.metal});

  final IconData icon;
  final double size;
  final SgMetal metal;

  @override
  Widget build(BuildContext context) {
    final nudge = size * .04;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(nudge, nudge),
          child: Icon(icon,
              size: size, color: metal.highlight.withValues(alpha: .7)),
        ),
        Icon(icon, size: size, color: metal.shadow.withValues(alpha: .88)),
      ],
    );
  }
}

/// Accessible one-line description of a medal.
String medalSemantics(MilestoneStatus status) {
  final def = status.definition;
  if (!status.earned) return '${def.title}, locked. ${def.howTo}';
  final at = status.earnedAt;
  return at == null
      ? '${def.title}, ${def.tier.label.toLowerCase()} medal, earned'
      : '${def.title}, ${def.tier.label.toLowerCase()} medal, earned '
          '${DateFormat('d MMMM y').format(at)}';
}
