import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/effects/effects_scope.dart';
import 'package:snapgrub/core/design_system/tokens.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';

enum SgIllustrationKind { plate, notebook, sunrise, chart, camera, offline, medal }

/// Small token-built vignettes for empty, error and permission states.
/// They breathe very slightly while effects animate.
class SgIllustration extends StatefulWidget {
  const SgIllustration({required this.kind, this.size = 120, super.key});

  final SgIllustrationKind kind;
  final double size;

  @override
  State<SgIllustration> createState() => _SgIllustrationState();
}

class _SgIllustrationState extends State<SgIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SgEffectsScope.of(context).animates) {
      if (!_idle.isAnimating) _idle.repeat();
    } else {
      _idle.stop();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.sg;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _IllustrationPainter(
            kind: widget.kind,
            idle: _idle,
            primary: scheme.primary,
            soft: scheme.primaryContainer,
            accent: tokens.protein.color,
            gold: tokens.carbs.color,
            ink: scheme.onSurface,
            paper: Theme.of(context).cardTheme.color ?? scheme.surface,
          ),
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter({
    required this.kind,
    required this.idle,
    required this.primary,
    required this.soft,
    required this.accent,
    required this.gold,
    required this.ink,
    required this.paper,
  }) : super(repaint: idle);

  final SgIllustrationKind kind;
  final Animation<double> idle;
  final Color primary;
  final Color soft;
  final Color accent;
  final Color gold;
  final Color ink;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final bob = math.sin(idle.value * math.pi * 2) * s * .015;
    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .025
      ..strokeCap = StrokeCap.round
      ..color = ink.withValues(alpha: .75);

    // Soft halo behind every vignette.
    canvas.drawCircle(c, s * .46, fill..color = soft.withValues(alpha: .55));

    switch (kind) {
      case SgIllustrationKind.plate:
        canvas.drawCircle(c.translate(0, bob), s * .30, fill..color = paper);
        canvas.drawCircle(c.translate(0, bob), s * .30, line);
        canvas.drawCircle(c.translate(0, bob), s * .21,
            line..color = ink.withValues(alpha: .25));
        canvas.drawCircle(c.translate(-s * .07, bob - s * .05), s * .07,
            fill..color = accent);
        canvas.drawCircle(c.translate(s * .08, bob + s * .02), s * .055,
            fill..color = primary);
        canvas.drawCircle(
            c.translate(-s * .01, bob + s * .09), s * .045, fill..color = gold);
        final fork = line..color = ink.withValues(alpha: .7);
        canvas.drawLine(c.translate(-s * .40, -s * .20),
            c.translate(-s * .40, s * .24), fork);
        canvas.drawLine(c.translate(s * .40, -s * .20),
            c.translate(s * .40, s * .24), fork);
      case SgIllustrationKind.notebook:
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: c.translate(0, bob), width: s * .5, height: s * .6),
          Radius.circular(s * .05),
        );
        canvas.drawRRect(r, fill..color = paper);
        canvas.drawRRect(r, line);
        for (var i = 0; i < 4; i++) {
          final y = r.top + s * (.14 + i * .1);
          canvas.drawLine(Offset(r.left + s * .08, y),
              Offset(r.right - s * (i == 3 ? .2 : .08), y),
              line..color = ink.withValues(alpha: .3));
        }
        canvas.drawCircle(Offset(r.right, r.top + s * .06), s * .06,
            fill..color = accent);
      case SgIllustrationKind.sunrise:
        canvas.drawCircle(c.translate(0, s * .06 - bob * 2), s * .16,
            fill..color = gold);
        canvas.drawRect(
          Rect.fromLTWH(c.dx - s * .4, c.dy + s * .1, s * .8, s * .3),
          fill..color = soft,
        );
        canvas.drawLine(Offset(c.dx - s * .34, c.dy + s * .1),
            Offset(c.dx + s * .34, c.dy + s * .1), line);
      case SgIllustrationKind.chart:
        final base = c.dy + s * .22;
        final bars = [.18, .3, .24, .38, .32];
        for (var i = 0; i < bars.length; i++) {
          final x = c.dx - s * .28 + i * s * .14;
          final h = s * bars[i] * (1 + (i == 3 ? bob / s * 4 : 0));
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x, base - h, s * .09, h),
                Radius.circular(s * .03)),
            fill..color = i == 3 ? primary : primary.withValues(alpha: .35),
          );
        }
        canvas.drawLine(Offset(c.dx - s * .34, base),
            Offset(c.dx + s * .34, base), line);
      case SgIllustrationKind.camera:
        final body = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: c.translate(0, bob), width: s * .6, height: s * .42),
          Radius.circular(s * .08),
        );
        canvas.drawRRect(body, fill..color = paper);
        canvas.drawRRect(body, line);
        canvas.drawCircle(c.translate(0, bob), s * .12, fill..color = primary);
        canvas.drawCircle(
            c.translate(0, bob), s * .06, fill..color = soft);
        canvas.drawCircle(c.translate(s * .2, bob - s * .12), s * .03,
            fill..color = accent);
      case SgIllustrationKind.offline:
        final path = Path()
          ..addOval(Rect.fromCircle(
              center: c.translate(-s * .1, bob), radius: s * .14))
          ..addOval(Rect.fromCircle(
              center: c.translate(s * .08, bob - s * .05), radius: s * .17))
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromLTWH(c.dx - s * .26, c.dy + bob, s * .5, s * .14),
              Radius.circular(s * .07)));
        canvas.drawPath(path, fill..color = paper);
        canvas.drawLine(c.translate(-s * .22, -s * .18),
            c.translate(s * .22, s * .2), line..color = accent);
      case SgIllustrationKind.medal:
        canvas.drawCircle(c.translate(0, s * .06 + bob), s * .2,
            fill..color = gold);
        canvas.drawCircle(c.translate(0, s * .06 + bob), s * .14,
            line..color = paper.withValues(alpha: .8));
        final ribbon = Path()
          ..moveTo(c.dx - s * .12, c.dy - s * .34)
          ..lineTo(c.dx - s * .02, c.dy - s * .1 + bob)
          ..lineTo(c.dx + s * .02, c.dy - s * .1 + bob)
          ..lineTo(c.dx + s * .12, c.dy - s * .34)
          ..close();
        canvas.drawPath(ribbon, fill..color = primary);
    }
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter old) =>
      old.kind != kind || old.primary != primary || old.ink != ink;
}

/// Calm, helpful empty state with an optional call to action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.message,
    this.illustration = SgIllustrationKind.plate,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.compact = false,
    super.key,
  });

  final String title;
  final String? message;
  final SgIllustrationKind illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 24, vertical: compact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SgIllustration(kind: illustration, size: compact ? 84 : 120),
            SizedBox(height: compact ? 12 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: compact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.headlineSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 14 : 22),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 4),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state that explains what happened in human words and offers retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.error,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final friendly = friendlyError(error);
    return EmptyState(
      title: friendly.title,
      message: friendly.message,
      illustration: friendly.offline
          ? SgIllustrationKind.offline
          : SgIllustrationKind.notebook,
      actionLabel: friendly.retryable && onRetry != null ? 'Try again' : null,
      onAction: onRetry,
      compact: compact,
    );
  }
}

/// Inline, single-line error for forms and cards.
class InlineError extends StatelessWidget {
  const InlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
