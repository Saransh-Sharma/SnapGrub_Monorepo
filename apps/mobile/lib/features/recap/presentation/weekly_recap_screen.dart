import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/router/nav.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/features/meal_visuals/presentation/meal_artwork.dart';
import 'package:snapgrub/features/milestones/presentation/milestone_medal.dart';
import 'package:snapgrub/features/recap/application/weekly_recap_provider.dart';
import 'package:snapgrub/features/recap/domain/weekly_recap.dart';
import 'package:snapgrub/features/recap/presentation/recap_share_card.dart';

final _n = NumberFormat.decimalPattern();

enum _Page { cover, topMeal, calories, protein, favourite, streak, share }

/// Full-screen weekly recap in a story format: progress bars on top, tap the
/// left/right third to go back/forward, swipe between pages, long-press to
/// pause. Pages auto-advance every ~5 s (not while a screen reader is on).
/// The last page renders a 4:5 share card and hands it to the share sheet.
class WeeklyRecapScreen extends ConsumerWidget {
  const WeeklyRecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recap = ref.watch(weeklyRecapProvider);
    final tokens = context.sg;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: tokens.hero,
        body: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  onSurface: tokens.onHero,
                  onSurfaceVariant: tokens.onHeroMuted,
                ),
          ),
          child: recap.when(
            loading: () => const Center(
              child: SgSkeleton(width: 220, height: 280, radius: 28),
            ),
            error: (error, _) => _Closeable(
              child: ErrorState(
                error: error,
                onRetry: () => ref.invalidate(weeklyRecapProvider),
              ),
            ),
            data: (value) => value == null || value.isEmpty
                ? const _Closeable(
                    child: EmptyState(
                      illustration: SgIllustrationKind.sunrise,
                      title: 'A quiet week',
                      message: 'Log a few meals and your recap will be '
                          'ready Sunday.',
                    ),
                  )
                : _Story(recap: value),
          ),
        ),
      ),
    );
  }
}

class _Closeable extends StatelessWidget {
  const _Closeable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: child),
            const Positioned(top: 4, right: 4, child: _CloseButton()),
          ],
        ),
      );
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) => E2eId(
        id: 'recap.close',
        child: IconButton(
          tooltip: 'Close',
          color: context.sg.onHero,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.popOrGo('/progress'),
        ),
      );
}

class _Story extends StatefulWidget {
  const _Story({required this.recap});

  final WeeklyRecap recap;

  @override
  State<_Story> createState() => _StoryState();
}

class _StoryState extends State<_Story> with SingleTickerProviderStateMixin {
  static const _pageDuration = Duration(seconds: 5);
  late final List<_Page> _pages = _pagesFor(widget.recap);
  final _pageController = PageController();
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: _pageDuration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _next();
        });
  int _index = 0;
  bool _paused = false;

  static List<_Page> _pagesFor(WeeklyRecap r) => [
        _Page.cover,
        if (r.topMeal != null) _Page.topMeal,
        _Page.calories,
        if (r.proteinDaysHit != null) _Page.protein,
        if (r.mostLogged != null) _Page.favourite,
        _Page.streak,
        _Page.share,
      ];

  bool get _autoAdvance => !MediaQuery.accessibleNavigationOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_progress.isAnimating && _index == 0 && _progress.value == 0) {
      _startPage();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startPage() {
    if (_pages[_index] == _Page.share || !_autoAdvance) {
      _progress.value = _pages[_index] == _Page.share ? 1 : 0;
      return;
    }
    _progress.forward(from: 0);
  }

  void _goTo(int index) {
    if (index < 0 || index >= _pages.length || index == _index) return;
    SgHaptics.tick();
    setState(() => _index = index);
    if (SgMotion.of(context).reduced) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    }
    _startPage();
  }

  void _next() => _goTo(_index + 1);
  void _prev() {
    if (_index == 0) {
      _progress.forward(from: 0);
      return;
    }
    _goTo(_index - 1);
  }

  void _pause() {
    if (_paused) return;
    _paused = true;
    _progress.stop();
    setState(() {});
  }

  void _resume() {
    if (!_paused) return;
    _paused = false;
    if (_autoAdvance && _pages[_index] != _Page.share) _progress.forward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final w = context.size?.width ?? 1;
                if (details.localPosition.dx < w / 3) {
                  _prev();
                } else {
                  _next();
                }
              },
              onLongPressStart: (_) => _pause(),
              onLongPressEnd: (_) => _resume(),
              onLongPressCancel: _resume,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) {
                  if (i == _index) return;
                  setState(() => _index = i);
                  _startPage();
                },
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  child: _pageFor(_pages[i]),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 56,
            top: 12,
            child: _ProgressBars(
              count: _pages.length,
              index: _index,
              progress: _progress,
            ),
          ),
          const Positioned(top: 0, right: 4, child: _CloseButton()),
          if (_paused)
            Positioned(
              left: 0,
              right: 0,
              top: 36,
              child: Center(
                child: Text(
                  'Paused',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.sg.onHeroMuted,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pageFor(_Page page) {
    final r = widget.recap;
    return switch (page) {
      _Page.cover => _CoverPage(recap: r),
      _Page.topMeal => _TopMealPage(recap: r),
      _Page.calories => _CaloriesPage(recap: r),
      _Page.protein => _ProteinPage(recap: r),
      _Page.favourite => _FavouritePage(recap: r),
      _Page.streak => _StreakPage(recap: r),
      _Page.share => _SharePage(recap: r),
    };
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.count,
    required this.index,
    required this.progress,
  });

  final int count;
  final int index;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    return Semantics(
      label: 'Page ${index + 1} of $count',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => Row(
          children: [
            for (var i = 0; i < count; i++)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: tokens.onHero.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: i < index
                        ? 1
                        : i == index
                            ? progress.value.clamp(0.0, 1.0)
                            : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: tokens.onHero,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pages
// ---------------------------------------------------------------------------

class _PageText extends StatelessWidget {
  const _PageText({required this.eyebrow, required this.title, this.body});

  final String eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SgEntrance(
          child: Text(eyebrow.toUpperCase(),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: tokens.onHeroMuted, letterSpacing: 1.6)),
        ),
        const SizedBox(height: 8),
        SgEntrance(
          index: 1,
          child: Text(title,
              style: theme.textTheme.displaySmall
                  ?.copyWith(color: tokens.onHero, height: 1.05)),
        ),
        if (body != null) ...[
          const SizedBox(height: 10),
          SgEntrance(
            index: 2,
            child: Text(body!,
                style: tokens.editorial
                    .copyWith(color: tokens.onHeroMuted, fontSize: 20)),
          ),
        ],
      ],
    );
  }
}

class _CoverPage extends StatelessWidget {
  const _CoverPage({required this.recap});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    return Center(
      child: SgEntrance(
        scale: .92,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                HoloFoil(
                  borderRadius: 32,
                  intensity: .55,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SgMetal.silver.highlight,
                          SgMetal.gold.highlight,
                          SgMetal.silver.base,
                        ],
                      ),
                    ),
                  ),
                ),
                // Soft paper veil at the bottom keeps the headline legible.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FFFCF7), Color(0xCCFFFCF7)],
                      stops: [.35, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SnapGrub',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: SgMetal.gold.shadow)),
                      const Spacer(),
                      Text(
                        'Your\nweek',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: tokens.hero,
                          height: .95,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        recapRangeLabel(recap),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: SgMetal.silver.shadow),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Labels.count(recap.mealCount, 'meal')}'
                        ' · ${Labels.count(recap.daysLogged, 'day')} logged',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: SgMetal.silver.shadow),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopMealPage extends StatelessWidget {
  const _TopMealPage({required this.recap});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final meal = recap.topMeal!;
    final tokens = context.sg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageText(
          eyebrow: 'Meal of the week',
          title: meal.title.isEmpty ? 'Top meal' : meal.title,
          body: '${DateFormat('EEEE').format(meal.loggedAt.toLocal())} · '
              '${_n.format(meal.caloriesKcal.round())} kcal',
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SgEntrance(
            index: 3,
            scale: .94,
            child: Center(
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: tokens.elevation3,
                  ),
                  child: MealArtwork(
                    meal: meal,
                    borderRadius: 28,
                    showGenerationLabel: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CaloriesPage extends StatelessWidget {
  const _CaloriesPage({required this.recap});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final theme = Theme.of(context);
    final peak = recap.dailyKcal.fold<double>(1, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageText(eyebrow: 'On an average day', title: 'You ate'),
        const SizedBox(height: 16),
        SgEntrance(
          index: 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _DelayedRoll(
                value: recap.avgKcal.round(),
                style: tokens.heroNumber
                    .copyWith(color: tokens.onHero, fontSize: 76),
              ),
              const SizedBox(width: 8),
              Text('kcal',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: tokens.onHeroMuted)),
            ],
          ),
        ),
        const Spacer(),
        Semantics(
          label: 'Calories by day: ${[
            for (var i = 0; i < 7; i++)
              '${DateFormat('EEEE').format(recap.start.add(Duration(days: i)))} '
                  '${recap.dailyKcal[i].round()}',
          ].join(', ')}',
          excludeSemantics: true,
          child: SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween:
                                Tween(begin: 0, end: recap.dailyKcal[i] / peak),
                            duration: SgMotion.of(context)
                                .of(Duration(milliseconds: 600 + 70 * i)),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => Container(
                              height: math.max(4, 120 * v),
                              decoration: BoxDecoration(
                                color: recap.dailyKcal[i] > 0
                                    ? tokens.energy.soft
                                    : tokens.onHero.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('E')
                                .format(recap.start.add(Duration(days: i)))
                                .substring(0, 1),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: tokens.onHeroMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// RollingNumber that starts at 0 and rolls to [value] after the page lands.
class _DelayedRoll extends StatefulWidget {
  const _DelayedRoll({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  State<_DelayedRoll> createState() => _DelayedRollState();
}

class _DelayedRollState extends State<_DelayedRoll> {
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _shown = widget.value);
    });
  }

  @override
  Widget build(BuildContext context) => RollingNumber(
        value: SgMotion.of(context).reduced ? widget.value : _shown,
        style: widget.style,
        semanticsLabel: 'Average',
      );
}

class _ProteinPage extends StatelessWidget {
  const _ProteinPage({required this.recap});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final hit = recap.proteinDaysHit ?? 0;
    final target = recap.proteinTargetG!.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageText(
          eyebrow: 'Protein',
          title: '$hit of 7 days',
          body: hit == 0
              ? 'Protein is a good next step. Aim for about $target g a day.'
              : hit >= 5
                  ? 'Near your $target g target most days. Strong week!'
                  : 'Near your $target g target on '
                      '${Labels.count(hit, 'day')}.',
        ),
        const Spacer(),
        SgEntrance(
          index: 3,
          child: Semantics(
            label: '$hit of 7 days reached the protein target',
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  SgRing(
                    progress: i < hit ? 1 : 0,
                    color: tokens.protein.color,
                    trackColor: tokens.onHero.withValues(alpha: .14),
                    size: 38,
                    thickness: 5,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _FavouritePage extends StatelessWidget {
  const _FavouritePage({required this.recap});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final food = recap.mostLogged!;
    return Center(
      child: _PageText(
        eyebrow: 'Most logged',
        title: food.name,
        body: 'Logged ${Labels.count(food.count, 'time')}.',
      ),
    );
  }
}

class _StreakPage extends StatelessWidget {
  const _StreakPage({required this.recap});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final s = recap.streak;
    final tier = medalTierForStreak(s.tier);
    return Column(
      children: [
        const Spacer(),
        SgEntrance(
          scale: .7,
          child: MilestoneMedal(
            icon: Icons.local_fire_department_rounded,
            tier: tier,
            earned: tier != null,
            size: 168,
            semanticLabel: tier == null
                ? 'Streak medal not yet earned'
                : '${tier.label} streak medal',
          ),
        ),
        const SizedBox(height: 32),
        _PageText(
          eyebrow: 'Logging streak',
          title: s.current == 0
              ? 'No streak yet'
              : Labels.count(s.current, 'day'),
          body: s.current == 0
              ? 'Day 1 is one meal away.'
              : s.current >= s.best
                  ? 'Your best streak yet!'
                  : 'Best: ${Labels.count(s.best, 'day')}.',
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _SharePage extends StatefulWidget {
  const _SharePage({required this.recap});

  final WeeklyRecap recap;

  @override
  State<_SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<_SharePage> {
  final _boundary = GlobalKey();
  final _button = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    SgHaptics.tap();
    try {
      final path = await captureShareCard(_boundary);
      final box = _button.currentContext?.findRenderObject() as RenderBox?;
      final origin =
          box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      await shareRecapImage(path, origin: origin);
    } catch (error) {
      if (mounted) {
        showSgToast(context, friendlyError(error).message,
            icon: Icons.info_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    return Column(
      children: [
        const _PageText(eyebrow: 'Share', title: 'Share your week'),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: SgEntrance(
              index: 2,
              scale: .94,
              child: RepaintBoundary(
                key: _boundary,
                child: RecapShareCard(recap: widget.recap),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: E2eId(
            id: 'recap.share',
            child: FilledButton.icon(
              key: _button,
              style: FilledButton.styleFrom(
                backgroundColor: tokens.onHero,
                foregroundColor: tokens.hero,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: tokens.hero),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: const Text('Share'),
            ),
          ),
        ),
      ],
    );
  }
}
