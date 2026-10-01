import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/design_system.dart';

/// Brand moment while auth/profile load: the three circles of the mark drop
/// in on springs, meet, and a titanium glint sweeps across them.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  final ValueNotifier<double> _glint = ValueNotifier(-1);

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final t = (_c.value - .55) / .4;
      _glint.value = t >= 0 && t <= 1 ? t : -1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (SgMotion.of(context).reduced) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _glint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Scaffold(
      body: MeshAurora(
        child: Center(
          child: Semantics(
            label: 'SnapGrub is loading',
            liveRegion: true,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                double drop(double start) => Curves.elasticOut
                    .transform(((_c.value - start) / .5).clamp(0.0, 1.0));
                final a = drop(0);
                final b = drop(.08);
                final c = drop(.16);
                final word = Curves.easeOutCubic
                    .transform(((_c.value - .5) / .4).clamp(0.0, 1.0));
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(0, -60 * (1 - a)),
                            child: Opacity(
                              opacity: a.clamp(0.0, 1.0),
                              child: Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(15, -12 - 70 * (1 - b)),
                            child: Opacity(
                              opacity: b.clamp(0.0, 1.0),
                              child: SizedBox.square(
                                dimension: 30,
                                child: MetalSurface(
                                  metal: SgMetal.copper,
                                  shape: MetalShape.disc,
                                  glint: _glint,
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(-12, 7 - 80 * (1 - c)),
                            child: Opacity(
                              opacity: c.clamp(0.0, 1.0),
                              child: SizedBox.square(
                                dimension: 22,
                                child: MetalSurface(
                                  metal: SgMetal.silver,
                                  shape: MetalShape.disc,
                                  glint: _glint,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: word,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - word)),
                        child: Text('SnapGrub',
                            style: theme.textTheme.headlineMedium),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
