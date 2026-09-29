import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:snapgrub/core/design_system/effects/effects_scope.dart';
import 'package:snapgrub/core/design_system/effects/shader_library.dart';
import 'package:snapgrub/core/design_system/effects/tilt.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

extension _ShaderColor on ui.FragmentShader {
  int setColor(int index, Color color) {
    setFloat(index, color.r);
    setFloat(index + 1, color.g);
    setFloat(index + 2, color.b);
    return index + 3;
  }
}

/// Holds a single reusable [ui.FragmentShader] for a widget's lifetime.
///
/// Allocating a shader per paint is wasteful; this mixin creates one when the
/// program is ready and disposes it with the widget.
mixin _ShaderHost<T extends StatefulWidget> on State<T> {
  ui.FragmentShader? shader;
  SgShader get shaderKind;

  @override
  void initState() {
    super.initState();
    final ready = ShaderLibrary.maybe(shaderKind);
    if (ready != null) {
      shader = ready.fragmentShader();
    } else {
      ShaderLibrary.load(shaderKind).then((program) {
        if (!mounted || program == null) return;
        setState(() => shader = program.fragmentShader());
      });
    }
  }

  @override
  void dispose() {
    shader?.dispose();
    super.dispose();
  }
}

/// Elapsed-seconds clock that only ticks while effects animate.
mixin _EffectClock<T extends StatefulWidget> on State<T>, TickerProvider {
  final ValueNotifier<double> clock = ValueNotifier(0);
  Ticker? _ticker;

  bool get wantsClock => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = SgEffectsScope.of(context).animates && wantsClock;
    if (animate && _ticker == null) {
      _ticker = createTicker(
          (elapsed) => clock.value = elapsed.inMicroseconds / 1e6)
        ..start();
    } else if (!animate && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    clock.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Metal
// ---------------------------------------------------------------------------

enum MetalShape { planar, disc, ring }

/// A metallic surface (brushed titanium, gold, copper...) lit by device tilt.
///
/// [shape] picks the geometry: a rounded rectangle, a disc (medals, shutter)
/// or a ring/bezel. For [MetalShape.ring], [ringWidth] is the stroke width as
/// a fraction of the radius. [idleGlint] sweeps a highlight every
/// [glintEvery] while effects animate; [glint] drives it manually (0..1).
class MetalSurface extends StatefulWidget {
  const MetalSurface({
    required this.metal,
    this.shape = MetalShape.planar,
    this.ringWidth = .14,
    this.borderRadius = 20,
    this.idleGlint = false,
    this.glintEvery = const Duration(seconds: 6),
    this.glint,
    this.child,
    super.key,
  });

  final SgMetal metal;
  final MetalShape shape;
  final double ringWidth;
  final double borderRadius;
  final bool idleGlint;
  final Duration glintEvery;
  final ValueListenable<double>? glint;
  final Widget? child;

  @override
  State<MetalSurface> createState() => _MetalSurfaceState();
}

class _MetalSurfaceState extends State<MetalSurface>
    with SingleTickerProviderStateMixin, _ShaderHost, _EffectClock {
  @override
  SgShader get shaderKind => SgShader.metalSheen;

  /// Only the idle sheen needs a running clock; tilt and manual glints
  /// repaint on their own notifications, so static metal costs nothing.
  @override
  bool get wantsClock => widget.idleGlint;

  @override
  Widget build(BuildContext context) {
    final quality = SgEffectsScope.of(context);
    final painted = quality.shaders && shader != null
        ? TiltBuilder(
            builder: (context, tilt, _) => CustomPaint(
              painter: _MetalPainter(
                shader: shader!,
                metal: widget.metal,
                shape: widget.shape,
                ringWidth: widget.ringWidth,
                borderRadius: widget.borderRadius,
                tilt: tilt,
                clock: clock,
                glint: widget.glint,
                idleGlint: widget.idleGlint && quality.animates,
                glintEvery: widget.glintEvery,
              ),
            ),
          )
        : CustomPaint(
            painter: _MetalFallbackPainter(
              metal: widget.metal,
              shape: widget.shape,
              ringWidth: widget.ringWidth,
              borderRadius: widget.borderRadius,
            ),
          );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(child: IgnorePointer(child: painted)),
        if (widget.child != null) widget.child! else const SizedBox.expand(),
      ],
    );
  }
}

Path _metalPath(Size size, MetalShape shape, double ringWidth, double radius) {
  final rect = Offset.zero & size;
  switch (shape) {
    case MetalShape.planar:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    case MetalShape.disc:
      return Path()
        ..addOval(Rect.fromCircle(
            center: rect.center, radius: size.shortestSide / 2));
    case MetalShape.ring:
      final outer = size.shortestSide / 2;
      final inner = outer * (1 - ringWidth);
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: rect.center, radius: outer))
        ..addOval(Rect.fromCircle(center: rect.center, radius: inner));
  }
}

class _MetalPainter extends CustomPainter {
  _MetalPainter({
    required this.shader,
    required this.metal,
    required this.shape,
    required this.ringWidth,
    required this.borderRadius,
    required this.tilt,
    required this.clock,
    required this.glint,
    required this.idleGlint,
    required this.glintEvery,
  }) : super(repaint: Listenable.merge([clock, if (glint != null) glint]));

  final ui.FragmentShader shader;
  final SgMetal metal;
  final MetalShape shape;
  final double ringWidth;
  final double borderRadius;
  final Offset tilt;
  final ValueListenable<double> clock;
  final ValueListenable<double>? glint;
  final bool idleGlint;
  final Duration glintEvery;

  double get _glint {
    final manual = glint?.value;
    if (manual != null && manual >= 0 && manual <= 1) return manual;
    if (!idleGlint) return -1;
    final period = glintEvery.inMilliseconds / 1000;
    final phase = clock.value % period;
    const sweep = 1.2;
    return phase < sweep ? phase / sweep : -1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final ringCentre = 1 - ringWidth / 2;
    var i = 0;
    shader
      ..setFloat(i++, size.width)
      ..setFloat(i++, size.height)
      ..setFloat(i++, clock.value)
      ..setFloat(i++, tilt.dx)
      ..setFloat(i++, tilt.dy);
    i = shader.setColor(i, metal.base);
    i = shader.setColor(i, metal.highlight);
    i = shader.setColor(i, metal.shadow);
    shader
      ..setFloat(i++, shape.index.toDouble())
      ..setFloat(i++, ringCentre)
      ..setFloat(i++, ringWidth / 2)
      ..setFloat(i++, _glint)
      ..setFloat(i++, 1);
    canvas.drawPath(
      _metalPath(size, shape, ringWidth, borderRadius),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _MetalPainter old) =>
      old.tilt != tilt ||
      old.metal != metal ||
      old.shape != shape ||
      old.shader != shader ||
      old.idleGlint != idleGlint;
}

class _MetalFallbackPainter extends CustomPainter {
  const _MetalFallbackPainter({
    required this.metal,
    required this.shape,
    required this.ringWidth,
    required this.borderRadius,
  });

  final SgMetal metal;
  final MetalShape shape;
  final double ringWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawPath(
      _metalPath(size, shape, ringWidth, borderRadius),
      Paint()..shader = metal.fallbackGradient().createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _MetalFallbackPainter old) =>
      old.metal != metal || old.shape != shape;
}

// ---------------------------------------------------------------------------
// Holographic foil
// ---------------------------------------------------------------------------

/// Translucent thin-film foil laid over [child] (cards, medals, covers).
class HoloFoil extends StatefulWidget {
  const HoloFoil({
    required this.child,
    this.intensity = 1,
    this.borderRadius = 28,
    super.key,
  });

  final Widget child;
  final double intensity;
  final double borderRadius;

  @override
  State<HoloFoil> createState() => _HoloFoilState();
}

class _HoloFoilState extends State<HoloFoil>
    with SingleTickerProviderStateMixin, _ShaderHost, _EffectClock {
  @override
  SgShader get shaderKind => SgShader.holoFoil;

  @override
  Widget build(BuildContext context) {
    final quality = SgEffectsScope.of(context);
    final Widget overlay;
    if (quality.shaders && shader != null) {
      overlay = TiltBuilder(
        builder: (context, tilt, _) => CustomPaint(
          painter: _FoilPainter(
            shader: shader!,
            tilt: tilt,
            clock: clock,
            intensity: widget.intensity,
          ),
        ),
      );
    } else {
      overlay = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFD1E8).withValues(alpha: .22 * widget.intensity),
              const Color(0xFFC9F1FF).withValues(alpha: .18 * widget.intensity),
              const Color(0xFFFFF4C2).withValues(alpha: .22 * widget.intensity),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(child: IgnorePointer(child: overlay)),
        ],
      ),
    );
  }
}

class _FoilPainter extends CustomPainter {
  _FoilPainter({
    required this.shader,
    required this.tilt,
    required this.clock,
    required this.intensity,
  }) : super(repaint: clock);

  final ui.FragmentShader shader;
  final Offset tilt;
  final ValueListenable<double> clock;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, clock.value)
      ..setFloat(3, tilt.dx)
      ..setFloat(4, tilt.dy)
      ..setFloat(5, intensity);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _FoilPainter old) =>
      old.tilt != tilt || old.intensity != intensity || old.shader != shader;
}

// ---------------------------------------------------------------------------
// Mesh aurora backdrop
// ---------------------------------------------------------------------------

/// Slow time-of-day mesh gradient used behind hero areas.
class MeshAurora extends StatefulWidget {
  const MeshAurora({this.phase, this.colors, this.child, super.key});

  /// Defaults to the current phase of the day.
  final DayPhase? phase;

  /// Overrides the palette (four colours).
  final List<Color>? colors;
  final Widget? child;

  @override
  State<MeshAurora> createState() => _MeshAuroraState();
}

class _MeshAuroraState extends State<MeshAurora>
    with SingleTickerProviderStateMixin, _ShaderHost, _EffectClock {
  @override
  SgShader get shaderKind => SgShader.meshAurora;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final colors = widget.colors ??
        tokens.ambience(widget.phase ?? dayPhaseFor(DateTime.now()));
    final quality = SgEffectsScope.of(context);
    final Widget background = quality.shaders && shader != null
        ? CustomPaint(
            painter: _AuroraPainter(
              shader: shader!,
              colors: colors,
              clock: clock,
              grain: tokens.dark ? .035 : .028,
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          );
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(child: RepaintBoundary(child: background)),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.shader,
    required this.colors,
    required this.clock,
    required this.grain,
  }) : super(repaint: clock);

  final ui.FragmentShader shader;
  final List<Color> colors;
  final ValueListenable<double> clock;
  final double grain;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    var i = 0;
    shader
      ..setFloat(i++, size.width)
      ..setFloat(i++, size.height)
      // Offset the clock so a static (reduced) frame is still interesting.
      ..setFloat(i++, clock.value + 40);
    for (var c = 0; c < 4; c++) {
      i = shader.setColor(i, colors[c % colors.length]);
    }
    shader
      ..setFloat(i++, grain)
      ..setFloat(i++, 1);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      !listEquals(old.colors, colors) || old.shader != shader;
}

// ---------------------------------------------------------------------------
// Sampler effects (ripple, scan beam, dissolve)
// ---------------------------------------------------------------------------

/// Fires a ripple on an [SgRipple].
class RippleController extends ChangeNotifier {
  Offset? _origin;
  int _serial = 0;

  /// [origin] in the ripple widget's local coordinates; null = centre.
  void fire([Offset? origin]) {
    _origin = origin;
    _serial++;
    notifyListeners();
  }
}

/// Soft expanding light ripple over [child] when [controller] fires.
///
/// Painted as an overlay rather than by sampling the child: sampling via
/// `AnimatedSampler` flips its render object's repaint-boundary status when
/// toggled, which the framework does not allow. The overlay keeps the widget
/// tree identical whether or not a ripple is playing.
class SgRipple extends StatefulWidget {
  const SgRipple({
    required this.child,
    required this.controller,
    this.borderRadius = 24,
    this.duration = const Duration(milliseconds: 900),
    super.key,
  });

  final Widget child;
  final RippleController controller;
  final double borderRadius;
  final Duration duration;

  @override
  State<SgRipple> createState() => _SgRippleState();
}

class _SgRippleState extends State<SgRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: widget.duration);
  int _seen = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onFire);
  }

  @override
  void didUpdateWidget(covariant SgRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onFire);
      widget.controller.addListener(_onFire);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFire);
    _anim.dispose();
    super.dispose();
  }

  void _onFire() {
    if (widget.controller._serial == _seen) return;
    _seen = widget.controller._serial;
    if (!SgEffectsScope.of(context).animates) return;
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: CustomPaint(
                painter: _RipplePainter(
                  progress: _anim,
                  origin: () => widget.controller._origin,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.progress,
    required this.origin,
    required this.color,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Offset? Function() origin;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final o = origin() ?? size.center(Offset.zero);
    final maxR = size.longestSide * 1.1;
    final eased = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 2; i++) {
      final k = (eased - i * .18).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final r = maxR * k;
      final a = (1 - k) * .28;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: a),
            Colors.white.withValues(alpha: a * .9),
            color.withValues(alpha: 0),
          ],
          stops: const [.72, .86, .92, 1],
        ).createShader(Rect.fromCircle(center: o, radius: r));
      canvas.drawCircle(o, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => old.color != color;
}

/// Sweeping analysis beam with edge highlighting over [child] (a photo).
class ScanBeam extends StatefulWidget {
  const ScanBeam({
    required this.child,
    this.active = true,
    this.confidence = 0,
    super.key,
  });

  final Widget child;
  final bool active;

  /// 0..1; the dot grid fades out as confidence rises.
  final double confidence;

  @override
  State<ScanBeam> createState() => _ScanBeamState();
}

class _ScanBeamState extends State<ScanBeam>
    with SingleTickerProviderStateMixin, _ShaderHost, _EffectClock {
  @override
  SgShader get shaderKind => SgShader.scanBeam;

  @override
  bool get wantsClock => widget.active;

  @override
  Widget build(BuildContext context) {
    final quality = SgEffectsScope.of(context);
    final tint = Theme.of(context).colorScheme.primaryContainer;
    if (!widget.active || !quality.animates || shader == null) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (widget.active)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        tint.withValues(alpha: 0),
                        tint.withValues(alpha: .28),
                        tint.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return ValueListenableBuilder<double>(
      valueListenable: clock,
      child: widget.child,
      builder: (context, time, child) => AnimatedSampler(
        (image, size, canvas) {
          final s = shader!;
          var i = 0;
          s
            ..setFloat(i++, size.width)
            ..setFloat(i++, size.height)
            ..setFloat(i++, time)
            ..setFloat(i++, widget.confidence.clamp(0, 1).toDouble());
          s.setColor(i, tint);
          s.setImageSampler(0, image);
          canvas.drawRect(Offset.zero & size, Paint()..shader = s);
        },
        child: child!,
      ),
    );
  }
}

/// Dissolves [child] into drifting grain as [progress] goes 0 → 1.
/// Running the animation in reverse re-materialises it (used by Undo).
class DissolveTransition extends StatefulWidget {
  const DissolveTransition({
    required this.progress,
    required this.child,
    this.direction = const Offset(1, 0),
    super.key,
  });

  final Animation<double> progress;
  final Widget child;
  final Offset direction;

  @override
  State<DissolveTransition> createState() => _DissolveTransitionState();
}

class _DissolveTransitionState extends State<DissolveTransition>
    with _ShaderHost {
  @override
  SgShader get shaderKind => SgShader.dissolve;

  @override
  Widget build(BuildContext context) {
    final quality = SgEffectsScope.of(context);
    final edge = Theme.of(context).colorScheme.secondary;
    return AnimatedBuilder(
      animation: widget.progress,
      child: widget.child,
      builder: (context, child) {
        final p = widget.progress.value.clamp(0.0, 1.0);
        if (p <= 0) return child!;
        if (p >= 1) return const SizedBox.shrink();
        if (!quality.shaders || shader == null) {
          return Opacity(opacity: 1 - p, child: child);
        }
        return AnimatedSampler(
          (image, size, canvas) {
            final s = shader!;
            final dir = widget.direction.distance == 0
                ? const Offset(1, 0)
                : widget.direction / widget.direction.distance;
            var i = 0;
            s
              ..setFloat(i++, size.width)
              ..setFloat(i++, size.height)
              ..setFloat(i++, p)
              ..setFloat(i++, dir.dx)
              ..setFloat(i++, dir.dy);
            s.setColor(i, edge);
            s.setImageSampler(0, image);
            canvas.drawRect(Offset.zero & size, Paint()..shader = s);
          },
          child: child!,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Liquid glass
// ---------------------------------------------------------------------------

/// Frosted glass that, where supported, bends the backdrop like a lens at its
/// rounded edges (iOS 26 "Liquid Glass" style). Falls back to a blur.
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    required this.child,
    this.borderRadius = 28,
    this.tint,
    this.padding = EdgeInsets.zero,
    this.blur = 16,
    super.key,
  });

  final Widget child;
  final double borderRadius;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final double blur;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> with _ShaderHost {
  final _key = GlobalKey();
  Rect? _rect;

  @override
  SgShader get shaderKind => SgShader.liquidGlass;

  void _measure() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final origin = box.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(origin.dx * dpr, origin.dy * dpr,
        box.size.width * dpr, box.size.height * dpr);
    if (rect != _rect) setState(() => _rect = rect);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.sg;
    final highContrast = MediaQuery.highContrastOf(context);
    final quality = SgEffectsScope.of(context);
    final fill = (widget.tint ?? scheme.surfaceContainer)
        .withValues(alpha: highContrast ? 1 : (tokens.dark ? .72 : .66));

    ui.ImageFilter filter =
        ui.ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur);
    final lens = shader;
    final rect = _rect;
    if (quality.shaders &&
        lens != null &&
        rect != null &&
        ui.ImageFilter.isShaderFilterSupported) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      lens
        ..setFloat(2, rect.left)
        ..setFloat(3, rect.top)
        ..setFloat(4, rect.width)
        ..setFloat(5, rect.height)
        ..setFloat(6, widget.borderRadius * dpr)
        ..setFloat(7, 1);
      filter = ui.ImageFilter.compose(
        outer: ui.ImageFilter.shader(lens),
        inner: filter,
      );
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });

    final radius = BorderRadius.circular(widget.borderRadius);
    final content = DecoratedBox(
      key: _key,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: tokens.dark ? .14 : .08),
        ),
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );
    return DecoratedBox(
      decoration:
          BoxDecoration(borderRadius: radius, boxShadow: tokens.elevation2),
      child: ClipRRect(
        borderRadius: radius,
        child: highContrast
            ? content
            : BackdropFilter(filter: filter, child: content),
      ),
    );
  }
}

/// Small helper for staggering implicit animations in lists.
double staggerT(double t, int index, {int count = 8, double overlap = .6}) {
  final n = math.max(1, count);
  final slot = 1 / (n * (1 - overlap) + overlap);
  final start = index.clamp(0, n - 1) * slot * (1 - overlap);
  return ((t - start) / slot).clamp(0.0, 1.0);
}
