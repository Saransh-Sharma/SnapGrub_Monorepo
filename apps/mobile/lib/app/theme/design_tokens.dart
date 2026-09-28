import 'package:flutter/material.dart';

class SnapGrubDesignTokens {
  const SnapGrubDesignTokens._();

  static const porcelain = Color(0xFFF7F2E9);
  static const porcelainDeep = Color(0xFFEDE5D8);
  static const paper = Color(0xFFFFFCF7);
  static const ink = Color(0xFF201E1A);
  static const inkMuted = Color(0xFF706B62);
  static const sage = Color(0xFF405D49);
  static const sageSoft = Color(0xFFDDE8DE);
  static const persimmon = Color(0xFFE27852);
  static const gold = Color(0xFFD0A64A);
  static const border = Color(0xFFD9D0C2);
  static const mist = Color(0xFFE7EFE6);
  static const blush = Color(0xFFF4D9CA);

  // Evolved palette (design system v2).
  static const inkHero = Color(0xFF161814);
  static const onInkHero = Color(0xFFF6F1E7);
  static const inkHeroMuted = Color(0xFFA7A396);
  static const outlineStrong = Color(0xFFA39A8B);
  static const slate = Color(0xFF6F86A8);
  static const persimmonDeep = Color(0xFFB9532F);
  static const goldDeep = Color(0xFF8A6A1F);
  static const success = Color(0xFF3F7D55);
  static const warning = Color(0xFFC98A1B);
  static const info = Color(0xFF4F7195);

  static const night = Color(0xFF111310);
  static const nightRaised = Color(0xFF1C1F1A);
  static const nightPaper = Color(0xFF252820);
  static const nightBorder = Color(0xFF3D4038);
  static const nightHero = Color(0xFF1F231D);
  static const nightPrimary = Color(0xFFA9C8AD);
  static const nightSecondary = Color(0xFFF0A17E);
  static const nightOnSurface = Color(0xFFF3F0E8);
  static const nightOnSurfaceMuted = Color(0xFFB8B8AE);
  static const nightPrimaryContainer = Color(0xFF314438);
  static const nightSecondaryContainer = Color(0xFF53362B);
  static const nightOutlineStrong = Color(0xFF6B6E63);
  static const nightMistGlow = Color(0xFF58705D);
  static const nightBlushGlow = Color(0xFF8B5745);

  // Compatibility aliases used by the existing feature surfaces.
  static const surface = porcelain;
  static const surfaceRaised = paper;
  static const textPrimary = ink;
  static const accent = sage;

  static const radiusXs = 12.0;
  static const radiusSm = 18.0;
  static const radiusMd = 24.0;
  static const radiusLg = 32.0;
  static const radiusXl = 40.0;
  static const radiusPill = 999.0;

  // Spacing scale (v2): 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40.
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const space40 = 40.0;

  static const iconSm = 16.0;
  static const iconMd = 20.0;
  static const iconLg = 24.0;
  static const iconXl = 32.0;

  static const spaceXs = 6.0;
  static const spaceSm = 10.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const spaceXl = 32.0;

  static const maxConversationWidth = 720.0;
  static const maxContentWidth = 840.0;
  static const minTapTarget = 48.0;

  static const lightBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [porcelain, Color(0xFFF9F5EE), porcelainDeep],
    stops: [0, .58, 1],
  );

  static const darkBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [night, Color(0xFF161914), Color(0xFF0D0F0C)],
    stops: [0, .62, 1],
  );
}
