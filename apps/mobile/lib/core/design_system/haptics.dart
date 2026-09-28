import 'package:flutter/services.dart';

/// Named haptic patterns. Always use these instead of calling
/// [HapticFeedback] directly so the user's Haptics preference is honoured and
/// the app speaks one consistent tactile language.
class SgHaptics {
  const SgHaptics._();

  /// Mirrors the user's preference; set by the app root.
  static bool enabled = true;

  /// Buttons and chips.
  static Future<void> tap() => _run(HapticFeedback.lightImpact);

  /// Pickers, slider detents, ruler marks, week strip.
  static Future<void> tick() => _run(HapticFeedback.selectionClick);

  /// Camera shutter: a firm press followed by a soft release.
  static Future<void> shutter() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await HapticFeedback.lightImpact();
  }

  /// Barcode found.
  static Future<void> detect() => _run(HapticFeedback.heavyImpact);

  /// Meal confirmed / logged.
  static Future<void> logged() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
  }

  /// Streak or goal milestone: three accelerating taps then a thump.
  static Future<void> milestone() async {
    if (!enabled) return;
    for (final gap in const [90, 70, 50]) {
      await HapticFeedback.lightImpact();
      await Future<void>.delayed(Duration(milliseconds: gap));
    }
    await HapticFeedback.heavyImpact();
  }

  /// Crossing a destructive threshold, or an error shake.
  static Future<void> warn() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Heavier, deliberate confirmation (e.g. pinch gestures, sheet snaps).
  static Future<void> impact() => _run(HapticFeedback.mediumImpact);

  static Future<void> _run(Future<void> Function() effect) async {
    if (!enabled) return;
    await effect();
  }
}
