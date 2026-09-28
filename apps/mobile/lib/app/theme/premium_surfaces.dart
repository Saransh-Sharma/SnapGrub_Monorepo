import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/app/theme/premium_motion.dart';
import 'package:snapgrub/core/design_system/haptics.dart';

class PremiumBackdrop extends StatelessWidget {
  const PremiumBackdrop({this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: dark
            ? SnapGrubDesignTokens.darkBackground
            : SnapGrubDesignTokens.lightBackground,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: _AmbientCanvas()),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _AmbientCanvas extends StatelessWidget {
  const _AmbientCanvas();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(painter: _AmbientPainter(dark: dark));
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    paint.color = (dark ? SnapGrubDesignTokens.nightMistGlow : SnapGrubDesignTokens.mist)
        .withValues(alpha: dark ? .10 : .42);
    canvas.drawCircle(Offset(size.width * .92, size.height * .12),
        size.shortestSide * .34, paint);
    paint.color = (dark ? SnapGrubDesignTokens.nightBlushGlow : SnapGrubDesignTokens.blush)
        .withValues(alpha: dark ? .07 : .25);
    canvas.drawCircle(Offset(size.width * .06, size.height * .72),
        size.shortestSide * .28, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class SnapGrubMark extends StatelessWidget {
  const SnapGrubMark({this.size = 56, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'SnapGrub',
        image: true,
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _SnapGrubMarkPainter(
              color: Theme.of(context).colorScheme.primary,
              accent: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      );
}

class _SnapGrubMarkPainter extends CustomPainter {
  const _SnapGrubMarkPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .34;
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(center.translate(radius * .36, -radius * .28),
        radius * .34, Paint()..color = accent);
    canvas.drawCircle(center.translate(-radius * .30, radius * .16),
        radius * .24, Paint()..color = Colors.white.withValues(alpha: .88));
  }

  @override
  bool shouldRepaint(covariant _SnapGrubMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}

class PremiumGlassSurface extends StatelessWidget {
  const PremiumGlassSurface({
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.radius = SnapGrubDesignTokens.radiusMd,
    this.tint,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final fill = tint ?? scheme.surfaceContainer;
    final surface = AnimatedContainer(
      duration: disableAnimations ? Duration.zero : PremiumMotion.settle,
      curve: PremiumMotion.standard,
      padding: padding,
      decoration: BoxDecoration(
        color: fill.withValues(alpha: reduceTransparency ? 1 : 0.86),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.28),
              blurRadius: 1,
              offset: const Offset(0, -1),
            ),
        ],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (!disableAnimations && !reduceTransparency)
            const Positioned.fill(
              child: IgnorePointer(
                child: _RuntimeEffectOverlay(
                  asset: 'shaders/refractive_glass.frag',
                  duration: Duration(milliseconds: 1800),
                  repeat: false,
                ),
              ),
            ),
          child,
        ],
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: reduceTransparency
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: surface,
            ),
    );
  }
}

class PremiumPressable extends StatefulWidget {
  const PremiumPressable({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.haptic = true,
    this.pressedScale = 0.968,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// When set, replaces the child's semantics so the label is read once.
  final String? semanticLabel;
  final bool haptic;
  final double pressedScale;

  @override
  State<PremiumPressable> createState() => _PremiumPressableState();
}

class _PremiumPressableState extends State<PremiumPressable> {
  bool _pressed = false;
  bool _focused = false;

  void _activate() {
    if (widget.onTap == null) return;
    if (widget.haptic) SgHaptics.tap();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onTap == null ? null : _activate,
      onLongPress: widget.onLongPress,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap == null ? null : _activate,
          onLongPress: widget.onLongPress == null
              ? null
              : () {
                  if (widget.haptic) SgHaptics.impact();
                  widget.onLongPress!();
                },
          onTapDown: !enabled ? null : (_) => setState(() => _pressed = true),
          onTapCancel: !enabled ? null : () => setState(() => _pressed = false),
          onTapUp: !enabled ? null : (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: reduceMotion || !_pressed ? 1 : widget.pressedScale,
            duration: reduceMotion
                ? Duration.zero
                : _pressed
                    ? PremiumMotion.press
                    : PremiumMotion.settle,
            curve: _pressed ? PremiumMotion.standard : Curves.elasticOut,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
                border: _focused
                    ? Border.all(color: scheme.primary, width: 2.5)
                    : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class MealImageReveal extends StatelessWidget {
  const MealImageReveal({required this.child, this.visible = true, super.key});

  final Widget child;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: reduceMotion ? Duration.zero : PremiumMotion.reveal,
      curve: PremiumMotion.standard,
      child: AnimatedScale(
        scale: visible || reduceMotion ? 1 : 1.035,
        duration: reduceMotion ? Duration.zero : PremiumMotion.reveal,
        curve: PremiumMotion.standard,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            child,
            if (!reduceMotion)
              const Positioned.fill(
                child: IgnorePointer(
                  child: _RuntimeEffectOverlay(
                    asset: 'shaders/meal_reveal.frag',
                    duration: PremiumMotion.reveal,
                    repeat: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuntimeEffectOverlay extends StatefulWidget {
  const _RuntimeEffectOverlay({
    required this.asset,
    required this.duration,
    this.repeat = true,
  });

  final String asset;
  final Duration duration;
  final bool repeat;

  @override
  State<_RuntimeEffectOverlay> createState() => _RuntimeEffectOverlayState();
}

class _RuntimeEffectOverlayState extends State<_RuntimeEffectOverlay>
    with SingleTickerProviderStateMixin {
  FragmentShader? _shader;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await FragmentProgram.fromAsset(widget.asset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
      if (widget.repeat) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    } catch (_) {
      // The base surface remains complete when a device cannot load effects.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null) return const SizedBox.expand();
    return CustomPaint(
      painter: _RuntimeEffectPainter(shader: shader, progress: _controller),
    );
  }
}

class _RuntimeEffectPainter extends CustomPainter {
  _RuntimeEffectPainter({required this.shader, required this.progress})
      : super(repaint: progress);

  final FragmentShader shader;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress.value);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _RuntimeEffectPainter oldDelegate) =>
      oldDelegate.shader != shader;
}
