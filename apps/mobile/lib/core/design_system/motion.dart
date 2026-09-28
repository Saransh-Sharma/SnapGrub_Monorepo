import 'package:flutter/widgets.dart';
import 'package:snapgrub/app/theme/premium_motion.dart';

/// Spring presets. Mass is always 1.
class SgSprings {
  const SgSprings._();

  static const snappy =
      SpringDescription(mass: 1, stiffness: 500, damping: 30);
  static const bouncy =
      SpringDescription(mass: 1, stiffness: 300, damping: 15);
  static const gentle =
      SpringDescription(mass: 1, stiffness: 180, damping: 24);
}

/// Reduce-motion aware access to the motion tokens.
///
/// Every animation in the app should take its durations from here so a single
/// accessibility setting collapses motion to instant changes / crossfades.
@immutable
class SgMotion {
  const SgMotion._(this.reduced);

  factory SgMotion.of(BuildContext context) =>
      SgMotion._(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// True when the user asked the OS to reduce motion.
  final bool reduced;

  Duration get press => _d(PremiumMotion.press);
  Duration get settle => _d(PremiumMotion.settle);
  Duration get enter => _d(PremiumMotion.enter);
  Duration get reveal => _d(PremiumMotion.reveal);
  Duration get page => _d(PremiumMotion.page);
  Duration get linger => _d(PremiumMotion.linger);

  /// Custom durations routed through the same switch.
  Duration of(Duration duration) => _d(duration);

  Curve get standard => PremiumMotion.standard;
  Curve get emphasized => reduced ? PremiumMotion.standard : PremiumMotion.emphasized;
  Curve get gentle => PremiumMotion.gentle;

  /// Stagger delay for list entrance (max 8 staggered items).
  Duration stagger(int index) => reduced
      ? Duration.zero
      : Duration(milliseconds: 40 * index.clamp(0, 8));

  Duration _d(Duration value) => reduced ? Duration.zero : value;
}
