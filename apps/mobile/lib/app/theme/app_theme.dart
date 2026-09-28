import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

const _sans = 'Geist';
const _serif = 'InstrumentSerif';

ThemeData buildSnapGrubTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final tokens = SnapGrubTokens.resolve(brightness);
  final paper =
      dark ? SnapGrubDesignTokens.nightPaper : SnapGrubDesignTokens.paper;
  final raised =
      dark ? SnapGrubDesignTokens.nightRaised : SnapGrubDesignTokens.paper;
  final scheme = ColorScheme.fromSeed(
    seedColor: SnapGrubDesignTokens.sage,
    brightness: brightness,
  ).copyWith(
    primary:
        dark ? SnapGrubDesignTokens.nightPrimary : SnapGrubDesignTokens.sage,
    secondary: dark
        ? SnapGrubDesignTokens.nightSecondary
        : SnapGrubDesignTokens.persimmon,
    tertiary: dark ? const Color(0xFFE6C06A) : SnapGrubDesignTokens.goldDeep,
    surface: dark ? SnapGrubDesignTokens.night : SnapGrubDesignTokens.porcelain,
    surfaceContainerLowest:
        dark ? const Color(0xFF0D0F0C) : SnapGrubDesignTokens.paper,
    surfaceContainerLow:
        dark ? const Color(0xFF171A15) : const Color(0xFFFBF7F0),
    surfaceContainer: raised,
    surfaceContainerHigh:
        dark ? SnapGrubDesignTokens.nightPaper : const Color(0xFFF1EADF),
    surfaceContainerHighest:
        dark ? const Color(0xFF2E3229) : SnapGrubDesignTokens.porcelainDeep,
    outline: tokens.outlineStrong,
    outlineVariant:
        dark ? SnapGrubDesignTokens.nightBorder : SnapGrubDesignTokens.border,
    onSurface: dark
        ? SnapGrubDesignTokens.nightOnSurface
        : SnapGrubDesignTokens.ink,
    onSurfaceVariant: dark
        ? SnapGrubDesignTokens.nightOnSurfaceMuted
        : SnapGrubDesignTokens.inkMuted,
    primaryContainer: dark
        ? SnapGrubDesignTokens.nightPrimaryContainer
        : SnapGrubDesignTokens.sageSoft,
    secondaryContainer: dark
        ? SnapGrubDesignTokens.nightSecondaryContainer
        : SnapGrubDesignTokens.blush,
    inverseSurface: dark ? SnapGrubDesignTokens.paper : tokens.hero,
    onInverseSurface: dark ? SnapGrubDesignTokens.ink : tokens.onHero,
  );

  final base = ThemeData(brightness: brightness).textTheme.apply(
        fontFamily: _sans,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      );
  TextStyle serif(TextStyle? style, double size, double spacing) =>
      (style ?? const TextStyle()).copyWith(
        fontFamily: _serif,
        fontSize: size,
        height: 1.05,
        fontWeight: FontWeight.w400,
        letterSpacing: spacing,
      );
  final textTheme = base.copyWith(
    displayLarge: serif(base.displayLarge, 56, -1.4),
    displayMedium: serif(base.displayMedium, 48, -1.1),
    displaySmall: serif(base.displaySmall, 42, -0.8),
    headlineLarge: serif(base.headlineLarge, 38, -0.6),
    headlineMedium: serif(base.headlineMedium, 32, -0.4),
    headlineSmall: serif(base.headlineSmall, 26, -0.2),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.45,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 17, height: 1.4),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 15, height: 1.38),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.35,
      letterSpacing: .05,
      color: scheme.onSurfaceVariant,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: .6,
    ),
  );

  const pill = StadiumBorder();
  final fieldRadius = BorderRadius.circular(SnapGrubDesignTokens.radiusSm);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: _sans,
    colorScheme: scheme,
    textTheme: textTheme,
    extensions: [tokens],
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: NoSplash.splashFactory,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: paper,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: pill,
        side: BorderSide(color: tokens.outlineStrong.withValues(alpha: .7)),
        foregroundColor: scheme.onSurface,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        highlightColor: scheme.primary.withValues(alpha: .08),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: tokens.hero,
      foregroundColor: tokens.onHero,
      elevation: 0,
      shape: pill,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
          borderRadius: fieldRadius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide:
              BorderSide(color: tokens.outlineStrong.withValues(alpha: .55))),
      focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.8)),
      filled: true,
      fillColor: paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(color: scheme.primary),
    ),
    listTileTheme: ListTileThemeData(
      minTileHeight: 60,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: textTheme.titleSmall?.copyWith(color: scheme.onSurface),
      subtitleTextStyle: textTheme.bodySmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusSm),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: raised,
      modalBackgroundColor: raised,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: .35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: raised,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusSm),
      ),
      textStyle: textTheme.bodyMedium,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.hero,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: tokens.onHero),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle:
          textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      actionTextColor: dark ? SnapGrubDesignTokens.sage : scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    chipTheme: ChipThemeData(
      shape: pill,
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: paper,
      selectedColor: scheme.primaryContainer,
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        shape: const WidgetStatePropertyAll(pill),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.onPrimary : null),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.primary : null),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Colors.transparent
              : tokens.outlineStrong),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: tokens.outlineStrong, width: 1.5),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: raised,
      surfaceTintColor: Colors.transparent,
      headerHeadlineStyle: textTheme.headlineMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: raised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primary.withValues(alpha: .10),
      circularTrackColor: scheme.primary.withValues(alpha: .10),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: .20),
      selectionHandleColor: scheme.primary,
    ),
    dividerColor: scheme.outlineVariant.withValues(alpha: 0.65),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.65),
      space: 1,
      thickness: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
