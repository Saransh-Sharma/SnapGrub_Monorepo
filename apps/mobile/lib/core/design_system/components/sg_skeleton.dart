import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/effects/effects_scope.dart';

/// Brand-tinted shimmer placeholder with a soft metallic sweep.
class SgSkeleton extends StatefulWidget {
  const SgSkeleton({
    this.width,
    this.height = 16,
    this.radius = 10,
    this.circle = false,
    super.key,
  });

  /// A column of text-line skeletons.
  static Widget lines({int count = 3, double spacing = 10}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < count; i++) ...[
            FractionallySizedBox(
              widthFactor: i == count - 1 ? .6 : 1,
              child: const SgSkeleton(height: 14),
            ),
            if (i < count - 1) SizedBox(height: spacing),
          ],
        ],
      );

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<SgSkeleton> createState() => _SgSkeletonState();
}

class _SgSkeletonState extends State<SgSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SgEffectsScope.of(context).animates) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.onSurface.withValues(alpha: .07);
    final shine = scheme.primaryContainer.withValues(alpha: .9);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 2.6 - .8;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius:
                  widget.circle ? null : BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1 + t, -.3),
                end: Alignment(t, .3),
                colors: [base, shine.withValues(alpha: .55), base],
                stops: const [.25, .5, .75],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton shaped like a meal card, for loading day logs.
class SgMealCardSkeleton extends StatelessWidget {
  const SgMealCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SgSkeleton(width: 64, height: 64, radius: 16),
            const SizedBox(width: 14),
            Expanded(child: SgSkeleton.lines(count: 2)),
          ],
        ),
      );
}
