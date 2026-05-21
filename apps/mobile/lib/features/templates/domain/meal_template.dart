import 'dart:convert';

import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class MealTemplate {
  const MealTemplate({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.title,
    required this.snapshot,
    required this.syncStatus,
    this.sourceMealId,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String clientId;
  final String title;
  final Map<String, Object?> snapshot;
  final String? sourceMealId;
  final String syncStatus;
  final DateTime? deletedAt;

  MealDraft toDraft({required String timezone}) {
    final items = (snapshot['items'] as List? ?? const []).map((raw) {
      final item = Map<String, Object?>.from(raw as Map);
      return MealDraftItem(
        name: item['name'] as String? ?? '',
        quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
        unit: item['unit'] as String? ?? 'serving',
        gramsEstimated: (item['grams_estimated'] as num?)?.toDouble(),
        caloriesKcal: (item['calories_kcal'] as num?)?.toDouble() ?? 0,
        proteinG: (item['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (item['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (item['fat_g'] as num?)?.toDouble() ?? 0,
        foodRefKind: item['food_ref_kind'] as String? ?? 'manual',
        customFoodId: item['custom_food_id'] as String?,
        sourceType: item['source_type'] as String?,
        sourceId: item['source_id'] as String?,
        notes: item['notes'] as String?,
      );
    }).toList();
    return MealDraft(
      userId: userId,
      timezone: timezone,
      title: title,
      mealType: MealType.values.firstWhere(
        (type) => type.name == (snapshot['meal_type'] as String?),
        orElse: () => MealType.unknown,
      ),
      source: MealSource.duplicate,
      items: items.isEmpty ? null : items,
    );
  }

  String encodeSnapshot() => jsonEncode(snapshot);
}
