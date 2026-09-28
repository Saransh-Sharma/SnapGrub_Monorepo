import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/haptics.dart';

/// Press-and-hold destructive button: a fill sweeps across while held and the
/// action fires only when it completes. Releasing early cancels.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    required this.label,
    required this.onConfirmed,
    this.icon = Icons.delete_outline_rounded,
    this.holdFor = const Duration(milliseconds: 1400),
    super.key,
  });

  final String label;
  final VoidCallback? onConfirmed;
  final IconData icon;
  final Duration holdFor;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold =
      AnimationController(vsync: this, duration: widget.holdFor)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            SgHaptics.warn();
            widget.onConfirmed?.call();
            _hold.value = 0;
          }
        });
  int _lastTick = 0;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.onConfirmed == null) return;
    SgHaptics.tap();
    _hold.forward();
  }

  void _cancel() {
    if (_hold.isCompleted) return;
    _hold.animateBack(0, duration: const Duration(milliseconds: 220));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onConfirmed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${widget.label}. Press and hold to confirm.',
      onTap: enabled ? widget.onConfirmed : null,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, _) {
            final tick = (_hold.value * 4).floor();
            if (tick != _lastTick && _hold.status == AnimationStatus.forward) {
              _lastTick = tick;
              SgHaptics.tick();
            }
            return Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: scheme.error.withValues(alpha: .6)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _hold.value,
                    child: ColoredBox(color: scheme.error),
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon,
                            size: 20,
                            color: _hold.value > .5
                                ? scheme.onError
                                : scheme.error),
                        const SizedBox(width: 8),
                        Text(
                          _hold.value > 0 ? 'Keep holding…' : widget.label,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: _hold.value > .5
                                    ? scheme.onError
                                    : scheme.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
