import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/shell/app_shell.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/time/user_day.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/insights/application/weekly_checkin_summary_mapper.dart';
import 'package:snapgrub/features/insights/data/insights_repository.dart';
import 'package:snapgrub/features/insights/presentation/smart_foods_section.dart';
import 'package:snapgrub/features/insights/presentation/weekly_checkin_card.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/milestones/application/streak_provider.dart';
import 'package:snapgrub/features/progress/application/progress_controller.dart';
import 'package:snapgrub/features/progress/domain/intake_summary.dart';
import 'package:snapgrub/features/progress/presentation/widgets/calorie_card.dart';
import 'package:snapgrub/features/progress/presentation/widgets/consistency_card.dart';
import 'package:snapgrub/features/progress/presentation/widgets/frequent_foods_section.dart';
import 'package:snapgrub/features/progress/presentation/widgets/macro_averages_card.dart';
import 'package:snapgrub/features/progress/presentation/widgets/milestone_shelf.dart';
import 'package:snapgrub/features/progress/presentation/widgets/range_pill.dart';
import 'package:snapgrub/features/progress/presentation/widgets/weight_card.dart';

export 'package:snapgrub/features/progress/presentation/widgets/frequent_foods_section.dart'
    show FrequentMealsSection;

/// Progress tab root: range control, weight trend, calories, macro averages,
/// consistency + streak, milestones, weekly check-in and repeat foods.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final _repeatsSectionKey = GlobalKey();

  void _scrollToRepeatsSection() {
    final sectionContext = _repeatsSectionKey.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: SgMotion.of(context).reveal,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(homeUserContextProvider);
    final bottom = AppShell.bottomInset(context) + 12;

    Widget body;
    if (userAsync.hasError && !userAsync.hasValue) {
      body = ErrorState(
        error: userAsync.error!,
        onRetry: () => ref.invalidate(homeUserContextProvider),
      );
    } else if (!userAsync.hasValue) {
      body = _ProgressSkeleton(bottom: bottom);
    } else if (userAsync.requireValue == null) {
      body = const EmptyState(
        illustration: SgIllustrationKind.chart,
        title: 'Sign in to see your progress',
        message: 'Your trends live with your account.',
      );
    } else {
      body = _ProgressBody(
        user: userAsync.requireValue!,
        bottom: bottom,
        repeatsKey: _repeatsSectionKey,
        onReviewRepeats: _scrollToRepeatsSection,
      );
    }

    return E2eId(
      id: 'scaffold.progress',
      child: Scaffold(
        body: SafeArea(bottom: false, child: body),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.range});

  final ProgressRange range;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('Progress', style: theme.textTheme.displaySmall),
          ),
          const SizedBox(height: 2),
          Text(
            'Last ${range.label}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ProgressBody extends ConsumerWidget {
  const _ProgressBody({
    required this.user,
    required this.bottom,
    required this.repeatsKey,
    required this.onReviewRepeats,
  });

  final HomeUserContext user;
  final double bottom;
  final GlobalKey repeatsKey;
  final VoidCallback onReviewRepeats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(progressRangeProvider);
    final targets = ref.watch(progressTargetsProvider) ?? const ProgressTargets();
    final intake = ref.watch(intakeSummaryProvider(range));
    final today = ref.watch(userDayTickProvider(user.timezone));

    Widget intakeSection(Widget Function(IntakeSummary) builder) =>
        intake.when(
          skipLoadingOnReload: true,
          loading: () => const SgCard(child: _CardSkeleton()),
          error: (error, _) => SgCard(
            child: ErrorState(
              error: error,
              compact: true,
              onRetry: () => ref.invalidate(intakeSummaryProvider(range)),
            ),
          ),
          data: builder,
        );

    var i = 0;
    Widget enter(Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SgEntrance(index: i++, child: child),
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
      children: [
        _Header(range: range),
        enter(E2eId(
          id: 'progress.range',
          child: ProgressRangePill(
            value: range,
            onChanged: (r) =>
                ref.read(progressRangeProvider.notifier).state = r,
          ),
        )),
        if (targets.isEmpty) enter(const _SetTargetsCard()),
        enter(WeightCard(range: range)),
        enter(intakeSection((s) => CalorieCard(
              summary: s,
              range: range,
              targetKcal: targets.validKcal,
            ))),
        enter(intakeSection(
            (s) => MacroAveragesCard(summary: s, targets: targets))),
        enter(ConsistencyCard(
          loggedDays: ref.watch(loggedDaysProvider),
          streak: ref.watch(streakProvider),
          today: today,
        )),
        enter(const MilestoneShelf()),
        enter(_CheckIn(userId: user.userId, onReviewRepeats: onReviewRepeats)),
        KeyedSubtree(
          key: repeatsKey,
          child: _Repeats(user: user),
        ),
      ],
    );
  }
}

class _SetTargetsCard extends StatelessWidget {
  const _SetTargetsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return E2eId(
      id: 'progress.targets.cta',
      child: SgCard(
        variant: SgCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set your targets',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: context.sg.onHero)),
                  const SizedBox(height: 4),
                  Text(
                    'Add targets to compare your days.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: context.sg.onHeroMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.sg.onHero,
                foregroundColor: context.sg.hero,
              ),
              onPressed: () => context.push('/settings/goal'),
              child: const Text('Set targets'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckIn extends ConsumerWidget {
  const _CheckIn({required this.userId, required this.onReviewRepeats});

  final String userId;
  final VoidCallback onReviewRepeats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Weekly insights are always shown in this UI; missing data gets a
    // friendly empty state rather than a build-flag message.
    final insights = ref.watch(latestWeeklyInsightsProvider(userId));
    void seeWeek() => context.push('/recap');
    return insights.when(
      skipLoadingOnReload: true,
      loading: () => const SgCard(child: _CardSkeleton()),
      error: (_, __) => WeeklyCheckInCard(summary: null, onSeeWeek: seeWeek),
      data: (items) => WeeklyCheckInCard(
        summary: const WeeklyCheckInSummaryMapper().fromInsights(items),
        onReviewRepeatFoods: onReviewRepeats,
        onSeeWeek: seeWeek,
      ),
    );
  }
}

class _Repeats extends ConsumerWidget {
  const _Repeats({required this.user});

  final HomeUserContext user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealType = mealTypeForNow(DateTime.now(), user.timezone);
    if (user.smartFoodsV2Enabled) {
      final suggestions = ref.watch(smartFoodSuggestionsProvider(
        SmartFoodSuggestionsRequest(
          userId: user.userId,
          currentMealType: mealType,
          timezone: user.timezone,
        ),
      ));
      return suggestions.when(
        skipLoadingOnReload: true,
        loading: () => const SgCard(child: _CardSkeleton()),
        error: (error, _) => SgCard(child: ErrorState(error: error, compact: true)),
        data: (items) => SmartFoodsSection(suggestions: items, contextData: user),
      );
    }
    final defaults = ref.watch(frequentFoodDefaultsProvider(user.userId));
    return defaults.when(
      skipLoadingOnReload: true,
      loading: () => const SgCard(child: _CardSkeleton()),
      error: (error, _) => SgCard(child: ErrorState(error: error, compact: true)),
      data: (items) => FrequentMealsSection(
        defaults: items,
        contextData: user,
        mealType: mealType,
      ),
    );
  }
}

/// Meal type suggested for "now" in the user's timezone.
MealType mealTypeForNow(DateTime now, String timezone) {
  final local = userLocalTimeFor(now, timezone);
  if (local.hour < 11) return MealType.breakfast;
  if (local.hour < 16) return MealType.lunch;
  if (local.hour < 21) return MealType.dinner;
  return MealType.snack;
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SgSkeleton(width: 100, height: 14),
          const SizedBox(height: 12),
          const SgSkeleton(height: 120, radius: 16),
          const SizedBox(height: 12),
          SgSkeleton.lines(count: 2),
        ],
      );
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton({required this.bottom});

  final double bottom;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
        children: const [
          SgSkeleton(width: 180, height: 40, radius: 12),
          SizedBox(height: 20),
          SgSkeleton(height: 44, radius: 22),
          SizedBox(height: 14),
          SgCard(child: _CardSkeleton()),
          SizedBox(height: 14),
          SgCard(child: _CardSkeleton()),
        ],
      );
}
