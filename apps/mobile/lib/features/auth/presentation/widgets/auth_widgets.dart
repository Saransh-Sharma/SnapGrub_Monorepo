import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';

/// Password field with a show / hide toggle.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    required this.controller,
    required this.label,
    this.autofillHints,
    this.helperText,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final Iterable<String>? autofillHints;
  final String? helperText;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscured,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscured ? 'Show password' : 'Hide password',
          constraints: const BoxConstraints(
            minWidth: SnapGrubDesignTokens.minTapTarget,
            minHeight: SnapGrubDesignTokens.minTapTarget,
          ),
          onPressed: () {
            SgHaptics.tick();
            setState(() => _obscured = !_obscured);
          },
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

/// The SnapGrub mark with a one-shot titanium glint sweeping across it.
///
/// The glint plays on entry and whenever [replayKey] changes. It is skipped
/// under Reduce Motion and when visual effects are off.
class AuthMark extends StatefulWidget {
  const AuthMark({required this.size, this.replayKey, super.key});

  final double size;
  final Object? replayKey;

  @override
  State<AuthMark> createState() => _AuthMarkState();
}

class _AuthMarkState extends State<AuthMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_played) {
      _played = true;
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant AuthMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayKey != widget.replayKey) _play();
  }

  void _play() {
    final allowed = !SgMotion.of(context).reduced &&
        SgEffectsScope.of(context) != EffectsQuality.off;
    if (allowed) _glint.forward(from: 0);
  }

  @override
  void dispose() {
    _glint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const metal = SgMetal.titanium;
    final mark = SnapGrubMark(size: widget.size);
    return AnimatedBuilder(
      animation: _glint,
      child: mark,
      builder: (context, child) {
        if (!_glint.isAnimating) return child!;
        final t = Curves.easeInOutCubic.transform(_glint.value);
        final centre = -0.35 + t * 1.7;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.transparent,
              metal.highlight.withValues(alpha: .0),
              metal.highlight.withValues(alpha: .78),
              metal.highlight.withValues(alpha: .0),
              Colors.transparent,
            ],
            stops: [
              0,
              (centre - .16).clamp(0.0, 1.0),
              centre.clamp(0.0, 1.0),
              (centre + .16).clamp(0.0, 1.0),
              1,
            ],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// A disclosure row that folds away the less common actions.
class AuthMoreOptions extends StatefulWidget {
  const AuthMoreOptions({required this.children, super.key});

  final List<Widget> children;

  @override
  State<AuthMoreOptions> createState() => _AuthMoreOptionsState();
}

class _AuthMoreOptionsState extends State<AuthMoreOptions> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motion = SgMotion.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        E2eId(
          id: 'auth.more_options',
          child: Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
              onTap: () {
                SgHaptics.tap();
                setState(() => _open = !_open);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: SnapGrubDesignTokens.minTapTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'More options',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _open ? .5 : 0,
                        duration: motion.settle,
                        curve: motion.standard,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: motion.settle,
          curve: motion.standard,
          alignment: Alignment.topCenter,
          child: _open
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// "Resend code" with a 30 s cooldown shown as a small draining ring.
///
/// The cooldown starts when the widget is created (a code was just sent) and
/// restarts whenever [restartToken] changes.
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({
    required this.id,
    required this.onPressed,
    this.restartToken = 0,
    this.cooldown = const Duration(seconds: 30),
    super.key,
  });

  final String id;
  final VoidCallback? onPressed;
  final int restartToken;
  final Duration cooldown;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  late int _remaining;

  int get _total => widget.cooldown.inSeconds;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant ResendCodeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restartToken != widget.restartToken) _start();
  }

  void _start() {
    _timer?.cancel();
    _remaining = _total;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining = (_remaining - 1).clamp(0, _total));
      if (_remaining == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coolingDown = _remaining > 0;
    return E2eId(
      id: widget.id,
      child: Semantics(
        label: coolingDown
            ? 'Resend code, available in $_remaining seconds'
            : null,
        excludeSemantics: coolingDown,
        child: TextButton(
          onPressed: coolingDown ? null : widget.onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(
              SnapGrubDesignTokens.minTapTarget,
              SnapGrubDesignTokens.minTapTarget,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (coolingDown) ...[
                SgRing(
                  progress: _remaining / _total,
                  color: scheme.primary,
                  size: 20,
                  thickness: 2.5,
                  animateFromZero: false,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Resend in ${_remaining}s',
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ] else ...[
                const Icon(Icons.refresh_rounded, size: 18),
                const SizedBox(width: 8),
                const Flexible(child: Text('Resend code')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
