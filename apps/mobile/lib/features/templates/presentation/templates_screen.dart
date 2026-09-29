import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/templates/data/template_repository.dart';
import 'package:snapgrub/features/templates/domain/meal_template.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  /// Saved meals hidden optimistically while their delete waits out Undo.
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final contextData = ref.watch(homeUserContextProvider);
    return AppScaffold(
      title: 'Saved meals',
      e2eId: 'scaffold.templates',
      child: contextData.when(
        loading: () => const _TemplatesSkeleton(),
        error: (error, _) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(homeUserContextProvider),
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              title: 'Sign in to see your saved meals',
              illustration: SgIllustrationKind.notebook,
            );
          }
          final templates = ref.watch(mealTemplatesProvider(data.userId));
          return templates.when(
            loading: () => const _TemplatesSkeleton(),
            error: (error, _) => ErrorState(
              error: error,
              onRetry: () => ref.invalidate(mealTemplatesProvider(data.userId)),
            ),
            data: (all) {
              final items = all.where((t) => !_hidden.contains(t.id)).toList();
              if (items.isEmpty) {
                return const EmptyState(
                  title: 'No saved meals yet',
                  message: 'Save a meal to log it again in one tap.',
                  illustration: SgIllustrationKind.notebook,
                );
              }
              return ListView.separated(
                padding: EdgeInsets.only(
                  top: SnapGrubDesignTokens.space4,
                  bottom: MediaQuery.paddingOf(context).bottom +
                      SnapGrubDesignTokens.space24,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: SnapGrubDesignTokens.space12),
                itemBuilder: (context, index) {
                  final template = items[index];
                  final card = _TemplateCard(
                    template: template,
                    onUse: () => _use(template, data.timezone),
                    onDelete: () => _delete(template),
                  );
                  return index < 8
                      ? SgEntrance(
                          key: ValueKey(template.id),
                          index: index,
                          child: card,
                        )
                      : card;
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Opens Review with the template's items. Nothing is saved until the
  /// user confirms there.
  void _use(MealTemplate template, String timezone) {
    final draft = template.toDraft(timezone: timezone);
    context.push('/meal-editor', extra: draft);
  }

  Future<void> _delete(MealTemplate template) async {
    setState(() => _hidden.add(template.id));
    SgHaptics.warn();
    final repository = ref.read(templateRepositoryProvider);
    await showUndoSnackBar(
      context,
      message: '“${template.title}” deleted',
      icon: Icons.delete_outline_rounded,
      onUndo: () {
        if (mounted) setState(() => _hidden.remove(template.id));
      },
      commit: () async {
        try {
          await repository.delete(template);
        } catch (error) {
          if (mounted) {
            setState(() => _hidden.remove(template.id));
            showSgToast(context, friendlyError(error).message,
                icon: Icons.info_outline_rounded);
          }
        }
      },
    );
  }
}

class _TemplateSummary {
  _TemplateSummary(MealTemplate template) {
    final raw = template.snapshot['items'] as List? ?? const [];
    itemCount = raw.length;
    for (final entry in raw) {
      if (entry is! Map) continue;
      double read(String key) => (entry[key] as num?)?.toDouble() ?? 0;
      kcal += read('calories_kcal');
      protein += read('protein_g');
      carbs += read('carbs_g');
      fat += read('fat_g');
    }
    names = [
      for (final entry in raw)
        if (entry is Map &&
            (entry['name'] as String?)?.trim().isNotEmpty == true)
          (entry['name'] as String).trim(),
    ];
  }

  late final int itemCount;
  late final List<String> names;
  double kcal = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onUse,
    required this.onDelete,
  });

  final MealTemplate template;
  final VoidCallback onUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = _TemplateSummary(template);
    final itemsLabel = Labels.count(summary.itemCount, 'item');
    final preview = summary.names.take(3).join(' · ');
    return E2eId(
      id: 'templates.item.${template.id}',
      child: SgCard(
        variant: SgCardVariant.raised,
        onTap: onUse,
        semanticLabel:
            '${template.title}, $itemsLabel, ${Labels.kcal(summary.kcal)}. '
            'Opens review first.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: SnapGrubDesignTokens.space40,
                  height: SnapGrubDesignTokens.space40,
                  decoration: BoxDecoration(
                    color: context.sg.energy.soft,
                    borderRadius:
                        BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
                  ),
                  child: Icon(
                    Icons.bookmark_rounded,
                    size: SnapGrubDesignTokens.iconMd,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: SnapGrubDesignTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: SnapGrubDesignTokens.space4),
                      Text(
                        preview.isEmpty ? itemsLabel : '$itemsLabel · $preview',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: SnapGrubDesignTokens.space8),
                Text(
                  Labels.kcal(summary.kcal),
                  style: context.sg.metricSmall,
                ),
              ],
            ),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            MacroChips(
              proteinG: summary.protein,
              carbsG: summary.carbs,
              fatG: summary.fat,
              dense: true,
            ),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            Wrap(
              spacing: SnapGrubDesignTokens.space8,
              runSpacing: SnapGrubDesignTokens.space4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                E2eId(
                  id: 'templates.item.${template.id}.use',
                  child: FilledButton.tonalIcon(
                    onPressed: onUse,
                    icon: const Icon(Icons.playlist_add_check_rounded),
                    label: const Text('Log'),
                  ),
                ),
                E2eId(
                  id: 'templates.item.${template.id}.delete',
                  child: TextButton.icon(
                    onPressed: onDelete,
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
      ),
    );
  }
}

class _TemplatesSkeleton extends StatelessWidget {
  const _TemplatesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: SnapGrubDesignTokens.space4),
      children: [
        for (var i = 0; i < 3; i++) ...[
          SgCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SgSkeleton(
                      width: SnapGrubDesignTokens.space40,
                      height: SnapGrubDesignTokens.space40,
                      radius: SnapGrubDesignTokens.radiusXs,
                    ),
                    const SizedBox(width: SnapGrubDesignTokens.space12),
                    Expanded(child: SgSkeleton.lines(count: 2)),
                  ],
                ),
                const SizedBox(height: SnapGrubDesignTokens.space12),
                const SgSkeleton(width: 160, height: 22),
              ],
            ),
          ),
          const SizedBox(height: SnapGrubDesignTokens.space12),
        ],
      ],
    );
  }
}
