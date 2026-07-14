import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/time/user_day.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/insights/application/weekly_checkin_summary_mapper.dart';
import 'package:snapgrub/features/insights/data/insights_repository.dart';
import 'package:snapgrub/features/insights/domain/weekly_insight.dart';
import 'package:snapgrub/features/insights/presentation/smart_foods_section.dart';
import 'package:snapgrub/features/insights/presentation/weekly_checkin_card.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          final defaults = data.smartFoodsV2Enabled
              ? null
              : ref.watch(frequentFoodDefaultsProvider(data.userId));
          final smartSuggestions = data.smartFoodsV2Enabled
              ? ref.watch(smartFoodSuggestionsProvider(
                  SmartFoodSuggestionsRequest(
                    userId: data.userId,
                    currentMealType:
                        _mealTypeForNow(DateTime.now(), data.timezone),
                    timezone: data.timezone,
                  ),
                ))
              : null;
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
                    data: (items) => WeeklyCheckInCard(
                      summary: const WeeklyCheckInSummaryMapper()
                          .fromInsights(items),
                      onReviewRepeatFoods: _scrollToRepeatsSection,
                    ),
                  ),
                if (!data.weeklyInsightsEnabled) const _InsightDisabledCard(),
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: _repeatsSectionKey,
                  child: data.smartFoodsV2Enabled
                      ? smartSuggestions!.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (error, _) => Text(error.toString()),
                          data: (items) => SmartFoodsSection(
                            suggestions: items,
                            contextData: data,
                          ),
                        )
                      : defaults!.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (error, _) => Text(error.toString()),
                          data: (items) => FrequentMealsSection(
                            defaults: items,
                            contextData: data,
                          ),
                        ),
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

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

MealType _mealTypeForNow(DateTime now, String timezone) {
  final local = userLocalTimeFor(now, timezone);
  if (local.hour < 11) return MealType.breakfast;
  if (local.hour < 16) return MealType.lunch;
  if (local.hour < 21) return MealType.dinner;
  return MealType.snack;
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
