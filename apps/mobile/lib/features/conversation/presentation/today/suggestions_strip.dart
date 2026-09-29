import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/insights/application/smart_food_draft_factory.dart';
import 'package:snapgrub/features/insights/data/insights_repository.dart';
import 'package:snapgrub/features/insights/domain/smart_food_suggestion.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

MealType mealTypeForHour(int hour) {
  if (hour >= 5 && hour < 11) return MealType.breakfast;
  if (hour >= 11 && hour < 16) return MealType.lunch;
  if (hour >= 17 && hour < 22) return MealType.dinner;
  return MealType.snack;
}

/// "Your usual around now": one-tap chips that open Review (never auto-save).
class SuggestionsStrip extends ConsumerWidget {
  const SuggestionsStrip({required this.user, super.key});

  final HomeUserContext user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final suggestions = ref
            .watch(smartFoodSuggestionsProvider(SmartFoodSuggestionsRequest(
              userId: user.userId,
              currentMealType: mealTypeForHour(now.hour),
              timezone: user.timezone,
            )))
            .valueOrNull ??
        const <SmartFoodSuggestion>[];
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SgSectionHeader(title: 'Your usuals'),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: suggestions.length.clamp(0, 8),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = suggestions[i];
              return SgEntrance(
                index: i,
                offset: const Offset(16, 0),
                child: PremiumPressable(
                  semanticLabel:
                      'Log ${s.title} again, ${s.caloriesKcal.round()} calories',
                  onTap: () async {
                    final draft = const SmartFoodDraftFactory().toDraft(
                      suggestion: s,
                      userId: user.userId,
                      timezone: user.timezone,
                      now: DateTime.now(),
                    );
                    // Review first; the editor announces the logged meal.
                    await context.push<Object?>('/meal-editor', extra: draft);
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: context.sg.energy.soft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.replay_rounded,
                              size: 17, color: context.sg.energy.onSoft),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge),
                              Text('${s.caloriesKcal.round()} kcal',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
