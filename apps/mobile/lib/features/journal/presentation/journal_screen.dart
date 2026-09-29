import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/application/meal_actions.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

/// Legacy "today's meals" list. The day now lives on Today; this route stays
/// valid (deep links, E2E flows) as a light list that points there.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(todayMealsProvider);
    final hidden = ref.watch(pendingMealDeletionsProvider);
    return AppScaffold(
      title: 'Journal',
      e2eId: 'scaffold.journal',
      actions: [
        E2eId(
          id: 'journal.add_meal',
          child: IconButton(
            tooltip: 'Log meal',
            onPressed: () => context.push('/meal-editor'),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
      ],
      child: meals.when(
        loading: () => ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            SgMealCardSkeleton(),
            SgMealCardSkeleton(),
            SgMealCardSkeleton(),
          ],
        ),
        error: (error, _) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(todayMealsProvider),
        ),
        data: (all) {
          final items = all.where((m) => !hidden.contains(m.id)).toList();
          return ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom +
                  SnapGrubDesignTokens.space24,
            ),
            children: [
              const _MovedBanner(),
              const SizedBox(height: SnapGrubDesignTokens.space16),
              if (items.isEmpty)
                EmptyState(
                  compact: true,
                  title: 'Nothing logged today',
                  message: 'Snap your first meal to see it here.',
                  actionLabel: 'Log a meal',
                  onAction: () => context.push('/meal-editor'),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  SgEntrance(
                    key: ValueKey(items[i].id),
                    index: i,
                    child: _MealCard(meal: items[i]),
                  ),
                  const SizedBox(height: SnapGrubDesignTokens.space12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _MovedBanner extends StatelessWidget {
  const _MovedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    return E2eId(
      id: 'journal.moved_banner',
      child: SgCard(
        color: tokens.energy.soft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.wb_sunny_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: SnapGrubDesignTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your meals are now on Today',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: SnapGrubDesignTokens.space4),
                      Text(
                        'Meals, totals and chat in one place.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            E2eId(
              id: 'journal.go_today',
              child: FilledButton.tonalIcon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Open Today'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends ConsumerWidget {
  const _MealCard({required this.meal});

  final Meal meal;

  static String _mealId(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'journal.meal.${slug.isEmpty ? 'untitled' : slug}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sync = Labels.mealSync(meal.syncStatus);
    final id = _mealId(meal.title);
    final subtitle =
        '${Labels.mealType(meal.mealType)} · ${DateFormat.jm().format(meal.loggedAt)}';
    return SgCard(
      variant: SgCardVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    E2eId(
                      id: id,
                      child:
                          Text(meal.title, style: theme.textTheme.titleMedium),
                    ),
                    const SizedBox(height: SnapGrubDesignTokens.space4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SnapGrubDesignTokens.space8),
              Text(Labels.kcal(meal.caloriesKcal),
                  style: context.sg.metricSmall),
            ],
          ),
          const SizedBox(height: SnapGrubDesignTokens.space12),
          Wrap(
            spacing: SnapGrubDesignTokens.space8,
            runSpacing: SnapGrubDesignTokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MacroChips(
                proteinG: meal.proteinG,
                carbsG: meal.carbsG,
                fatG: meal.fatG,
                dense: true,
              ),
              if (sync != null)
                StatusPill(label: sync.label, icon: sync.icon, tone: sync.tone),
            ],
          ),
          const SizedBox(height: SnapGrubDesignTokens.space8),
          Wrap(
            spacing: SnapGrubDesignTokens.space4,
            children: [
              E2eId(
                id: '$id.edit',
                child: TextButton.icon(
                  onPressed: () => context.push('/meal-editor?id=${meal.id}'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              E2eId(
                id: '$id.duplicate',
                child: TextButton.icon(
                  onPressed: () => MealActions.duplicate(context, ref, meal),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Log again'),
                ),
              ),
              E2eId(
                id: '$id.delete',
                child: TextButton.icon(
                  onPressed: () =>
                      MealActions.deleteWithUndo(context, ref, meal),
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
