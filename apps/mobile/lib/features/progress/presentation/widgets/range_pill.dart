import 'package:flutter/material.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/progress/domain/intake_summary.dart';

/// 7 / 30 / 90-day switch. The selection pill stretches toward the new
/// segment and then settles (a small "morph"), with a tick haptic.
class ProgressRangePill extends StatefulWidget {
  const ProgressRangePill({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ProgressRange value;
  final ValueChanged<ProgressRange> onChanged;

  @override
  State<ProgressRangePill> createState() => _ProgressRangePillState();
}

class _ProgressRangePillState extends State<ProgressRangePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );
  late int _from = widget.value.index;

  @override
  void didUpdateWidget(covariant ProgressRangePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = oldWidget.value.index;
      if (SgMotion.of(context).reduced) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.sg;
    const values = ProgressRange.values;
    return Semantics(
      container: true,
      label: 'Range',
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusPill),
          border:
              Border.all(color: scheme.outlineVariant.withValues(alpha: .6)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth / values.length;
            return Stack(
              children: [
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final to = widget.value.index;
                    // Leading edge moves first, trailing edge follows: the
                    // pill stretches mid-flight, then contracts.
                    final lead = Curves.easeOutCubic.transform(_c.value);
                    final trail = Curves.easeInOutCubic
                        .transform((_c.value * 1.25 - .25).clamp(0, 1));
                    final movingRight = to >= _from;
                    final left = movingRight
                        ? _lerp(_from * w, to * w, trail)
                        : _lerp(_from * w, to * w, lead);
                    final right = movingRight
                        ? _lerp((_from + 1) * w, (to + 1) * w, lead)
                        : _lerp((_from + 1) * w, (to + 1) * w, trail);
                    return Positioned(
                      left: left,
                      width: right - left,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.hero,
                          borderRadius: BorderRadius.circular(
                              SnapGrubDesignTokens.radiusPill),
                          boxShadow: tokens.elevation1,
                        ),
                      ),
                    );
                  },
                ),
                Material(
                  type: MaterialType.transparency,
                  child: Row(
                    children: [
                      for (final r in values)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: r == widget.value,
                            label: r.label,
                            excludeSemantics: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                  SnapGrubDesignTokens.radiusPill),
                              onTap: r == widget.value
                                  ? null
                                  : () {
                                      SgHaptics.tick();
                                      widget.onChanged(r);
                                    },
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: SgMotion.of(context).settle,
                                  style: theme.textTheme.labelLarge!.copyWith(
                                    color: r == widget.value
                                        ? tokens.onHero
                                        : scheme.onSurfaceVariant,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                  child: Text(r.short),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
