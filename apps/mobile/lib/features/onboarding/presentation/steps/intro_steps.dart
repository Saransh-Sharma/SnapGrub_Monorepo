import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/onboarding/application/onboarding_controller.dart';
import 'package:snapgrub/features/onboarding/presentation/widgets/onboarding_chrome.dart';

// ---------------------------------------------------------------------------
// 1. Welcome
// ---------------------------------------------------------------------------

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space16,
        SnapGrubDesignTokens.space24,
        SnapGrubDesignTokens.space24,
      ),
      child: OnboardingEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: SnapGrubMark(size: 44),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space16),
            const _WelcomeDemo(),
            const SizedBox(height: SnapGrubDesignTokens.space24),
            Semantics(
              header: true,
              child: Text(
                'Snap a meal.\nWe’ll do the math.',
                style: theme.textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            Text(
              'Calories and macros from a photo. Answer a few questions to '
              'get your plan.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Looping mini-demo: a meal photo, a scan beam sweep, then a meal card whose
/// macro chips pop in. Static (final frame) when motion is reduced.
class _WelcomeDemo extends StatefulWidget {
  const _WelcomeDemo();

  @override
  State<_WelcomeDemo> createState() => _WelcomeDemoState();
}

class _WelcomeDemoState extends State<_WelcomeDemo>
    with SingleTickerProviderStateMixin {
  static const _restFrame = .84;
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
    value: _restFrame,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ambientMotionOf(context)) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop
        ..stop()
        ..value = _restFrame;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  static double _interval(double t, double begin, double end,
      [Curve curve = Curves.easeOutCubic]) {
    final raw = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    return ExcludeSemantics(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: AmbientTickerMode(
          child: SizedBox(
            height: 300,
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, _) {
                final t = _loop.value;
                final fadeOut = t > .94 ? 1 - (t - .94) / .06 : 1.0;
                final photoIn = _interval(t, 0, .1);
                final scanning = t >= .1 && t < .48;
                final beam = _interval(t, .1, .48, Curves.easeInOut);
                final cardIn = _interval(t, .45, .6, Curves.easeOutBack);
                final chips = _interval(t, .58, .76, Curves.elasticOut);
                final photo = _MealPhoto(beam: scanning ? beam : null);
                return Opacity(
                  opacity: fadeOut.clamp(0.0, 1.0),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: 0,
                        child: Opacity(
                          opacity: photoIn,
                          child: Transform.scale(
                            scale: .94 + .06 * photoIn,
                            child: SizedBox(
                              width: 230,
                              height: 190,
                              child: scanning
                                  ? ScanBeam(
                                      key: const ValueKey('beam'),
                                      child: photo,
                                    )
                                  : photo,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Opacity(
                          opacity: cardIn.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 36 * (1 - cardIn)),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 320),
                                child: SgCard(
                                  variant: SgCardVariant.raised,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: tokens.energy.soft,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.restaurant_rounded,
                                          color: tokens.energy.color,
                                          size: SnapGrubDesignTokens.iconMd,
                                        ),
                                      ),
                                      const SizedBox(
                                          width: SnapGrubDesignTokens.space12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Salmon rice bowl',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall,
                                                  ),
                                                ),
                                                Text('540 kcal',
                                                    style: tokens.metricSmall),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Transform.scale(
                                              alignment: Alignment.centerLeft,
                                              scale: chips.clamp(0.0, 1.2),
                                              child: const MacroChips(
                                                proteinG: 34,
                                                carbsG: 58,
                                                fatG: 17,
                                                dense: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Illustrated "photo" of a bowl, with a light sweep line while scanning.
class _MealPhoto extends StatelessWidget {
  const _MealPhoto({this.beam});

  /// 0..1 sweep position while scanning; null when idle.
  final double? beam;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
      child: CustomPaint(
        painter: _BowlPainter(
          table: tokens.dark ? scheme.surfaceContainerHigh : tokens.carbs.soft,
          plate: scheme.surfaceContainerLowest,
          rim: tokens.outlineStrong,
          rice: scheme.surfaceContainerHighest,
          greens: tokens.energy.color,
          salmon: tokens.protein.color,
          sauce: tokens.carbs.color,
          seeds: tokens.fat.color,
          beam: beam,
          beamColor: scheme.primary,
        ),
      ),
    );
  }
}

class _BowlPainter extends CustomPainter {
  const _BowlPainter({
    required this.table,
    required this.plate,
    required this.rim,
    required this.rice,
    required this.greens,
    required this.salmon,
    required this.sauce,
    required this.seeds,
    required this.beam,
    required this.beamColor,
  });

  final Color table;
  final Color plate;
  final Color rim;
  final Color rice;
  final Color greens;
  final Color salmon;
  final Color sauce;
  final Color seeds;
  final double? beam;
  final Color beamColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = table);
    final c = rect.center;
    final r = size.shortestSide * .42;
    canvas.drawCircle(c + const Offset(0, 6), r,
        Paint()..color = Colors.black.withValues(alpha: .08));
    canvas.drawCircle(c, r, Paint()..color = plate);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = rim.withValues(alpha: .5));
    final inner = r * .8;
    canvas.drawCircle(c, inner, Paint()..color = rice);
    // Salmon slices.
    final salmonPaint = Paint()..color = salmon;
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(c.dx - inner * .25 + i * inner * .2, c.dy - inner * .2);
      canvas.rotate(-.5 + i * .12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: inner * .26, height: inner * .62),
          Radius.circular(inner * .1),
        ),
        salmonPaint,
      );
      canvas.restore();
    }
    // Greens.
    final greenPaint = Paint()..color = greens;
    for (var i = 0; i < 7; i++) {
      final a = math.pi * .15 + i * .32;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * inner * .6,
        inner * .14,
        greenPaint,
      );
    }
    // Sauce + seeds.
    canvas.drawCircle(c + Offset(inner * .42, -inner * .38), inner * .16,
        Paint()..color = sauce);
    final seedPaint = Paint()..color = seeds;
    for (var i = 0; i < 9; i++) {
      final a = i * 1.7;
      canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * inner * (.2 + (i % 3) * .12),
          1.6,
          seedPaint);
    }
    final b = beam;
    if (b != null) {
      final y = size.height * b;
      final band = Rect.fromLTWH(0, y - 26, size.width, 52);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              beamColor.withValues(alpha: 0),
              beamColor.withValues(alpha: .28),
              beamColor.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = beamColor.withValues(alpha: .8)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BowlPainter old) =>
      old.beam != beam || old.table != table || old.plate != plate;
}

// ---------------------------------------------------------------------------
// 2. Name
// ---------------------------------------------------------------------------

class NameStep extends ConsumerStatefulWidget {
  const NameStep({required this.active, required this.onSubmit, super.key});

  final bool active;
  final VoidCallback onSubmit;

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(onboardingControllerProvider).displayName,
  );
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.active) _focusSoon();
  }

  @override
  void didUpdateWidget(covariant NameStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _focusSoon();
    if (!widget.active && oldWidget.active) _focus.unfocus();
  }

  void _focusSoon() {
    if (_controller.text.isNotEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    return OnboardingStepBody(
      question: 'What should we call you?',
      why: 'Used in your greeting.',
      children: [
        E2eId(
          id: 'onboarding.display_name',
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: notifier.updateName,
            onSubmitted: (_) => widget.onSubmit(),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            maxLength: 40,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Asha',
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}
