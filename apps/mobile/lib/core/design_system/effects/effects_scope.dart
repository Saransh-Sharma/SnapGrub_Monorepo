import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:snapgrub/core/design_system/effects/device_capabilities.dart';
import 'package:snapgrub/core/preferences/ui_preferences.dart';

/// Effective rendering tier for GPU effects.
///
/// * [full]: live shaders, continuous idle motion, tilt.
/// * [reduced]: shaders render static frames only; no continuous animation.
/// * [off]: pure gradient / flat fallbacks.
enum EffectsQuality { full, reduced, off }

extension EffectsQualityX on EffectsQuality {
  bool get animates => this == EffectsQuality.full;
  bool get shaders => this != EffectsQuality.off;
}

/// Decides the effective [EffectsQuality] from the user preference, OS
/// accessibility settings, power state and a frame-time watchdog.
class SgEffectsScope extends StatefulWidget {
  const SgEffectsScope({
    required this.preference,
    required this.child,
    this.enableWatchdog = true,
    super.key,
  });

  final VisualEffectsLevel preference;
  final Widget child;
  final bool enableWatchdog;

  static EffectsQuality of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_EffectsInherited>();
    // Without a scope (isolated widget tests, previews) never run endless
    // tickers: render static frames only.
    final base = scope?.quality ?? EffectsQuality.reduced;
    final media = MediaQuery.maybeOf(context);
    if (media == null) return base;
    if (media.disableAnimations && base == EffectsQuality.full) {
      return EffectsQuality.reduced;
    }
    return base;
  }

  /// Pure resolution logic, exposed for tests.
  static EffectsQuality resolve({
    required VisualEffectsLevel preference,
    required bool lowPower,
    required int watchdogSteps,
  }) {
    var quality = switch (preference) {
      VisualEffectsLevel.full => EffectsQuality.full,
      VisualEffectsLevel.reduced => EffectsQuality.reduced,
      VisualEffectsLevel.off => EffectsQuality.off,
    };
    if (lowPower && quality == EffectsQuality.full) {
      quality = EffectsQuality.reduced;
    }
    for (var i = 0; i < watchdogSteps; i++) {
      quality = switch (quality) {
        EffectsQuality.full => EffectsQuality.reduced,
        _ => quality,
      };
    }
    return quality;
  }

  @override
  State<SgEffectsScope> createState() => _SgEffectsScopeState();
}

class _SgEffectsScopeState extends State<SgEffectsScope> {
  final _power = DeviceCapabilities.instance.lowPowerMode;
  int _watchdogSteps = 0;
  final List<FrameTiming> _window = [];
  DateTime _windowStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _power.addListener(_onChanged);
    if (widget.enableWatchdog) {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    }
  }

  @override
  void dispose() {
    _power.removeListener(_onChanged);
    if (widget.enableWatchdog) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  /// Steps quality down one tier if more than 10% of frames over 3 s miss a
  /// 120 Hz budget by a wide margin (> 16 ms raster or build).
  void _onTimings(List<FrameTiming> timings) {
    if (_watchdogSteps > 0) return;
    _window.addAll(timings);
    final now = DateTime.now();
    if (now.difference(_windowStart) < const Duration(seconds: 3)) return;
    final janky = _window
        .where((t) =>
            t.rasterDuration.inMilliseconds > 16 ||
            t.buildDuration.inMilliseconds > 16)
        .length;
    final ratio = _window.isEmpty ? 0 : janky / _window.length;
    _window.clear();
    _windowStart = now;
    if (ratio > .10 && mounted) {
      setState(() => _watchdogSteps = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quality = SgEffectsScope.resolve(
      preference: widget.preference,
      lowPower: _power.value,
      watchdogSteps: _watchdogSteps,
    );
    return _EffectsInherited(quality: quality, child: widget.child);
  }
}

class _EffectsInherited extends InheritedWidget {
  const _EffectsInherited({required this.quality, required super.child});

  final EffectsQuality quality;

  @override
  bool updateShouldNotify(_EffectsInherited oldWidget) =>
      oldWidget.quality != quality;
}
