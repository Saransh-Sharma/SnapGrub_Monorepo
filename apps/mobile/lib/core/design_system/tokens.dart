import 'package:flutter/material.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';

/// A metallic material used by the metal shader and its gradient fallback.
@immutable
class SgMetal {
  const SgMetal({
    required this.name,
    required this.base,
    required this.highlight,
    required this.shadow,
  });

  final String name;
  final Color base;
  final Color highlight;
  final Color shadow;

  static const titanium = SgMetal(
    name: 'titanium',
    base: Color(0xFF8A958B),
    highlight: Color(0xFFE9EFE8),
    shadow: Color(0xFF3E4640),
  );
  static const gold = SgMetal(
    name: 'gold',
    base: Color(0xFFC9A24A),
    highlight: Color(0xFFFFF1C2),
    shadow: Color(0xFF6E5317),
  );
  static const copper = SgMetal(
    name: 'copper',
    base: Color(0xFFC06A48),
    highlight: Color(0xFFFFD2BC),
    shadow: Color(0xFF5E2A18),
  );
  static const silver = SgMetal(
    name: 'silver',
    base: Color(0xFFA7ABB0),
    highlight: Color(0xFFFFFFFF),
    shadow: Color(0xFF4A4E53),
  );
  static const slate = SgMetal(
    name: 'slate',
    base: Color(0xFF7E92B0),
    highlight: Color(0xFFE3ECF8),
    shadow: Color(0xFF34435A),
  );

  /// Gradient used when shaders are unavailable or effects are off.
  Gradient fallbackGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) =>
      LinearGradient(
        begin: begin,
        end: end,
        colors: [highlight, base, shadow, base],
        stops: const [0, .38, .78, 1],
      );
}

/// Colours for one macro nutrient.
@immutable
class MacroPalette {
  const MacroPalette({
    required this.color,
    required this.soft,
    required this.onSoft,
    required this.metal,
  });

  final Color color;
  final Color soft;
  final Color onSoft;
  final SgMetal metal;

  static MacroPalette lerp(MacroPalette a, MacroPalette b, double t) =>
      MacroPalette(
        color: Color.lerp(a.color, b.color, t)!,
        soft: Color.lerp(a.soft, b.soft, t)!,
        onSoft: Color.lerp(a.onSoft, b.onSoft, t)!,
        metal: t < .5 ? a.metal : b.metal,
      );
}

enum Macro { energy, protein, carbs, fat }

/// Time-of-day ambience used by the aurora backdrop and greetings.
enum DayPhase { dawn, noon, dusk, night }

DayPhase dayPhaseFor(DateTime time) {
  final h = time.hour;
  if (h >= 5 && h < 11) return DayPhase.dawn;
  if (h >= 11 && h < 17) return DayPhase.noon;
  if (h >= 17 && h < 21) return DayPhase.dusk;
  return DayPhase.night;
}

/// SnapGrub design-system tokens that Material's ColorScheme cannot express.
@immutable
class SnapGrubTokens extends ThemeExtension<SnapGrubTokens> {
  const SnapGrubTokens({
    required this.energy,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.success,
    required this.warning,
    required this.info,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.outlineStrong,
    required this.overTarget,
    required this.elevation1,
    required this.elevation2,
    required this.elevation3,
    required this.heroNumber,
    required this.metric,
    required this.metricSmall,
    required this.editorial,
    required this.dark,
  });

  final MacroPalette energy;
  final MacroPalette protein;
  final MacroPalette carbs;
  final MacroPalette fat;
  final Color success;
  final Color warning;
  final Color info;
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;
  final Color outlineStrong;

  /// Neutral colour for overflow beyond a target (never an error colour).
  final Color overTarget;
  final List<BoxShadow> elevation1;
  final List<BoxShadow> elevation2;
  final List<BoxShadow> elevation3;
  final TextStyle heroNumber;
  final TextStyle metric;
  final TextStyle metricSmall;

  /// Serif italic used for warm editorial emphasis ("nice balance").
  final TextStyle editorial;
  final bool dark;

  MacroPalette macro(Macro macro) => switch (macro) {
        Macro.energy => energy,
        Macro.protein => protein,
        Macro.carbs => carbs,
        Macro.fat => fat,
      };

  /// Aurora colours for a phase of the day.
  List<Color> ambience(DayPhase phase) {
    if (dark) {
      return switch (phase) {
        DayPhase.dawn => const [
            Color(0xFF1B1F1A),
            Color(0xFF2A211D),
            Color(0xFF141713),
            Color(0xFF1E261F)
          ],
        DayPhase.noon => const [
            Color(0xFF172019),
            Color(0xFF1E231C),
            Color(0xFF121411),
            Color(0xFF232019)
          ],
        DayPhase.dusk => const [
            Color(0xFF2A1C16),
            Color(0xFF1E1F1A),
            Color(0xFF131412),
            Color(0xFF2B2117)
          ],
        DayPhase.night => const [
            Color(0xFF111512),
            Color(0xFF18201B),
            Color(0xFF0D0F0C),
            Color(0xFF161B1D)
          ],
      };
    }
    return switch (phase) {
      DayPhase.dawn => const [
          Color(0xFFF9E7DA),
          Color(0xFFF7F2E9),
          Color(0xFFE9F0E6),
          Color(0xFFF5E4D0)
        ],
      DayPhase.noon => const [
          Color(0xFFF7F2E9),
          Color(0xFFE7EFE6),
          Color(0xFFFBF7F0),
          Color(0xFFEDE5D8)
        ],
      DayPhase.dusk => const [
          Color(0xFFF6D9C6),
          Color(0xFFF4E5D2),
          Color(0xFFEFE6DA),
          Color(0xFFE8D2BF)
        ],
      DayPhase.night => const [
          Color(0xFFE3E8E0),
          Color(0xFFEDE8DF),
          Color(0xFFDCE3DD),
          Color(0xFFE9E1D6)
        ],
    };
  }

  static SnapGrubTokens resolve(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    const tabular = [FontFeature.tabularFigures()];
    final numberColor =
        dark ? SnapGrubDesignTokens.nightOnSurface : SnapGrubDesignTokens.ink;
    return SnapGrubTokens(
      dark: dark,
      energy: MacroPalette(
        color: dark
            ? SnapGrubDesignTokens.nightPrimary
            : SnapGrubDesignTokens.sage,
        soft: dark
            ? SnapGrubDesignTokens.nightPrimaryContainer
            : SnapGrubDesignTokens.sageSoft,
        onSoft: dark
            ? SnapGrubDesignTokens.nightOnSurface
            : SnapGrubDesignTokens.sage,
        metal: SgMetal.titanium,
      ),
      protein: MacroPalette(
        color: dark
            ? SnapGrubDesignTokens.nightSecondary
            : SnapGrubDesignTokens.persimmon,
        soft: dark
            ? SnapGrubDesignTokens.nightSecondaryContainer
            : const Color(0xFFFBE3D9),
        onSoft:
            dark ? const Color(0xFFFFD8C7) : SnapGrubDesignTokens.persimmonDeep,
        metal: SgMetal.copper,
      ),
      carbs: MacroPalette(
        color: dark ? const Color(0xFFE6C06A) : SnapGrubDesignTokens.gold,
        soft: dark ? const Color(0xFF4A3D1C) : const Color(0xFFF6ECCF),
        onSoft: dark ? const Color(0xFFF7E3B0) : SnapGrubDesignTokens.goldDeep,
        metal: SgMetal.gold,
      ),
      fat: MacroPalette(
        color: dark ? const Color(0xFF9DB2D2) : SnapGrubDesignTokens.slate,
        soft: dark ? const Color(0xFF28334A) : const Color(0xFFE2E8F1),
        onSoft: dark ? const Color(0xFFD7E2F3) : const Color(0xFF3F5575),
        metal: SgMetal.slate,
      ),
      success: dark ? const Color(0xFF8FC9A0) : SnapGrubDesignTokens.success,
      warning: dark ? const Color(0xFFF0C067) : SnapGrubDesignTokens.warning,
      info: dark ? const Color(0xFF9DB9DC) : SnapGrubDesignTokens.info,
      hero:
          dark ? SnapGrubDesignTokens.nightHero : SnapGrubDesignTokens.inkHero,
      onHero: SnapGrubDesignTokens.onInkHero,
      onHeroMuted: SnapGrubDesignTokens.inkHeroMuted,
      outlineStrong: dark
          ? SnapGrubDesignTokens.nightOutlineStrong
          : SnapGrubDesignTokens.outlineStrong,
      overTarget: dark ? const Color(0xFFD8D4C8) : const Color(0xFF4A463F),
      elevation1: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? .28 : .05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      elevation2: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? .34 : .08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        if (!dark)
          BoxShadow(
            color: Colors.white.withValues(alpha: .28),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
      ],
      elevation3: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? .45 : .14),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ],
      heroNumber: TextStyle(
        fontFamily: 'Geist',
        fontSize: 64,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.4,
        fontFeatures: tabular,
        color: numberColor,
      ),
      metric: TextStyle(
        fontFamily: 'Geist',
        fontSize: 28,
        height: 1.05,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        fontFeatures: tabular,
        color: numberColor,
      ),
      metricSmall: TextStyle(
        fontFamily: 'Geist',
        fontSize: 17,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        fontFeatures: tabular,
        color: numberColor,
      ),
      editorial: TextStyle(
        fontFamily: 'InstrumentSerif',
        fontStyle: FontStyle.italic,
        fontSize: 22,
        height: 1.1,
        color: numberColor,
      ),
    );
  }

  @override
  SnapGrubTokens copyWith() => this;

  @override
  SnapGrubTokens lerp(ThemeExtension<SnapGrubTokens>? other, double t) {
    if (other is! SnapGrubTokens) return this;
    List<BoxShadow> shadows(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? b;
    return SnapGrubTokens(
      dark: t < .5 ? dark : other.dark,
      energy: MacroPalette.lerp(energy, other.energy, t),
      protein: MacroPalette.lerp(protein, other.protein, t),
      carbs: MacroPalette.lerp(carbs, other.carbs, t),
      fat: MacroPalette.lerp(fat, other.fat, t),
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      overTarget: Color.lerp(overTarget, other.overTarget, t)!,
      elevation1: shadows(elevation1, other.elevation1),
      elevation2: shadows(elevation2, other.elevation2),
      elevation3: shadows(elevation3, other.elevation3),
      heroNumber: TextStyle.lerp(heroNumber, other.heroNumber, t)!,
      metric: TextStyle.lerp(metric, other.metric, t)!,
      metricSmall: TextStyle.lerp(metricSmall, other.metricSmall, t)!,
      editorial: TextStyle.lerp(editorial, other.editorial, t)!,
    );
  }
}

extension SnapGrubTokensContext on BuildContext {
  /// Design-system tokens. Falls back to resolved defaults outside the app
  /// theme (for example in isolated widget tests).
  SnapGrubTokens get sg =>
      Theme.of(this).extension<SnapGrubTokens>() ??
      SnapGrubTokens.resolve(Theme.of(this).brightness);
}
