import 'package:snapgrub/features/insights/domain/smart_food_suggestion.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

class SmartFoodSuggestionRanker {
  const SmartFoodSuggestionRanker();

  List<SmartFoodSuggestion> rank({
    required Iterable<SmartFoodSuggestion> suggestions,
    required MealType currentMealType,
    required DateTime now,
    int limit = 8,
  }) {
    final scored = <SmartFoodSuggestion>[];
    final recentCutoff = now.subtract(const Duration(days: 14));

    for (final suggestion in suggestions) {
      var score = suggestion.score;
      final reasons = <String>[];

      if (suggestion.mealTypeHint == currentMealType &&
          currentMealType != MealType.unknown) {
        score += 40;
        reasons.add('Often at ${currentMealType.name}');
      }
      if (suggestion.origin == SmartFoodSuggestionOrigin.frequentDefault &&
          (suggestion.useCount ?? 0) >= 3) {
        score += 25;
        reasons.add('Used ${suggestion.useCount} times');
      }
      final lastUsedAt = suggestion.lastUsedAt;
      if (lastUsedAt != null && lastUsedAt.isAfter(recentCutoff)) {
        score += 15;
        reasons.add('Logged recently');
      }
      if (suggestion.caloriesKcal > 0 &&
          (suggestion.proteinG > 0 ||
              suggestion.carbsG > 0 ||
              suggestion.fatG > 0)) {
        score += 10;
      }
      if (suggestion.origin == SmartFoodSuggestionOrigin.template) {
        score += 5;
        reasons.add('From template');
      }

      scored.add(suggestion.copyWith(
        score: score,
        reasonLabel: reasons.isEmpty ? suggestion.reasonLabel : reasons.first,
      ));
    }

    final byKey = <String, SmartFoodSuggestion>{};
    for (final suggestion in scored) {
      final existing = byKey[suggestion.dedupeKey];
      if (existing == null || suggestion.score > existing.score) {
        byKey[suggestion.dedupeKey] = suggestion;
      }
    }

    final ranked = byKey.values.toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        final aTime = a.lastUsedAt;
        final bTime = b.lastUsedAt;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime);
        }
        return a.title.compareTo(b.title);
      });
    return ranked.take(limit).toList(growable: false);
  }
}
