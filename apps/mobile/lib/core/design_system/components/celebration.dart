import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapgrub/core/design_system/effects/effects_scope.dart';
import 'package:snapgrub/core/design_system/haptics.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

/// Metal-flake confetti burst, rendered as an overlay above everything.
///
/// Flakes are tiny quads whose brightness follows cos(spin) to fake 3D foil
/// flips. Celebrations are rate-limited: once per session per [key], and
/// [oncePerDay] / [onceEver] add persistent limits. Returns whether it played.
class Celebration {
  Celebration._();

  static final Set<String> _session = {};

  static Future<bool> play(
    BuildContext context, {
    required String key,
    List<SgMetal> metals = const [
      SgMetal.gold,
      SgMetal.titanium,
      SgMetal.copper
    ],
    Offset? origin,
    bool oncePerDay = false,
    bool onceEver = false,
    bool haptic = true,
    int count = 70,
  }) async {
    if (_session.contains(key)) return false;
    final prefsKey = onceEver
        ? 'celebrate.$key'
        : oncePerDay
            ? 'celebrate.$key.${DateUtils.dateOnly(DateTime.now()).toIso8601String()}'
            : null;
    if (prefsKey != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool(prefsKey) ?? false) return false;
        await prefs.setBool(prefsKey, true);
      } catch (_) {}
    }
    _session.add(key);
    if (!context.mounted) return false;
    if (haptic) SgHaptics.milestone();
    final quality = SgEffectsScope.of(context);
    if (!quality.animates) return true;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return true;
    final size = MediaQuery.sizeOf(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _FlakeBurst(
          origin: origin ?? Offset(size.width / 2, size.height * .38),
          metals: metals,
          count: count,
          onDone: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
    return true;
  }

  /// Test hook.
  @visibleForTesting
  static void resetSession() => _session.clear();
}

class _Flake {
  _Flake(math.Random r, Offset origin, this.metal)
      : position = origin,
        velocity = Offset.fromDirection(
          -math.pi / 2 + (r.nextDouble() - .5) * math.pi * 1.1,
          520 + r.nextDouble() * 520,
        ),
        spin = r.nextDouble() * math.pi * 2,
        spinSpeed = (r.nextDouble() - .5) * 18,
        rotation = r.nextDouble() * math.pi,
        size = Size(5 + r.nextDouble() * 6, 8 + r.nextDouble() * 9);

  Offset position;
  Offset velocity;
  double spin;
  final double spinSpeed;
  final double rotation;
  final Size size;
  final SgMetal metal;
}

class _FlakeBurst extends StatefulWidget {
  const _FlakeBurst({
    required this.origin,
    required this.metals,
    required this.count,
    required this.onDone,
  });

  final Offset origin;
  final List<SgMetal> metals;
  final int count;
  final VoidCallback onDone;

  @override
  State<_FlakeBurst> createState() => _FlakeBurstState();
}

class _FlakeBurstState extends State<_FlakeBurst>
    with SingleTickerProviderStateMixin {
  late final List<_Flake> _flakes;
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);
  Duration _last = Duration.zero;
  static const _life = 1.25;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _flakes = [
      for (var i = 0; i < widget.count; i++)
        _Flake(r, widget.origin, widget.metals[i % widget.metals.length]),
    ];
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    for (final f in _flakes) {
      f.velocity = Offset(f.velocity.dx * (1 - 1.6 * dt),
          f.velocity.dy * (1 - 1.6 * dt) + 1400 * dt);
      f.position += f.velocity * dt;
      f.spin += f.spinSpeed * dt;
    }
    _t.value = elapsed.inMicroseconds / 1e6;
    if (_t.value > _life) {
      _ticker.stop();
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.infinite,
        painter: _FlakePainter(_flakes, _t, _life),
      );
}

class _FlakePainter extends CustomPainter {
  _FlakePainter(this.flakes, this.t, this.life) : super(repaint: t);

  final List<_Flake> flakes;
  final ValueNotifier<double> t;
  final double life;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1 - (t.value / life)).clamp(0.0, 1.0);
    final paint = Paint();
    for (final f in flakes) {
      final flip = math.cos(f.spin);
      final light = (flip.abs() * .8 + .2);
      final color = Color.lerp(f.metal.shadow, f.metal.highlight, light)!;
      paint.color = color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(f.position.dx, f.position.dy);
      canvas.rotate(f.rotation + f.spin * .3);
      canvas.scale(1, flip.abs().clamp(.12, 1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: f.size.width, height: f.size.height),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FlakePainter oldDelegate) => false;
}
