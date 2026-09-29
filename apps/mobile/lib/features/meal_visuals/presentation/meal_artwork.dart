import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/theme/premium_surfaces.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_visuals/data/meal_visual_repository.dart';
import 'package:snapgrub/features/meal_visuals/domain/meal_visual.dart';

class MealArtwork extends ConsumerWidget {
  const MealArtwork({
    required this.meal,
    this.borderRadius = 22,
    this.hero = false,
    this.showGenerationLabel = true,
    super.key,
  });

  final Meal meal;
  final double borderRadius;
  final bool hero;
  final bool showGenerationLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visual = ref.watch(mealVisualProvider(meal)).valueOrNull;
    final originalPath =
        ref.watch(mealAssetPathProvider(meal.photoAssetId)).valueOrNull;
    final path = visual?.localPath ?? originalPath;
    Widget artwork;
    if (path != null && File(path).existsSync()) {
      artwork = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => StudioMealPlaceholder(title: meal.title),
      );
    } else {
      artwork = StudioMealPlaceholder(title: meal.title);
    }
    artwork = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MealImageReveal(child: artwork),
          if (visual?.status == MealVisualStatus.queued ||
              visual?.status == MealVisualStatus.generating)
            _ArtworkGeneratingOverlay(showLabel: showGenerationLabel),
        ],
      ),
    );
    return hero ? Hero(tag: 'meal-art-${meal.id}', child: artwork) : artwork;
  }
}

class _ArtworkGeneratingOverlay extends StatefulWidget {
  const _ArtworkGeneratingOverlay({required this.showLabel});

  final bool showLabel;

  @override
  State<_ArtworkGeneratingOverlay> createState() =>
      _ArtworkGeneratingOverlayState();
}

class _ArtworkGeneratingOverlayState extends State<_ArtworkGeneratingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final x = reduceMotion ? 0.0 : (_controller.value * 3) - 1.5;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(x - 1, -1),
                    end: Alignment(x + 1, 1),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: .22),
                      Colors.transparent,
                    ],
                    stops: const [.34, .5, .66],
                  ),
                ),
              );
            },
          ),
          if (widget.showLabel)
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .42),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Creating image…',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StudioMealPlaceholder extends StatelessWidget {
  const StudioMealPlaceholder({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final seed =
        title.codeUnits.fold<int>(17, (value, unit) => value * 31 + unit);
    final random = Random(seed);
    final palettes = <List<Color>>[
      const [Color(0xFFE2C59B), Color(0xFF8E6045), Color(0xFFF4E5C8)],
      const [Color(0xFFACC3A5), Color(0xFF49634E), Color(0xFFE4D9B9)],
      const [Color(0xFFEAB18D), Color(0xFF9E4F39), Color(0xFFF4DDB8)],
      const [Color(0xFFC5B8D4), Color(0xFF675675), Color(0xFFE8DABF)],
    ];
    final colors = palettes[random.nextInt(palettes.length)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors[2], colors[0]],
        ),
      ),
      child: CustomPaint(
        painter: _PlatePainter(colors: colors, seed: seed),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  const _PlatePainter({required this.colors, required this.seed});

  final List<Color> colors;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .52, size.height * .49);
    final plateRadius = min(size.width, size.height) * .34;
    canvas.drawCircle(
      center + Offset(0, plateRadius * .12),
      plateRadius * 1.03,
      Paint()..color = Colors.black.withValues(alpha: .12),
    );
    canvas.drawCircle(
        center, plateRadius, Paint()..color = const Color(0xFFFFFBF2));
    canvas.drawCircle(
      center,
      plateRadius * .78,
      Paint()..color = colors[0].withValues(alpha: .76),
    );
    final random = Random(seed);
    for (var i = 0; i < 12; i++) {
      final angle = random.nextDouble() * pi * 2;
      final distance = random.nextDouble() * plateRadius * .54;
      final point = center + Offset(cos(angle), sin(angle)) * distance;
      canvas.drawCircle(
        point,
        plateRadius * (.07 + random.nextDouble() * .08),
        Paint()..color = colors[i.isEven ? 1 : 2].withValues(alpha: .88),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlatePainter oldDelegate) =>
      oldDelegate.seed != seed;
}
