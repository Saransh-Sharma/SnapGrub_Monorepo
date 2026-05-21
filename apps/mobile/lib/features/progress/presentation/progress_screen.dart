import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/insights/data/insights_repository.dart';
import 'package:snapgrub/features/insights/domain/weekly_insight.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextData = ref.watch(homeUserContextProvider);
    return AppScaffold(
      title: 'Progress',
      child: contextData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(error.toString()),
        data: (data) {
          if (data == null) return const Text('Sign in to continue.');
          final rollup = ref.watch(todayRollupProvider);
          final insights = ref.watch(latestWeeklyInsightsProvider(data.userId));
          final defaults = ref.watch(frequentFoodDefaultsProvider(data.userId));
          return rollup.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(error.toString()),
            data: (value) => ListView(
              children: [
                _ProgressBody(rollup: value, contextData: data),
                const SizedBox(height: 16),
                if (data.weeklyInsightsEnabled)
                  insights.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text(error.toString()),
                    data: (items) => WeeklyInsightCard(insights: items),
                  ),
                if (!data.weeklyInsightsEnabled) const _InsightDisabledCard(),
                const SizedBox(height: 16),
                StreakCard(insights: insights.valueOrNull ?? const []),
                const SizedBox(height: 16),
                defaults.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(error.toString()),
                  data: (items) =>
                      FrequentMealsSection(defaults: items, contextData: data),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.rollup,
    required this.contextData,
  });

  final DailyRollup rollup;
  final HomeUserContext contextData;

  @override
  Widget build(BuildContext context) {
    final calorieGoal = contextData.calorieGoal ?? 2000;
    return Column(
      children: [
        _ProgressTile(
          label: 'Calories',
          value: rollup.caloriesKcal,
          goal: calorieGoal,
          unit: 'kcal',
        ),
        _ProgressTile(
          label: 'Protein',
          value: rollup.proteinG,
          goal: contextData.proteinGoal ?? 120,
          unit: 'g',
        ),
        _ProgressTile(
          label: 'Carbs',
          value: rollup.carbsG,
          goal: contextData.carbsGoal ?? 200,
          unit: 'g',
        ),
        _ProgressTile(
          label: 'Fat',
          value: rollup.fatG,
          goal: contextData.fatGoal ?? 70,
          unit: 'g',
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: Text('${rollup.mealCount} meals logged'),
            subtitle: Text(rollup.hasPhotoMeal
                ? 'Includes photo-sourced meals'
                : 'Manual/template meals today'),
          ),
        ),
      ],
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
  });

  final String label;
  final double value;
  final double goal;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Text('${value.round()} / ${goal.round()} $unit'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}

class WeeklyInsightCard extends StatelessWidget {
  const WeeklyInsightCard({required this.insights, super.key});

  final List<WeeklyInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.insights_outlined),
          title: Text('Weekly check-in'),
          subtitle: Text('A weekly view appears after a few logged meals.'),
        ),
      );
    }
    final primary = insights.firstWhere(
      (item) => item.insightType == 'next_week_suggestion',
      orElse: () => insights.first,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined),
                const SizedBox(width: 8),
                Text('Weekly check-in',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(primary.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(primary.summary),
            const SizedBox(height: 12),
            for (final insight
                in insights.where((item) => item.id != primary.id).take(3))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${insight.title}: ${insight.summary}'),
              ),
          ],
        ),
      ),
    );
  }
}

class StreakCard extends StatelessWidget {
  const StreakCard({required this.insights, super.key});

  final List<WeeklyInsight> insights;

  @override
  Widget build(BuildContext context) {
    final streak = _firstInsightOfType(insights, 'logging_streak');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month_outlined),
        title: const Text('Logging rhythm'),
        subtitle: Text(
            streak?.summary ?? 'Log a few meals to see your weekly rhythm.'),
      ),
    );
  }
}

class FrequentMealsSection extends ConsumerWidget {
  const FrequentMealsSection({
    required this.defaults,
    required this.contextData,
    super.key,
  });

  final List<UserFoodDefault> defaults;
  final HomeUserContext contextData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (defaults.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.repeat),
          title: Text('Frequent meals'),
          subtitle:
              Text('Repeat foods will appear here after they are logged.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequent foods', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in defaults)
          Card(
            child: ListTile(
              title: Text(item.foodName),
              subtitle: Text(
                  '${_formatQuantity(item.preferredQuantity)} ${item.preferredUnit} · used ${item.useCount} times'),
              trailing: IconButton(
                tooltip: 'Quick add',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () async {
                  final draft = MealDraft(
                    userId: contextData.userId,
                    timezone: contextData.timezone,
                    title: item.foodName,
                    mealType: MealType.snack,
                    source: MealSource.duplicate,
                    items: [
                      MealDraftItem(
                        name: item.foodName,
                        foodRefKind: item.foodRefKind,
                        canonicalFoodId: item.foodRefKind == 'canonical'
                            ? item.foodRefId
                            : null,
                        brandedProductId: item.foodRefKind == 'branded'
                            ? item.foodRefId
                            : null,
                        customFoodId: item.foodRefKind == 'custom'
                            ? item.foodRefId
                            : null,
                        quantity: item.preferredQuantity,
                        unit: item.preferredUnit,
                        gramsEstimated: item.preferredGrams,
                        caloriesKcal: item.caloriesKcal,
                        proteinG: item.proteinG,
                        carbsG: item.carbsG,
                        fatG: item.fatG,
                        sourceType: 'user_food_default',
                        sourceId: item.id,
                      ),
                    ],
                  );
                  await ref.read(mealRepositoryProvider).saveDraft(draft);
                },
              ),
            ),
          ),
      ],
    );
  }
}

WeeklyInsight? _firstInsightOfType(List<WeeklyInsight> insights, String type) {
  for (final insight in insights) {
    if (insight.insightType == type) return insight;
  }
  return null;
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

class _InsightDisabledCard extends StatelessWidget {
  const _InsightDisabledCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.insights_outlined),
        title: Text('Weekly check-in'),
        subtitle: Text('Weekly insights are not enabled for this build.'),
      ),
    );
  }
}
