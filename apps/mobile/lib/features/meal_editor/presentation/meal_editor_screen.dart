import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_repository.dart';
import 'package:snapgrub/features/custom_foods/domain/custom_food.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/templates/data/template_repository.dart';

class MealEditorScreen extends ConsumerStatefulWidget {
  const MealEditorScreen({this.mealId, this.initialDraft, super.key});

  final String? mealId;
  final MealDraft? initialDraft;

  @override
  ConsumerState<MealEditorScreen> createState() => _MealEditorScreenState();
}

class _MealEditorScreenState extends ConsumerState<MealEditorScreen> {
  MealDraft? _draft;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    if (_draft != null) return;
    if (widget.initialDraft != null) {
      setState(() {
        _draft = widget.initialDraft;
        _loading = false;
      });
      return;
    }
    final contextData = await ref.read(homeUserContextProvider.future);
    if (contextData == null) return;
    final repo = ref.read(mealRepositoryProvider);
    final mealId = widget.mealId;
    if (mealId == null) {
      setState(() {
        _draft = repo.newManualDraft(
            userId: contextData.userId, timezone: contextData.timezone);
        _loading = false;
      });
      return;
    }

    final meal = await repo.getMeal(mealId);
    if (meal == null) {
      setState(() {
        _error = 'Meal not found.';
        _loading = false;
      });
      return;
    }
    setState(() {
      _draft = MealDraft(
        id: meal.id,
        userId: meal.userId,
        clientId: meal.clientId,
        timezone: meal.timezone,
        title: meal.title,
        mealType: meal.mealType,
        source: meal.source,
        loggedAt: meal.loggedAt,
        expectedRevision: meal.revision,
        confidenceOverall: meal.confidenceOverall,
        provenanceType: meal.provenanceType,
        analysisJobId: meal.analysisJobId,
        photoAssetId: meal.photoAssetId,
        items: meal.items
            .map(
              (item) => MealDraftItem(
                id: item.id,
                clientId: item.clientId,
                name: item.name,
                foodRefKind: item.foodRefKind,
                canonicalFoodId: item.canonicalFoodId,
                brandedProductId: item.brandedProductId,
                customFoodId: item.customFoodId,
                quantity: item.quantity,
                unit: item.unit,
                gramsEstimated: item.gramsEstimated,
                caloriesKcal: item.caloriesKcal,
                proteinG: item.proteinG,
                carbsG: item.carbsG,
                fatG: item.fatG,
                confidence: item.confidence,
                sourceType: item.sourceType,
                sourceId: item.sourceId,
                notes: item.notes,
              ),
            )
            .toList(),
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return AppScaffold(
      title: 'Meal Editor',
      actions: [
        if (draft != null)
          IconButton(
            tooltip: 'Save as template',
            onPressed: _saving ? null : () => _saveTemplate(draft),
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        if (draft != null && widget.mealId != null)
          IconButton(
            tooltip: 'Delete meal',
            onPressed: _saving ? null : () => _deleteMeal(draft.id),
            icon: const Icon(Icons.delete_outline),
          ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Text(_error!)
              : ListView(
                  children: [
                    if (draft!.confidenceOverall != null ||
                        draft.provenanceType != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.confidenceOverall != null &&
                                        draft.confidenceOverall! < 0.7
                                    ? 'Please review this estimate.'
                                    : 'Estimate ready for review.',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Confidence: ${((draft.confidenceOverall ?? 0) * 100).round()}% ${draft.provenanceType ?? ''}',
                              ),
                              if (draft.analysisWarnings.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final warning
                                        in draft.analysisWarnings)
                                      Chip(
                                        avatar: const Icon(Icons.error_outline,
                                            size: 16),
                                        label: Text(warning),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      initialValue: draft.title,
                      decoration:
                          const InputDecoration(labelText: 'Meal title'),
                      onChanged: (value) => draft.title = value,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MealType>(
                      initialValue: draft.mealType,
                      decoration: const InputDecoration(labelText: 'Meal type'),
                      items: MealType.values
                          .map((type) => DropdownMenuItem(
                              value: type, child: Text(type.name)))
                          .toList(),
                      onChanged: (value) => setState(
                          () => draft.mealType = value ?? MealType.unknown),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(_formatMealTime(draft.loggedAt)),
                      subtitle: Text(draft.timezone),
                      trailing: TextButton(
                        onPressed: () => _pickMealTime(draft),
                        child: const Text('Change'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Items',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (var i = 0; i < draft.items.length; i++)
                      _ItemEditor(
                        key: ValueKey(draft.items[i].id),
                        item: draft.items[i],
                        onDelete: draft.items.length == 1
                            ? null
                            : () => setState(() => draft.items.removeAt(i)),
                      ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => draft.items.add(MealDraftItem())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add item'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _insertCustomFood(draft),
                      icon: const Icon(Icons.fastfood_outlined),
                      label: const Text('Add custom food'),
                    ),
                    const SizedBox(height: 16),
                    _Totals(draft: draft),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _save(draft),
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Save meal'),
                    ),
                  ],
                ),
    );
  }

  Future<void> _save(MealDraft draft) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(mealRepositoryProvider).saveDraft(draft);
      if (mounted) context.go('/journal');
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveTemplate(MealDraft draft) async {
    setState(() => _error = null);
    try {
      draft.validate();
      await ref.read(templateRepositoryProvider).saveFromDraft(draft);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Template saved')));
      }
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _deleteMeal(String mealId) async {
    final meal = await ref.read(mealRepositoryProvider).getMeal(mealId);
    if (meal == null) return;
    await ref.read(mealRepositoryProvider).deleteMeal(meal);
    if (mounted) context.go('/journal');
  }

  Future<void> _pickMealTime(MealDraft draft) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: draft.loggedAt,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(draft.loggedAt),
    );
    if (time == null) return;
    setState(() {
      draft.loggedAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _insertCustomFood(MealDraft draft) async {
    final contextData = await ref.read(homeUserContextProvider.future);
    if (contextData == null || !mounted) return;
    final foods =
        await ref.read(customFoodsProvider(contextData.userId).future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<CustomFood>(
      context: context,
      builder: (context) {
        if (foods.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No custom foods yet. Add one from Custom foods.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: foods.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final food = foods[index];
            return ListTile(
              title: Text(food.name),
              subtitle: Text('${food.caloriesKcal.round()} kcal'),
              onTap: () => Navigator.of(context).pop(food),
            );
          },
        );
      },
    );
    if (selected == null) return;
    setState(() {
      draft.items
          .add(ref.read(customFoodRepositoryProvider).toMealItem(selected));
    });
  }

  String _formatMealTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({
    required this.item,
    required this.onDelete,
    super.key,
  });

  final MealDraftItem item;
  final VoidCallback? onDelete;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final needsReview = item.confidence != null && item.confidence! < 0.7;
    return Card(
      color: needsReview
          ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.18)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (needsReview) ...[
              Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 18, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Review this item before saving')),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.name,
                    decoration: const InputDecoration(labelText: 'Food'),
                    onChanged: (value) => item.name = value,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete item',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _NumberField(
                        label: 'Qty',
                        initial: item.quantity,
                        onChanged: (v) => item.quantity = v)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    onChanged: (value) => item.unit = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: 'Grams',
                    initial: item.gramsEstimated,
                    onChanged: (v) => item.gramsEstimated = v,
                    nullable: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _NumberField(
                        label: 'Kcal',
                        initial: item.caloriesKcal,
                        onChanged: (v) => item.caloriesKcal = v)),
                const SizedBox(width: 8),
                Expanded(
                    child: _NumberField(
                        label: 'Protein',
                        initial: item.proteinG,
                        onChanged: (v) => item.proteinG = v)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _NumberField(
                        label: 'Carbs',
                        initial: item.carbsG,
                        onChanged: (v) => item.carbsG = v)),
                const SizedBox(width: 8),
                Expanded(
                    child: _NumberField(
                        label: 'Fat',
                        initial: item.fatG,
                        onChanged: (v) => item.fatG = v)),
              ],
            ),
            if (item.confidence != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                    label: Text(
                        '${(item.confidence! * 100).round()}% confidence')),
              ),
            ],
            if (item.foodRefKind != 'manual') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text(item.foodRefKind)),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              onChanged: (value) => item.notes = value,
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.nullable = false,
  });

  final String label;
  final double? initial;
  final ValueChanged<double> onChanged;
  final bool nullable;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial == null
          ? ''
          : initial!.toStringAsFixed(initial! % 1 == 0 ? 0 : 1),
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: (value) {
        if (nullable && value.trim().isEmpty) return;
        onChanged(double.tryParse(value) ?? 0);
      },
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.draft});

  final MealDraft draft;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${draft.caloriesKcal.round()} kcal'),
            Text('P ${draft.proteinG.round()}g'),
            Text('C ${draft.carbsG.round()}g'),
            Text('F ${draft.fatG.round()}g'),
          ],
        ),
      ),
    );
  }
}
