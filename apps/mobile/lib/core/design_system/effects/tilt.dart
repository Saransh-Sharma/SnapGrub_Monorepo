import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:snapgrub/core/design_system/effects/effects_scope.dart';

/// Shared, ref-counted device tilt in the range -1..1 on both axes.
///
/// Tilt is measured relative to a slowly adapting rest pose, so whatever
/// angle the user naturally holds the phone at reads as "centre". When no
/// accelerometer is available the light drifts autonomously instead.
class TiltController extends ValueNotifier<Offset> {
  TiltController._() : super(Offset.zero);

  static final TiltController instance = TiltController._();

  StreamSubscription<AccelerometerEvent>? _sub;
  Ticker? _drift;
  int _listeners = 0;
  Offset? _baseline;
  bool _sensorFailed = false;

  void retain() {
    _listeners++;
    if (_listeners == 1) _start();
  }

  void release() {
    _listeners = math.max(0, _listeners - 1);
    if (_listeners == 0) _stop();
  }

  void _start() {
    if (_sensorFailed) {
      _startDrift();
      return;
    }
    try {
      _sub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onSample, onError: (_) => _fallBack(), cancelOnError: true);
    } catch (_) {
      _fallBack();
    }
  }

  void _fallBack() {
    _sensorFailed = true;
    _sub?.cancel();
    _sub = null;
    if (_listeners > 0) _startDrift();
  }

  void _startDrift() {
    _drift ??= Ticker((elapsed) {
      final t = elapsed.inMilliseconds / 1000;
      value = Offset(math.sin(t * .45) * .55, math.cos(t * .31) * .35);
    })
      ..start();
  }

  void _onSample(AccelerometerEvent e) {
    final raw = Offset(e.x, e.y);
    final baseline = _baseline ?? raw;
    // Rest pose follows slowly so sustained angles recentre over ~3 s.
    _baseline = Offset.lerp(baseline, raw, .02);
    final delta = (raw - _baseline!) / 3.2;
    final target = Offset(
      delta.dx.clamp(-1.0, 1.0),
      (-delta.dy).clamp(-1.0, 1.0),
    );
    value = Offset.lerp(value, target, .18)!;
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _drift?.dispose();
    _drift = null;
    _baseline = null;
    value = Offset.zero;
  }
}

/// Rebuilds with the current tilt while effects are at full quality; otherwise
/// provides a fixed, pleasant light angle.
class TiltBuilder extends StatefulWidget {
  const TiltBuilder({required this.builder, this.child, super.key});

  final Widget Function(BuildContext context, Offset tilt, Widget? child)
      builder;
  final Widget? child;

  static const restingLight = Offset(-.15, -.1);

  @override
  State<TiltBuilder> createState() => _TiltBuilderState();
}

class _TiltBuilderState extends State<TiltBuilder> {
  bool _retained = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final live = SgEffectsScope.of(context).animates &&
        TickerMode.valuesOf(context).enabled;
    if (live && !_retained) {
      TiltController.instance.retain();
      _retained = true;
    } else if (!live && _retained) {
      TiltController.instance.release();
      _retained = false;
    }
  }

  @override
  void dispose() {
    if (_retained) TiltController.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_retained) {
      return widget.builder(context, TiltBuilder.restingLight, widget.child);
    }
    return ValueListenableBuilder<Offset>(
      valueListenable: TiltController.instance,
      child: widget.child,
      builder: (context, tilt, child) =>
          widget.builder(context, tilt + TiltBuilder.restingLight, child),
    );
  }
}
