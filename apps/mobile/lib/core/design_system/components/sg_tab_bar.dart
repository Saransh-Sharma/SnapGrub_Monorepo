import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/effects/sg_effects.dart';
import 'package:snapgrub/core/design_system/haptics.dart';
import 'package:snapgrub/core/design_system/motion.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

class SgTabItem {
  const SgTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating liquid-glass tab bar with a stretchy "gooey" selection pill and a
/// raised titanium capture button in the middle.
///
/// [items] must have an even count; the capture button sits between the two
/// halves.
class SgTabBar extends StatelessWidget {
  const SgTabBar({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.onCapture,
    this.captureKey,
    super.key,
  }) : assert(items.length % 2 == 0);

  final List<SgTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCapture;
  final Key? captureKey;

  @override
  Widget build(BuildContext context) {
    final half = items.length ~/ 2;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 12),
      child: SizedBox(
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: 6,
              child: LiquidGlass(
                borderRadius: 32,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const captureSlot = 76.0;
                    final slot =
                        (constraints.maxWidth - captureSlot) / items.length;
                    double leftFor(int index) =>
                        index < half ? index * slot : index * slot + captureSlot;
                    return Stack(
                      children: [
                        _GooeyIndicator(
                          left: leftFor(currentIndex),
                          width: slot,
                        ),
                        for (var i = 0; i < items.length; i++)
                          Positioned(
                            left: leftFor(i),
                            width: slot,
                            top: 0,
                            bottom: 0,
                            child: _TabButton(
                              item: items[i],
                              selected: i == currentIndex,
                              onTap: () {
                                if (i != currentIndex) SgHaptics.tick();
                                onSelect(i);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: -10,
              child: CaptureButton(key: captureKey, onPressed: onCapture),
            ),
          ],
        ),
      ),
    );
  }
}

class _GooeyIndicator extends StatefulWidget {
  const _GooeyIndicator({required this.left, required this.width});

  final double left;
  final double width;

  @override
  State<_GooeyIndicator> createState() => _GooeyIndicatorState();
}

class _GooeyIndicatorState extends State<_GooeyIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 460));
  late double _from = widget.left;
  late double _to = widget.left;

  @override
  void didUpdateWidget(covariant _GooeyIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.left != widget.left) {
      _from = _currentLeft();
      _to = widget.left;
      if (SgMotion.of(context).reduced) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    }
  }

  double _currentLeft() =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_c.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // Leading edge moves fast, trailing edge lags: a stretchy blob.
        final lead = Curves.easeOutCubic.transform(_c.value);
        final trail = Curves.easeInOutCubic.transform(_c.value);
        final forward = _to >= _from;
        final a = _from + (_to - _from) * (forward ? trail : lead);
        final b = _from + (_to - _from) * (forward ? lead : trail);
        final left = (forward ? a : b) + 8;
        final right = (forward ? b : a) + widget.width - 8;
        return Positioned(
          left: left,
          width: (right - left).clamp(0, double.infinity),
          top: 10,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SgTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motion = SgMotion.of(context);
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      identifier: 'tab.${item.label.toLowerCase()}',
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1,
              duration: motion.settle,
              curve: motion.emphasized,
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    letterSpacing: .2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The raised titanium capture button: a metal ring with an idle sheen
/// around an ink core. The most-touched control in the app.
class CaptureButton extends StatefulWidget {
  const CaptureButton({
    required this.onPressed,
    this.size = 64,
    this.icon = Icons.photo_camera_rounded,
    this.semanticLabel = 'Log a meal',
    super.key,
  });

  final VoidCallback onPressed;
  final double size;
  final IconData icon;
  final String semanticLabel;

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final motion = SgMotion.of(context);
    return Semantics(
      identifier: 'tab.capture',
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          SgHaptics.impact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _down ? .9 : 1,
          duration: _down ? motion.press : motion.settle,
          curve: _down ? Curves.easeOut : Curves.elasticOut,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: tokens.elevation3,
            ),
            child: MetalSurface(
              metal: SgMetal.titanium,
              shape: MetalShape.disc,
              idleGlint: true,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.hero,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: tokens.onHero, size: 26),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
