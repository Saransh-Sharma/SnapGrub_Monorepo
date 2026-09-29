import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:snapgrub/core/design_system/effects/effects_scope.dart';
import 'package:snapgrub/core/design_system/effects/sg_effects.dart';
import 'package:snapgrub/core/design_system/effects/shader_library.dart';
import 'package:snapgrub/core/design_system/motion.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

/// Animated progress ring.
///
/// * Progress springs to new values and gives the liquid fill a "slosh".
/// * Values above 1 draw an overflow lap in a neutral colour — never red.
/// * [liquid] uses the liquid-ring shader when effects allow it.
/// * [bezel] wraps the ring in a thin tilt-lit metal rim.
class SgRing extends StatefulWidget {
  const SgRing({
    required this.progress,
    required this.color,
    this.size = 56,
    this.thickness = 6,
    this.trackColor,
    this.liquid = false,
    this.bezel,
    this.bezelWidth = 3,
    this.child,
    this.semanticsLabel,
    this.semanticsValue,
    this.animateFromZero = true,
    super.key,
  });

  final double progress;
  final Color color;
  final double size;
  final double thickness;
  final Color? trackColor;
  final bool liquid;
  final SgMetal? bezel;
  final double bezelWidth;
  final Widget? child;
  final String? semanticsLabel;
  final String? semanticsValue;
  final bool animateFromZero;

  @override
  State<SgRing> createState() => _SgRingState();
}

class _SgRingState extends State<SgRing> with TickerProviderStateMixin {
  late final AnimationController _value = AnimationController.unbounded(
    vsync: this,
    value: widget.animateFromZero ? 0 : widget.progress,
  );
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );
  ui.FragmentShader? _shader;
  Timer? _settle;

  /// Liquid shimmer runs only briefly after a change, then freezes, so a
  /// screen of rings never animates continuously.
  void _stir([Duration length = const Duration(milliseconds: 3200)]) {
    if (!widget.liquid || !SgEffectsScope.of(context).animates) return;
    if (!_clock.isAnimating) _clock.repeat();
    _settle?.cancel();
    _settle = Timer(length, () {
      if (mounted) _clock.stop();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.liquid) _ensureShader();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.animateFromZero) _animateTo(widget.progress);
    });
  }

  void _ensureShader() {
    if (_shader != null) return;
    final ready = ShaderLibrary.maybe(SgShader.liquidRing);
    if (ready != null) {
      _shader = ready.fragmentShader();
      return;
    }
    ShaderLibrary.load(SgShader.liquidRing).then((program) {
      if (!mounted || program == null) return;
      setState(() => _shader = program.fragmentShader());
    });
  }

  bool _stirredOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = SgEffectsScope.of(context).animates && widget.liquid;
    if (!animate && _clock.isAnimating) {
      _clock.stop();
    } else if (animate && !_stirredOnce) {
      _stirredOnce = true;
      _stir();
    }
  }

  @override
  void didUpdateWidget(covariant SgRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.liquid) _ensureShader();
    if (oldWidget.progress != widget.progress) _animateTo(widget.progress);
  }

  void _animateTo(double target) {
    if (SgMotion.of(context).reduced) {
      _value.value = target;
      return;
    }
    _value.animateWith(SpringSimulation(
      SgSprings.gentle,
      _value.value,
      target,
      _value.velocity,
    ));
    if (widget.liquid) {
      _wobble.forward(from: 0);
      _stir();
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    _value.dispose();
    _wobble.dispose();
    _clock.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final quality = SgEffectsScope.of(context);
    final track = widget.trackColor ?? widget.color.withValues(alpha: .14);
    final useLiquid = widget.liquid && quality.shaders && _shader != null;
    final ringInset = widget.bezel == null ? 0.0 : widget.bezelWidth + 1.5;

    Widget ring = CustomPaint(
      painter: useLiquid
          ? _LiquidRingPainter(
              shader: _shader!,
              value: _value,
              wobble: _wobble,
              clock: _clock,
              color: widget.color,
              track: track,
              over: tokens.overTarget,
              thickness: widget.thickness,
            )
          : _ArcRingPainter(
              value: _value,
              color: widget.color,
              track: track,
              over: tokens.overTarget,
              thickness: widget.thickness,
            ),
      child: widget.child == null
          ? null
          : Center(
              child: Padding(
                padding: EdgeInsets.all(widget.thickness + 2),
                child: widget.child,
              ),
            ),
    );
    if (widget.bezel != null) {
      ring = Stack(
        fit: StackFit.expand,
        children: [
          MetalSurface(
            metal: widget.bezel!,
            shape: MetalShape.ring,
            ringWidth: (widget.bezelWidth * 2) / widget.size,
          ),
          Padding(padding: EdgeInsets.all(ringInset), child: ring),
        ],
      );
    }
    final percent = (widget.progress * 100).round();
    return Semantics(
      label: widget.semanticsLabel,
      value: widget.semanticsValue ?? '$percent percent',
      child: SizedBox.square(dimension: widget.size, child: ring),
    );
  }
}

class _ArcRingPainter extends CustomPainter {
  _ArcRingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.over,
    required this.thickness,
  }) : super(repaint: value);

  final ValueListenable<double> value;
  final Color color;
  final Color track;
  final Color over;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(thickness / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    final v = value.value.clamp(0.0, 2.0);
    final lap1 = math.min(v, 1.0);
    if (lap1 > 0.001) {
      canvas.drawArc(
          rect, -math.pi / 2, math.pi * 2 * lap1, false, paint..color = color);
    }
    final lap2 = math.max(v - 1, 0.0);
    if (lap2 > 0.001) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * lap2,
        false,
        paint
          ..color = over
          ..strokeWidth = thickness * .55,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter old) =>
      old.color != color || old.track != track || old.thickness != thickness;
}

class _LiquidRingPainter extends CustomPainter {
  _LiquidRingPainter({
    required this.shader,
    required this.value,
    required this.wobble,
    required this.clock,
    required this.color,
    required this.track,
    required this.over,
    required this.thickness,
  }) : super(repaint: Listenable.merge([value, wobble, clock]));

  final ui.FragmentShader shader;
  final Animation<double> value;
  final Animation<double> wobble;
  final Animation<double> clock;
  final Color color;
  final Color track;
  final Color over;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final radius = size.shortestSide / 2;
    final w = wobble.value;
    final impulse = w == 0 ? 0.0 : math.exp(-w * 4) * (1 - w);
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, clock.value * 60)
      ..setFloat(3, value.value.clamp(0.0, 2.0))
      ..setFloat(4, thickness / radius)
      ..setFloat(5, impulse)
      ..setFloat(6, color.r)
      ..setFloat(7, color.g)
      ..setFloat(8, color.b)
      ..setFloat(9, track.r)
      ..setFloat(10, track.g)
      ..setFloat(11, track.b)
      ..setFloat(12, track.a)
      ..setFloat(13, over.r)
      ..setFloat(14, over.g)
      ..setFloat(15, over.b);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _LiquidRingPainter old) =>
      old.color != color || old.track != track || old.shader != shader;
}
