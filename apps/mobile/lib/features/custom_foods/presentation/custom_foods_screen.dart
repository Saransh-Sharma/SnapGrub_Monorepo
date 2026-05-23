import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/custom_foods/data/custom_food_repository.dart';
import 'package:snapgrub/features/custom_foods/domain/custom_food.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';

class CustomFoodsScreen extends ConsumerWidget {
  const CustomFoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextData = ref.watch(homeUserContextProvider);
    return AppScaffold(
      title: 'Custom foods',
      actions: [
        E2eId(
          id: 'custom_foods.add',
          child: IconButton(
            tooltip: 'Add custom food',
            onPressed: () async {
              final data = contextData.valueOrNull;
              if (data == null) return;
              await _showFoodEditor(
                  context, ref, data.userId, CustomFoodDraft());
            },
            icon: const Icon(Icons.add),
          ),
        ),
      ],
      child: contextData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(error.toString()),
        data: (data) {
          if (data == null) return const Text('Sign in to continue.');
          final foods = ref.watch(customFoodsProvider(data.userId));
          return foods.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(error.toString()),
            data: (items) {
              if (items.isEmpty) return const Text('No custom foods yet.');
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _CustomFoodTile(food: items[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _CustomFoodTile extends ConsumerWidget {
  const _CustomFoodTile({required this.food});

  final CustomFood food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return E2eId(
      id: 'custom_foods.item',
      child: Card(
        child: ListTile(
          title: Text(food.name),
          subtitle: Text(
              '${food.caloriesKcal.round()} kcal · P ${food.proteinG.round()}g · C ${food.carbsG.round()}g · F ${food.fatG.round()}g'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await _showFoodEditor(
                  context,
                  ref,
                  food.userId,
                  CustomFoodDraft(
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
                  ),
                );
              } else if (value == 'delete') {
                await ref.read(customFoodRepositoryProvider).delete(food);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showFoodEditor(
  BuildContext context,
  WidgetRef ref,
  String userId,
  CustomFoodDraft draft,
) async {
  final error = ValueNotifier<String?>(null);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              E2eId(
                id: 'custom_foods.name',
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Food name'),
                  controller: TextEditingController(text: draft.name),
                  onChanged: (value) => draft.name = value,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Brand'),
                controller: TextEditingController(text: draft.brand ?? ''),
                onChanged: (value) => draft.brand = value,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _NumberInput(
                          label: 'Serving',
                          initial: draft.servingQuantity,
                          onChanged: (v) => draft.servingQuantity = v)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Unit'),
                      controller:
                          TextEditingController(text: draft.servingUnit ?? ''),
                      onChanged: (value) => draft.servingUnit = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _NumberInput(
                          label: 'Grams',
                          initial: draft.servingGrams,
                          nullable: true,
                          onChanged: (v) => draft.servingGrams = v)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _NumberInput(
                          label: 'Kcal',
                          initial: draft.caloriesKcal,
                          onChanged: (v) => draft.caloriesKcal = v ?? 0)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _NumberInput(
                          label: 'Protein',
                          initial: draft.proteinG,
                          onChanged: (v) => draft.proteinG = v ?? 0)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _NumberInput(
                          label: 'Carbs',
                          initial: draft.carbsG,
                          onChanged: (v) => draft.carbsG = v ?? 0)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _NumberInput(
                          label: 'Fat',
                          initial: draft.fatG,
                          onChanged: (v) => draft.fatG = v ?? 0)),
                ],
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String?>(
                valueListenable: error,
                builder: (context, value, _) => value == null
                    ? const SizedBox.shrink()
                    : Text(value,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
              ),
              E2eId(
                id: 'custom_foods.save',
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ref
                          .read(customFoodRepositoryProvider)
                          .save(userId, draft);
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      error.value = e.toString();
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.nullable = false,
  });

  final String label;
  final double? initial;
  final ValueChanged<double?> onChanged;
  final bool nullable;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      controller: TextEditingController(
          text: initial == null
              ? ''
              : initial!.toStringAsFixed(initial! % 1 == 0 ? 0 : 1)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: (value) => onChanged(nullable && value.trim().isEmpty
          ? null
          : double.tryParse(value) ?? 0),
    );
  }
}
