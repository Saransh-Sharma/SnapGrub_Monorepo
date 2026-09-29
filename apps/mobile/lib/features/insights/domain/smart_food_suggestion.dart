import 'package:snapgrub/features/meal_editor/domain/meal.dart';

enum SmartFoodSuggestionOrigin { frequentDefault, recentMeal, template }

class SmartFoodSuggestionItem {
  const SmartFoodSuggestionItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.foodRefKind = 'manual',
    this.canonicalFoodId,
    this.brandedProductId,
    this.customFoodId,
    this.gramsEstimated,
    this.confidence,
    this.notes,
  });

  final String name;
  final String foodRefKind;
  final String? canonicalFoodId;
  final String? brandedProductId;
  final String? customFoodId;
  final double quantity;
  final String unit;
  final double? gramsEstimated;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? confidence;
  final String? notes;

  String get foodReferenceKey {
    return [
      foodRefKind,
      canonicalFoodId,
      brandedProductId,
      customFoodId,
      _normalize(name),
    ].whereType<String>().join(':');
  }
}

class SmartFoodSuggestion {
  const SmartFoodSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.origin,
    required this.score,
    required this.reasonLabel,
    required this.items,
    this.mealTypeHint,
    this.lastUsedAt,
    this.useCount,
  });

  final String id;
  final String title;
  final String subtitle;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final MealType? mealTypeHint;
  final SmartFoodSuggestionOrigin origin;
  final double score;
  final String reasonLabel;
  final DateTime? lastUsedAt;
  final int? useCount;
  final List<SmartFoodSuggestionItem> items;

  String get dedupeKey {
    final primaryRef = items.isEmpty
        ? title.trim().toLowerCase()
        : items.first.foodReferenceKey;
    return '${_normalize(title)}|$primaryRef';
  }

  SmartFoodSuggestion copyWith({
    double? score,
    String? reasonLabel,
  }) {
    return SmartFoodSuggestion(
      id: id,
      title: title,
      subtitle: subtitle,
      caloriesKcal: caloriesKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      mealTypeHint: mealTypeHint,
      origin: origin,
      score: score ?? this.score,
      reasonLabel: reasonLabel ?? this.reasonLabel,
      lastUsedAt: lastUsedAt,
      useCount: useCount,
      items: items,
    );
  }
}

String smartFoodOriginName(SmartFoodSuggestionOrigin origin) {
  return switch (origin) {
    SmartFoodSuggestionOrigin.frequentDefault => 'frequent_default',
    SmartFoodSuggestionOrigin.recentMeal => 'recent_meal',
    SmartFoodSuggestionOrigin.template => 'template',
  };
}

String _normalize(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
