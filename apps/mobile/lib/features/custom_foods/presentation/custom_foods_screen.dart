import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/core/feedback/undo.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_repository.dart';
import 'package:snapgrub/features/custom_foods/domain/custom_food.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';

class CustomFoodsScreen extends ConsumerStatefulWidget {
  const CustomFoodsScreen({super.key});

  @override
  ConsumerState<CustomFoodsScreen> createState() => _CustomFoodsScreenState();
}

class _CustomFoodsScreenState extends ConsumerState<CustomFoodsScreen> {
  /// Foods hidden optimistically while their delete waits out Undo.
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final contextData = ref.watch(homeUserContextProvider);
    final userId = contextData.valueOrNull?.userId;
    return AppScaffold(
      title: 'My foods',
      e2eId: 'scaffold.custom_foods',
      actions: [
        E2eId(
          id: 'custom_foods.add',
          child: IconButton(
            tooltip: 'Add food',
            onPressed: userId == null ? null : () => _openEditor(userId),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
      ],
      child: contextData.when(
        loading: () => const _FoodsSkeleton(),
        error: (error, _) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(homeUserContextProvider),
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              title: 'Sign in to see your foods',
              illustration: SgIllustrationKind.plate,
            );
          }
          final foods = ref.watch(customFoodsProvider(data.userId));
          return foods.when(
            loading: () => const _FoodsSkeleton(),
            error: (error, _) => ErrorState(
              error: error,
              onRetry: () => ref.invalidate(customFoodsProvider(data.userId)),
            ),
            data: (all) {
              final items =
                  all.where((food) => !_hidden.contains(food.id)).toList();
              if (items.isEmpty) {
                return EmptyState(
                  title: 'No saved foods yet',
                  message: 'Save your go-to foods and recipes to log them in '
                      'one tap.',
                  illustration: SgIllustrationKind.plate,
                  actionLabel: 'Add food',
                  onAction: () => _openEditor(data.userId),
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
                  final food = items[index];
                  final tile = _CustomFoodTile(
                    food: food,
                    onEdit: () => _openEditor(food.userId, food: food),
                    onDelete: () => _delete(food),
                  );
                  return index < 8
                      ? SgEntrance(
                          key: ValueKey(food.id),
                          index: index,
                          child: tile,
                        )
                      : tile;
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(String userId, {CustomFood? food}) async {
    final saved = await showCustomFoodEditor(
      context,
      ref,
      userId: userId,
      food: food,
    );
    if (saved != null && mounted) {
      SgHaptics.logged();
      showSgToast(
        context,
        food == null ? 'Added “${saved.name}”' : 'Saved “${saved.name}”',
      );
    }
  }

  Future<void> _delete(CustomFood food) async {
    setState(() => _hidden.add(food.id));
    SgHaptics.warn();
    final repository = ref.read(customFoodRepositoryProvider);
    await showUndoSnackBar(
      context,
      message: '“${food.name}” deleted',
      icon: Icons.delete_outline_rounded,
      onUndo: () {
        if (mounted) setState(() => _hidden.remove(food.id));
      },
      commit: () async {
        try {
          await repository.delete(food);
        } catch (error) {
          if (mounted) {
            setState(() => _hidden.remove(food.id));
            showSgToast(context, friendlyError(error).message,
                icon: Icons.info_outline_rounded);
          }
        }
      },
    );
  }
}

String _servingLabel(CustomFood food) {
  final qty = food.servingQuantity;
  final unit = food.servingUnit?.trim();
  final parts = <String>[
    if (qty != null)
      '${formatNumber(qty)} ${unit == null || unit.isEmpty ? 'serving' : unit}',
    if (food.servingGrams != null) Labels.grams(food.servingGrams!),
  ];
  return parts.join(' · ');
}

class _CustomFoodTile extends StatelessWidget {
  const _CustomFoodTile({
    required this.food,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomFood food;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = food.brand?.trim();
    final serving = _servingLabel(food);
    final meta = [
      if (brand != null && brand.isNotEmpty) brand,
      if (serving.isNotEmpty) serving,
    ].join(' · ');
    return E2eId(
      id: 'custom_foods.item.${food.id}',
      child: SgCard(
        variant: SgCardVariant.raised,
        onTap: onEdit,
        semanticLabel:
            '${food.name}, ${Labels.kcal(food.caloriesKcal)} per serving. '
            'Tap to edit.',
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
                      Text(
                        food.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: SnapGrubDesignTokens.space4),
                        Text(
                          meta,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: SnapGrubDesignTokens.space8),
                Text(Labels.kcal(food.caloriesKcal),
                    style: context.sg.metricSmall),
                PopupMenuButton<String>(
                  tooltip: 'More options for ${food.name}',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Delete'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: SnapGrubDesignTokens.space8),
            MacroChips(
              proteinG: food.proteinG,
              carbsG: food.carbsG,
              fatG: food.fatG,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the custom-food editor sheet. Returns the saved food, or null when
/// dismissed.
Future<CustomFood?> showCustomFoodEditor(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  CustomFood? food,
}) async {
  final draft = food == null
      ? CustomFoodDraft()
      : CustomFoodDraft(
          id: food.id,
          clientId: food.clientId,
          name: food.name,
          brand: food.brand,
          servingQuantity: food.servingQuantity,
          servingUnit: food.servingUnit,
          servingGrams: food.servingGrams,
          caloriesKcal: food.caloriesKcal,
          proteinG: food.proteinG,
          carbsG: food.carbsG,
          fatG: food.fatG,
        );
  // Not disposed explicitly: the sheet's exit animation may still be
  // listening after the future completes; it holds no resources.
  final state = _EditorState();
  final repository = ref.read(customFoodRepositoryProvider);
  return showSgSheet<CustomFood>(
    context: context,
    title: food == null ? 'New food' : 'Edit food',
    subtitle: 'Nutrition per serving.',
    builder: (_) => _CustomFoodForm(draft: draft, state: state),
    actions: Builder(
      builder: (sheetContext) => ListenableBuilder(
        listenable: state,
        builder: (sheetContext, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null) ...[
              InlineError(message: state.error!),
              const SizedBox(height: SnapGrubDesignTokens.space12),
            ],
            E2eId(
              id: 'custom_foods.save',
              child: FilledButton.icon(
                onPressed: state.saving
                    ? null
                    : () async {
                        state.begin();
                        try {
                          final saved = await repository.save(userId, draft);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop(saved);
                          }
                        } catch (error) {
                          SgHaptics.warn();
                          state.fail(friendlyError(error).message);
                        }
                      },
                icon: state.saving
                    ? const SizedBox.square(
                        dimension: SnapGrubDesignTokens.iconSm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(food == null ? 'Save food' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EditorState extends ChangeNotifier {
  bool saving = false;
  String? error;

  void begin() {
    saving = true;
    error = null;
    notifyListeners();
  }

  void fail(String message) {
    saving = false;
    error = message;
    notifyListeners();
  }
}

/// Owns its text controllers so rebuilds (keyboard, errors) never reset the
/// cursor or leak controllers.
class _CustomFoodForm extends StatefulWidget {
  const _CustomFoodForm({required this.draft, required this.state});

  final CustomFoodDraft draft;
  final _EditorState state;

  @override
  State<_CustomFoodForm> createState() => _CustomFoodFormState();
}

class _CustomFoodFormState extends State<_CustomFoodForm> {
  late final _name = TextEditingController(text: widget.draft.name);
  late final _brand = TextEditingController(text: widget.draft.brand ?? '');
  late final _unit =
      TextEditingController(text: widget.draft.servingUnit ?? '');

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    const gap = SizedBox(height: SnapGrubDesignTokens.space12);
    const hGap = SizedBox(width: SnapGrubDesignTokens.space12);
    // Stack pairs vertically at large text sizes so labels never truncate.
    final stack = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    Widget pair(Widget a, Widget b) => stack
        ? Column(children: [a, gap, b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: a), hGap, Expanded(child: b)],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        E2eId(
          id: 'custom_foods.name',
          child: TextField(
            controller: _name,
            autofocus: draft.id == null,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (value) => draft.name = value,
          ),
        ),
        gap,
        TextField(
          controller: _brand,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Brand',
            helperText: 'Optional',
          ),
          onChanged: (value) => draft.brand = value,
        ),
        const SizedBox(height: SnapGrubDesignTokens.space20),
        SgSectionHeader(
          title: 'Serving',
          padding: const EdgeInsets.only(bottom: SnapGrubDesignTokens.space8),
        ),
        pair(
          SgNumberField(
            label: 'Amount',
            value: draft.servingQuantity,
            onChanged: (v) => draft.servingQuantity = v,
          ),
          TextField(
            controller: _unit,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Unit',
              hintText: 'slice, cup…',
            ),
            onChanged: (value) => draft.servingUnit = value,
          ),
        ),
        gap,
        SgNumberField(
          label: 'Weight',
          suffix: 'g',
          nullable: true,
          helper: 'Optional. Helps scale portions.',
          value: draft.servingGrams,
          onChanged: (v) => draft.servingGrams = v,
        ),
        const SizedBox(height: SnapGrubDesignTokens.space20),
        SgSectionHeader(
          title: 'Nutrition',
          padding: const EdgeInsets.only(bottom: SnapGrubDesignTokens.space8),
        ),
        pair(
          SgNumberField(
            label: 'Calories',
            suffix: 'kcal',
            value: draft.caloriesKcal,
            onChanged: (v) => draft.caloriesKcal = v ?? 0,
          ),
          SgNumberField(
            label: 'Protein',
            suffix: 'g',
            value: draft.proteinG,
            onChanged: (v) => draft.proteinG = v ?? 0,
          ),
        ),
        gap,
        pair(
          SgNumberField(
            label: 'Carbs',
            suffix: 'g',
            value: draft.carbsG,
            onChanged: (v) => draft.carbsG = v ?? 0,
          ),
          SgNumberField(
            label: 'Fat',
            suffix: 'g',
            value: draft.fatG,
            onChanged: (v) => draft.fatG = v ?? 0,
          ),
        ),
      ],
    );
  }
}

class _FoodsSkeleton extends StatelessWidget {
  const _FoodsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: SnapGrubDesignTokens.space4),
      children: [
        for (var i = 0; i < 4; i++) ...[
          SgCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SgSkeleton.lines(count: 2),
                const SizedBox(height: SnapGrubDesignTokens.space12),
                const SgSkeleton(width: 150, height: 20),
              ],
            ),
          ),
          const SizedBox(height: SnapGrubDesignTokens.space12),
        ],
      ],
    );
  }
}
