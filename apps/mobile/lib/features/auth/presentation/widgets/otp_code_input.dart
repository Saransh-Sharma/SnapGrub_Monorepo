import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';

/// Six-box one-time-code input.
///
/// A single (visually transparent) [TextField] sits on top of the boxes, so
/// the platform keyboard, `oneTimeCode` autofill, long-press paste and the
/// accessibility tree all see one ordinary text field. The boxes are purely
/// visual and mirror the controller's text.
///
/// * Digits pop into their box with a bouncy spring.
/// * Bump [errorSignal] to shake the row (with the `warn` haptic).
/// * Bump [successSignal] to sweep a shimmer across the boxes.
/// * [onCompleted] fires once when the sixth digit arrives.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    required this.controller,
    required this.onCompleted,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
    this.errorSignal = 0,
    this.successSignal = 0,
    this.autofocus = true,
    this.semanticLabel = 'Email code',
    this.fieldKey,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final int length;
  final bool enabled;
  final bool hasError;
  final int errorSignal;
  final int successSignal;
  final bool autofocus;
  final String semanticLabel;
  final Key? fieldKey;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput>
    with TickerProviderStateMixin {
  final _focusNode = FocusNode(debugLabel: 'otp');
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    _lastText = widget.controller.text;
    widget.controller.addListener(_onText);
    _focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant OtpCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
    final motion = SgMotion.of(context);
    if (widget.errorSignal != oldWidget.errorSignal) {
      SgHaptics.warn();
      if (!motion.reduced) _shake.forward(from: 0);
    }
    if (widget.successSignal != oldWidget.successSignal && !motion.reduced) {
      _shimmer.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focusNode.dispose();
    _shake.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  String _lastText = '';

  void _onText() {
    final text = widget.controller.text;
    if (text == _lastText) return;
    final wasComplete = _lastText.length >= widget.length;
    _lastText = text;
    setState(() {});
    if (text.isNotEmpty && text.length < widget.length) SgHaptics.tick();
    if (text.length == widget.length && !wasComplete) {
      widget.onCompleted(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final focused = _focusNode.hasFocus;
    final activeIndex = math.min(text.length, widget.length - 1);
    final theme = Theme.of(context);

    final boxes = AnimatedBuilder(
      animation: Listenable.merge([_shake, _shimmer]),
      builder: (context, _) {
        final t = _shake.value;
        final dx =
            _shake.isAnimating ? math.sin(t * math.pi * 6) * 12 * (1 - t) : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) SizedBox(width: i == widget.length ~/ 2 ? 14 : 8),
                Expanded(
                  child: _OtpBox(
                    digit: i < text.length ? text[i] : null,
                    active: focused && widget.enabled && i == activeIndex,
                    error: widget.hasError,
                    shimmer: _shimmer.isAnimating
                        ? _shimmerAt(i, _shimmer.value)
                        : 0,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    // The real field: transparent text/cursor/selection laid over the boxes.
    final field = Theme(
      data: theme.copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Colors.transparent,
          cursorColor: Colors.transparent,
        ),
      ),
      child: Semantics(
        label: '${widget.semanticLabel}, ${widget.length} digits',
        child: TextField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.length),
          ],
          showCursor: false,
          enableSuggestions: false,
          autocorrect: false,
          style: const TextStyle(color: Colors.transparent, fontSize: 1),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            filled: false,
            isCollapsed: true,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(child: IgnorePointer(child: boxes)),
          Positioned.fill(child: field),
        ],
      ),
    );
  }

  /// Brightness of the shimmer band over box [i] at time [t] (0..1).
  double _shimmerAt(int i, double t) {
    final centre = -0.2 + t * 1.4;
    final pos = (i + .5) / widget.length;
    final d = (pos - centre).abs();
    return (1 - d / .22).clamp(0.0, 1.0);
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.active,
    required this.error,
    required this.shimmer,
  });

  final String? digit;
  final bool active;
  final bool error;
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.sg;
    final motion = SgMotion.of(context);
    final filled = digit != null;
    final borderColor = error
        ? scheme.error
        : active
            ? scheme.primary
            : filled
                ? tokens.outlineStrong
                : scheme.outlineVariant;
    const metal = SgMetal.titanium;

    return AnimatedContainer(
      duration: motion.press,
      curve: motion.standard,
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        color: Color.lerp(
          filled ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
          metal.highlight,
          shimmer * .85,
        ),
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
        border: Border.all(color: borderColor, width: active ? 2 : 1.2),
        boxShadow: shimmer > 0
            ? [
                BoxShadow(
                  color: metal.base.withValues(alpha: .35 * shimmer),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: filled
          ? TweenAnimationBuilder<double>(
              key: ValueKey(digit),
              tween: Tween(begin: 0, end: 1),
              duration: motion.of(const Duration(milliseconds: 420)),
              curve: const SpringCurve(SgSprings.bouncy),
              builder: (context, v, child) => Transform.scale(
                scale: .55 + .45 * v,
                child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
              ),
              child: Text(
                digit!,
                style: tokens.metric.copyWith(color: scheme.onSurface),
              ),
            )
          : active
              ? _Caret(color: scheme.primary)
              : const SizedBox.shrink(),
    );
  }
}

class _Caret extends StatelessWidget {
  const _Caret({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      );
}

/// A [Curve] that follows a critically-or-under-damped spring from 0 to 1.
///
/// The spring is simulated over a fixed window and normalised so the curve
/// ends exactly at 1 (under-damped springs overshoot on the way).
class SpringCurve extends Curve {
  const SpringCurve(this.spring, {this.window = .6});

  final SpringDescription spring;

  /// Seconds of simulated spring time mapped onto t = 0..1.
  final double window;

  @override
  double transformInternal(double t) {
    final sim = SpringSimulation(spring, 0, 1, 0);
    return sim.x(t * window) + (1 - sim.x(window)) * t;
  }
}
