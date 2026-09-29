import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feature_flags/feature_flags.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_visuals/data/meal_visual_repository.dart';
import 'package:snapgrub/features/meal_visuals/presentation/meal_artwork.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

/// Atlas tab: a visual diary of every logged meal, grouped by month.
///
/// It is a tab root, so it has no close or settings control — the tab bar
/// is the way out. Tapping a meal opens that day on Today.
class MealAtlasScreen extends ConsumerStatefulWidget {
  const MealAtlasScreen({super.key});

  @override
  ConsumerState<MealAtlasScreen> createState() => _MealAtlasScreenState();
}

class _MealAtlasScreenState extends ConsumerState<MealAtlasScreen> {
  Timer? _syncDebounce;

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }

  /// Tiles enqueue artwork requests individually; one sync picks them all
  /// up instead of one sync per tile.
  void _scheduleArtworkSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      unawaited(
        ref
            .read(syncControllerProvider.notifier)
            .syncNow(trigger: SyncTrigger.foreground),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(allMealsProvider);
    final flags =
        ref.watch(profileControllerProvider).valueOrNull?.featureFlags ??
            const {};
    final artworkEnabled =
        FeatureFlags(flags).isEnabled(FeatureFlag.generatedMealVisuals);
    return AppScaffold(
      title: 'Atlas',
      e2eId: 'screen.meal_atlas',
      padding: EdgeInsets.zero,
      child: meals.when(
        skipLoadingOnReload: true,
        loading: () => const _AtlasSkeleton(),
        error: (error, _) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(allMealsProvider),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                title: 'Your Atlas starts here',
                message: 'Every meal you log appears here, by month.',
                illustration: SgIllustrationKind.plate,
                actionLabel: 'Log a meal',
                onAction: () => context.push('/capture'),
              )
            : E2eId(
                id: 'atlas.content',
                child: _AtlasContent(
                  meals: items,
                  artworkEnabled: artworkEnabled,
                  onArtworkRequested: _scheduleArtworkSync,
                ),
              ),
      ),
    );
  }
}

class _MonthGroup {
  _MonthGroup(this.month);

  final DateTime month;
  final List<Meal> meals = [];
  double kcal = 0;
}

List<_MonthGroup> _groupByMonth(List<Meal> meals) {
  final sorted = [...meals]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  final groups = <_MonthGroup>[];
  for (final meal in sorted) {
    final local = meal.loggedAt.toLocal();
    final month = DateTime(local.year, local.month);
    if (groups.isEmpty || groups.last.month != month) {
      groups.add(_MonthGroup(month));
    }
    groups.last
      ..meals.add(meal)
      ..kcal += meal.caloriesKcal;
  }
  return groups;
}

class _AtlasContent extends StatelessWidget {
  const _AtlasContent({
    required this.meals,
    required this.artworkEnabled,
    required this.onArtworkRequested,
  });

  final List<Meal> meals;
  final bool artworkEnabled;
  final VoidCallback onArtworkRequested;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByMonth(meals);
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final columns = textScale > 1.3
          ? 1
          : constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 600
                  ? 3
                  : 2;
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              SnapGrubDesignTokens.space20,
              SnapGrubDesignTokens.space16,
              SnapGrubDesignTokens.space20,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${Labels.count(meals.length, 'meal')} so far',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          for (final group in groups) ...[
            SliverToBoxAdapter(
              child: _MonthHeader(group: group),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: SnapGrubDesignTokens.space16,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: SnapGrubDesignTokens.space12,
                  crossAxisSpacing: SnapGrubDesignTokens.space12,
                  childAspectRatio: columns == 1 ? 1.25 : .8,
                ),
                itemCount: group.meals.length,
                itemBuilder: (context, index) {
                  final meal = group.meals[index];
                  return _AtlasMealTile(
                    key: ValueKey(meal.id),
                    meal: meal,
                    artworkEnabled: artworkEnabled,
                    onArtworkRequested: onArtworkRequested,
                  );
                },
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SizedBox(height: bottom + SnapGrubDesignTokens.space24),
          ),
        ],
      );
    });
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.group});

  final _MonthGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = group.meals.length;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SnapGrubDesignTokens.space20,
          SnapGrubDesignTokens.space24,
          SnapGrubDesignTokens.space20,
          SnapGrubDesignTokens.space12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(group.month),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${Labels.count(count, 'meal')} · ${Labels.kcal(group.kcal)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtlasMealTile extends ConsumerStatefulWidget {
  const _AtlasMealTile({
    required this.meal,
    required this.artworkEnabled,
    required this.onArtworkRequested,
    super.key,
  });

  final Meal meal;
  final bool artworkEnabled;
  final VoidCallback onArtworkRequested;

  @override
  ConsumerState<_AtlasMealTile> createState() => _AtlasMealTileState();
}

class _AtlasMealTileState extends ConsumerState<_AtlasMealTile> {
  @override
  void initState() {
    super.initState();
    if (widget.artworkEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestArtwork());
    }
  }

  Future<void> _requestArtwork() async {
    if (!mounted) return;
    try {
      await ref.read(mealVisualRepositoryProvider).request(widget.meal);
      widget.onArtworkRequested();
    } catch (_) {
      // Artwork is decorative; the tile already shows a fallback.
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final theme = Theme.of(context);
    final when = DateFormat.MMMd().format(meal.loggedAt.toLocal());
    return E2eId(
      id: 'atlas.meal.${meal.id}',
      child: PremiumPressable(
        semanticLabel: '${meal.title}, $when, '
            '${meal.caloriesKcal.round()} calories. Opens that day.',
        onTap: () => context.go(
          '/home?day=${_day(meal.loggedAt.toLocal())}&meal=${meal.id}',
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MealArtwork(
                meal: meal,
                borderRadius: 0,
                hero: true,
                showGenerationLabel: false,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [.45, 1],
                  ),
                ),
              ),
              Positioned(
                left: SnapGrubDesignTokens.space12,
                right: SnapGrubDesignTokens.space12,
                bottom: SnapGrubDesignTokens.space12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: SnapGrubDesignTokens.space4),
                    Text(
                      '$when · ${Labels.kcal(meal.caloriesKcal)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: .85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _day(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class _AtlasSkeleton extends StatelessWidget {
  const _AtlasSkeleton();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SnapGrubDesignTokens.space16,
            SnapGrubDesignTokens.space24,
            SnapGrubDesignTokens.space16,
            0,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: SnapGrubDesignTokens.space12,
            crossAxisSpacing: SnapGrubDesignTokens.space12,
            childAspectRatio: .8,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const SgSkeleton(
            height: double.infinity,
            radius: SnapGrubDesignTokens.radiusMd,
          ),
        ),
      );
}
