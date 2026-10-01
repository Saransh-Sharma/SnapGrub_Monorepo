import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How much GPU/motion richness the user wants.
enum VisualEffectsLevel { full, reduced, off }

/// Whether the calorie hero shows what is left or what was eaten.
enum CalorieFraming { remaining, eaten }

@immutable
class UiPreferences {
  const UiPreferences({
    this.themeMode = ThemeMode.system,
    this.effects = VisualEffectsLevel.full,
    this.haptics = true,
    this.calorieFraming = CalorieFraming.remaining,
  });

  final ThemeMode themeMode;
  final VisualEffectsLevel effects;
  final bool haptics;
  final CalorieFraming calorieFraming;

  UiPreferences copyWith({
    ThemeMode? themeMode,
    VisualEffectsLevel? effects,
    bool? haptics,
    CalorieFraming? calorieFraming,
  }) =>
      UiPreferences(
        themeMode: themeMode ?? this.themeMode,
        effects: effects ?? this.effects,
        haptics: haptics ?? this.haptics,
        calorieFraming: calorieFraming ?? this.calorieFraming,
      );
}

final uiPreferencesProvider =
    NotifierProvider<UiPreferencesController, UiPreferences>(
  UiPreferencesController.new,
);

class UiPreferencesController extends Notifier<UiPreferences> {
  static const _themeKey = 'ui.theme_mode';
  static const _effectsKey = 'ui.visual_effects';
  static const _hapticsKey = 'ui.haptics';
  static const _framingKey = 'ui.calorie_framing';

  @override
  UiPreferences build() {
    _load();
    return const UiPreferences();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = UiPreferences(
        themeMode: _byName(ThemeMode.values, prefs.getString(_themeKey)) ??
            ThemeMode.system,
        effects:
            _byName(VisualEffectsLevel.values, prefs.getString(_effectsKey)) ??
                VisualEffectsLevel.full,
        haptics: prefs.getBool(_hapticsKey) ?? true,
        calorieFraming:
            _byName(CalorieFraming.values, prefs.getString(_framingKey)) ??
                CalorieFraming.remaining,
      );
    } catch (_) {
      // Preferences are cosmetic; defaults are always safe.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode), _themeKey, mode.name);

  Future<void> setEffects(VisualEffectsLevel level) =>
      _persist(state.copyWith(effects: level), _effectsKey, level.name);

  Future<void> setHaptics(bool enabled) async {
    state = state.copyWith(haptics: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticsKey, enabled);
    } catch (_) {}
  }

  Future<void> setCalorieFraming(CalorieFraming framing) => _persist(
      state.copyWith(calorieFraming: framing), _framingKey, framing.name);

  Future<void> _persist(UiPreferences next, String key, String value) async {
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
