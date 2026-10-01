import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/motion.dart';

/// Fades and lifts [child] into place once, after a stagger delay.
/// Use [index] for list entrance choreography (40 ms steps, max 8).
class SgEntrance extends StatefulWidget {
  const SgEntrance({
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 14),
    this.scale = 1,
    super.key,
  });

  final Widget child;
  final int index;
  final Offset offset;
  final double scale;

  @override
  State<SgEntrance> createState() => _SgEntranceState();
}

class _SgEntranceState extends State<SgEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = SgMotion.of(context);
    if (motion.reduced) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(motion.stagger(widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      child: widget.child,
      builder: (context, child) {
        final t = curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: Transform.scale(
              scale: widget.scale + (1 - widget.scale) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
