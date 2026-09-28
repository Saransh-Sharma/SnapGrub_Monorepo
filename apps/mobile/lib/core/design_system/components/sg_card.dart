import 'package:flutter/material.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/app/theme/premium_surfaces.dart';
import 'package:snapgrub/core/design_system/effects/sg_effects.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

enum SgCardVariant { flat, raised, hero, glass, metalRim }

/// The single card primitive. Variants:
/// * flat — paper with a hairline (default content card)
/// * raised — paper with soft elevation (interactive / floating content)
/// * hero — dark ink surface for the one big number on a screen
/// * glass — frosted, for navigation chrome only
/// * metalRim — hero with a thin tilt-lit metal edge (rare, earned moments)
class SgCard extends StatelessWidget {
  const SgCard({
    required this.child,
    this.variant = SgCardVariant.flat,
    this.padding = const EdgeInsets.all(SnapGrubDesignTokens.space16),
    this.radius = SnapGrubDesignTokens.radiusMd,
    this.onTap,
    this.semanticLabel,
    this.metal = SgMetal.titanium,
    this.color,
    super.key,
  });

  final Widget child;
  final SgCardVariant variant;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final SgMetal metal;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final scheme = Theme.of(context).colorScheme;
    final shape = BorderRadius.circular(radius);
    final paper = Theme.of(context).cardTheme.color ?? scheme.surfaceContainer;

    Widget body;
    switch (variant) {
      case SgCardVariant.flat:
      case SgCardVariant.raised:
        body = DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? paper,
            borderRadius: shape,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .8),
            ),
            boxShadow:
                variant == SgCardVariant.raised ? tokens.elevation1 : null,
          ),
          child: Padding(padding: padding, child: child),
        );
      case SgCardVariant.hero:
        body = DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? tokens.hero,
            borderRadius: shape,
            boxShadow: tokens.elevation2,
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: tokens.onHero),
            child: IconTheme.merge(
              data: IconThemeData(color: tokens.onHero),
              child: Padding(padding: padding, child: child),
            ),
          ),
        );
      case SgCardVariant.glass:
        body = LiquidGlass(
          borderRadius: radius,
          padding: padding,
          child: child,
        );
      case SgCardVariant.metalRim:
        body = DecoratedBox(
          decoration:
              BoxDecoration(borderRadius: shape, boxShadow: tokens.elevation2),
          child: MetalSurface(
            metal: metal,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color ?? tokens.hero,
                  borderRadius: BorderRadius.circular(radius - 2),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: tokens.onHero),
                  child: IconTheme.merge(
                    data: IconThemeData(color: tokens.onHero),
                    child: Padding(padding: padding, child: child),
                  ),
                ),
              ),
            ),
          ),
        );
    }

    if (onTap == null) {
      return semanticLabel == null
          ? body
          : Semantics(label: semanticLabel, container: true, child: body);
    }
    return PremiumPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: body,
    );
  }
}

/// Section header: small caps label with an optional trailing action.
class SgSectionHeader extends StatelessWidget {
  const SgSectionHeader({
    required this.title,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(4, 20, 4, 10),
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}
