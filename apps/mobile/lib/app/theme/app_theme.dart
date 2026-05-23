import 'package:flutter/material.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';

ThemeData buildSnapGrubTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: SnapGrubDesignTokens.accent,
    brightness: Brightness.light,
    surface: SnapGrubDesignTokens.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SnapGrubDesignTokens.surface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: SnapGrubDesignTokens.surface,
      foregroundColor: SnapGrubDesignTokens.textPrimary,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: SnapGrubDesignTokens.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusSm),
        side: const BorderSide(color: SnapGrubDesignTokens.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusSm),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusSm),
      ),
      filled: true,
      fillColor: SnapGrubDesignTokens.surfaceRaised,
    ),
  );
}
