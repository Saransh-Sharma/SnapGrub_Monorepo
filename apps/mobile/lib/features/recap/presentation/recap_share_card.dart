import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/meal_visuals/presentation/meal_artwork.dart';
import 'package:snapgrub/features/milestones/presentation/milestone_medal.dart';
import 'package:snapgrub/features/recap/domain/weekly_recap.dart';

final _n = NumberFormat.decimalPattern();

String recapRangeLabel(WeeklyRecap recap) {
  final sameMonth = recap.start.month == recap.end.month;
  final a = DateFormat(sameMonth ? 'd' : 'd MMM').format(recap.start);
  final b = DateFormat('d MMM').format(recap.end);
  return '$a – $b';
}

/// 4:5 share card with a holographic-foil border. Rendered off the same
/// widget the user sees, then captured with [captureShareCard].
class RecapShareCard extends StatelessWidget {
  const RecapShareCard({required this.recap, super.key});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    final onHero = tokens.onHero;
    final muted = tokens.onHeroMuted;
    final tier = medalTierForStreak(recap.streak.tier);
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: HoloFoil(
        borderRadius: 28,
        intensity: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SgMetal.gold.highlight,
                SgMetal.silver.base,
                SgMetal.copper.highlight,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ColoredBox(
                color: tokens.hero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('SnapGrub',
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: onHero, letterSpacing: .4)),
                          const Spacer(),
                          Text(recapRangeLabel(recap),
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: muted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (recap.topMeal != null)
                        Expanded(
                          flex: 5,
                          child: MealArtwork(
                            meal: recap.topMeal!,
                            borderRadius: 18,
                            showGenerationLabel: false,
                          ),
                        )
                      else
                        const Spacer(flex: 2),
                      const SizedBox(height: 14),
                      Text('My week',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(color: onHero, height: 1)),
                      Text(
                        recap.mostLogged == null
                            ? '${Labels.count(recap.mealCount, 'meal')} logged.'
                            : 'Top food: ${recap.mostLogged!.name} '
                                '(${recap.mostLogged!.count}×)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.editorial
                            .copyWith(color: muted, fontSize: 17),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Stat(
                            value: _n.format(recap.avgKcal.round()),
                            label: 'avg kcal',
                          ),
                          const SizedBox(width: 18),
                          _Stat(
                            value: '${recap.daysLogged}/7',
                            label: 'days logged',
                          ),
                          const Spacer(),
                          if (tier != null) ...[
                            MilestoneMedal(
                              icon: Icons.local_fire_department_rounded,
                              tier: tier,
                              size: 36,
                              live: false,
                            ),
                            const SizedBox(width: 8),
                          ],
                          _Stat(
                            value: '${recap.streak.current}',
                            label: 'day streak',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: tokens.metricSmall.copyWith(color: tokens.onHero)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: tokens.onHeroMuted)),
      ],
    );
  }
}

/// Renders the [RepaintBoundary] behind [boundaryKey] to a PNG in the temp
/// directory and returns its path.
Future<String> captureShareCard(GlobalKey boundaryKey,
    {double pixelRatio = 3}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('Share card is not on screen yet.');
  }
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Could not encode the share card.');
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final file = File('${dir.path}/snapgrub-week-$stamp.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.path;
  } finally {
    image.dispose();
  }
}

/// Opens the system share sheet with the rendered card.
Future<ShareResult> shareRecapImage(String path, {Rect? origin}) {
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'image/png')],
      text: 'My week on SnapGrub',
      sharePositionOrigin: origin,
    ),
  );
}
