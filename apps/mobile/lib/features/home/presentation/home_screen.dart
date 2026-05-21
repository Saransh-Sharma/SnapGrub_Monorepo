import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/home/presentation/widgets/daily_progress_card.dart';
import 'package:snapgrub/features/home/presentation/widgets/macro_summary_card.dart';
import 'package:snapgrub/features/home/presentation/widgets/quick_actions_row.dart';
import 'package:snapgrub/features/home/presentation/widgets/recent_meals_carousel.dart';
import 'package:snapgrub/features/home/presentation/widgets/snap_strip.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userContext = ref.watch(homeUserContextProvider);
    final rollup = ref.watch(todayRollupProvider);
    final meals = ref.watch(todayMealsProvider);
    return AppScaffold(
      title: 'Today',
      actions: [
        IconButton(
          tooltip: 'Sync',
          onPressed: () => ref.read(syncControllerProvider.notifier).syncNow(),
          icon: const Icon(Icons.sync),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: userContext.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(error.toString()),
        data: (contextData) {
          if (contextData == null) return const Text('Sign in to continue.');
          final rollupData = rollup.valueOrNull;
          final mealData = meals.valueOrNull ?? const [];
          return RefreshIndicator(
            onRefresh: () => ref.read(syncControllerProvider.notifier).syncNow(trigger: SyncTrigger.pullToRefresh),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SnapStrip(),
                const SizedBox(height: 16),
                if (rollupData != null) DailyProgressCard(rollup: rollupData, contextData: contextData),
                if (rollupData != null) ...[
                  const SizedBox(height: 12),
                  MacroSummaryCard(rollup: rollupData, contextData: contextData),
                ],
                const SizedBox(height: 12),
                const QuickActionsRow(),
                const SizedBox(height: 16),
                Text('Recent meals', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                RecentMealsCarousel(meals: mealData),
              ],
            ),
          );
        },
      ),
    );
  }
}
