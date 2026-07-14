import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/time/user_day.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/capture/application/capture_controller.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/home/presentation/widgets/daily_progress_card.dart';
import 'package:snapgrub/features/home/presentation/widgets/macro_summary_card.dart';
import 'package:snapgrub/features/home/presentation/widgets/quick_actions_row.dart';
import 'package:snapgrub/features/home/presentation/widgets/recent_meals_carousel.dart';
import 'package:snapgrub/features/home/presentation/widgets/snap_strip.dart';
import 'package:snapgrub/features/insights/data/insights_repository.dart';
import 'package:snapgrub/features/insights/presentation/smart_foods_section.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(captureControllerProvider.notifier).initializeIfPermitted();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(captureControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        controller.resumePreview();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        controller.pausePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userContext = ref.watch(homeUserContextProvider);
    final rollup = ref.watch(todayRollupProvider);
    final meals = ref.watch(todayMealsProvider);
    return AppScaffold(
      title: 'Today',
      actions: [
        E2eId(
          id: 'home.sync',
          child: IconButton(
            tooltip: 'Sync',
            onPressed: () =>
                ref.read(syncControllerProvider.notifier).syncNow(),
            icon: const Icon(Icons.sync),
          ),
        ),
        E2eId(
          id: 'home.settings',
          child: IconButton(
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ),
      ],
      child: userContext.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(error.toString()),
        data: (contextData) {
          if (contextData == null) return const Text('Sign in to continue.');
          final rollupData = rollup.valueOrNull;
          final mealData = meals.valueOrNull ?? const [];
          final smartSuggestions = contextData.smartFoodsV2Enabled
              ? ref.watch(smartFoodSuggestionsProvider(
                  SmartFoodSuggestionsRequest(
                    userId: contextData.userId,
                    currentMealType:
                        _mealTypeForNow(DateTime.now(), contextData.timezone),
                    timezone: contextData.timezone,
                  ),
                ))
              : null;
          return RefreshIndicator(
            onRefresh: () => ref
                .read(syncControllerProvider.notifier)
                .syncNow(trigger: SyncTrigger.pullToRefresh),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SnapStrip(),
                _SyncAttentionCard(
                    status: ref.watch(syncControllerProvider).valueOrNull ??
                        SyncStatus.idle),
                const SizedBox(height: 16),
                if (rollupData != null)
                  DailyProgressCard(
                      rollup: rollupData, contextData: contextData),
                if (rollupData != null) ...[
                  const SizedBox(height: 12),
                  MacroSummaryCard(
                      rollup: rollupData, contextData: contextData),
                ],
                const SizedBox(height: 12),
                const QuickActionsRow(),
                const SizedBox(height: 16),
                Text('Recent meals',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                RecentMealsCarousel(meals: mealData),
                if (smartSuggestions != null) ...[
                  const SizedBox(height: 16),
                  smartSuggestions.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text(error.toString()),
                    data: (items) => SmartFoodsSection(
                      suggestions: items,
                      contextData: contextData,
                      maxItems: 3,
                      showHeader: true,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

MealType _mealTypeForNow(DateTime now, String timezone) {
  final local = userLocalTimeFor(now, timezone);
  if (local.hour < 11) return MealType.breakfast;
  if (local.hour < 16) return MealType.lunch;
  if (local.hour < 21) return MealType.dinner;
  return MealType.snack;
}

class _SyncAttentionCard extends StatelessWidget {
  const _SyncAttentionCard({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    if (status != SyncStatus.conflict && status != SyncStatus.failed) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: ListTile(
          leading: Icon(status == SyncStatus.conflict
              ? Icons.report_problem_outlined
              : Icons.error_outline),
          title: Text(status == SyncStatus.conflict
              ? 'Sync needs review'
              : 'Sync retry pending'),
          subtitle: Text(status == SyncStatus.conflict
              ? 'Review conflicting local changes before the next sync.'
              : 'Some local changes failed and will retry automatically.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/sync'),
        ),
      ),
    );
  }
}
