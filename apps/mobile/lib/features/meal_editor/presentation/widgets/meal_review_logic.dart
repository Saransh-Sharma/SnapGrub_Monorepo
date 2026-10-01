import 'package:flutter/foundation.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/labels.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

/// Items under this confidence get a gentle "Check portion" nudge.
const lowConfidenceThreshold = .7;

bool isLowConfidence(MealDraftItem item) =>
    item.confidence != null && item.confidence! < lowConfidenceThreshold;

/// Nutrition per single unit of an item, captured when a row is expanded so
/// the portion stepper can scale calories and macros proportionally.
@immutable
class PortionBase {
  const PortionBase({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.grams,
  });

  /// Captures the per-unit values from [item]. A zero quantity is treated as
  /// one unit so the stepper still has something sensible to scale.
  factory PortionBase.capture(MealDraftItem item) {
    final quantity = item.quantity > 0 ? item.quantity : 1.0;
    return PortionBase(
      kcal: item.caloriesKcal / quantity,
      protein: item.proteinG / quantity,
      carbs: item.carbsG / quantity,
      fat: item.fatG / quantity,
      grams:
          item.gramsEstimated == null ? null : item.gramsEstimated! / quantity,
    );
  }

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double? grams;

  /// Sets [item] to [quantity] units, scaling everything from this base.
  void applyTo(MealDraftItem item, double quantity) {
    item
      ..quantity = quantity
      ..caloriesKcal = _round(kcal * quantity)
      ..proteinG = _round(protein * quantity)
      ..carbsG = _round(carbs * quantity)
      ..fatG = _round(fat * quantity)
      ..gramsEstimated = grams == null ? null : _round(grams! * quantity);
  }

  static double _round(double value) => (value * 10).roundToDouble() / 10;
}

/// "1 cup · 180 g" — quantity, unit and (when known) grams.
String portionLabel(MealDraftItem item) {
  final unit = item.unit.trim();
  final quantity = formatNumber(item.quantity, decimals: 2);
  final amount = unit.isEmpty ? quantity : '$quantity $unit';
  final grams = item.gramsEstimated;
  if (grams == null || grams <= 0) return amount;
  return '$amount · ${grams.round()} g';
}

/// Where an item's numbers come from, for the collapsed row: a catalog or
/// saved food, or a model estimate. Null for hand-entered items.
String? itemSourceLabel(MealDraftItem item) {
  if (item.foodRefKind != 'manual') {
    return Labels.foodReference(item.foodRefKind);
  }
  return (item.sourceType?.startsWith('ai_') ?? false) ? 'Estimated' : null;
}

/// Screen-reader summary for a row: "Rice, 1 cup, 206 calories".
String itemSemanticLabel(MealDraftItem item) {
  final name = item.name.trim().isEmpty ? 'New item' : item.name.trim();
  final unit = item.unit.trim();
  final quantity = formatNumber(item.quantity, decimals: 2);
  final amount = unit.isEmpty ? quantity : '$quantity $unit';
  final kcal = item.caloriesKcal.round();
  final check = isLowConfidence(item) ? ', check portion' : '';
  return '$name, $amount, $kcal calories$check';
}

/// A stable fingerprint of everything the user can edit, used to decide
/// whether leaving the screen would throw work away.
String mealDraftFingerprint(MealDraft draft) {
  final buffer = StringBuffer()
    ..writeln(draft.title)
    ..writeln(draft.mealType.name)
    ..writeln(draft.loggedAt.toIso8601String());
  for (final item in draft.items) {
    buffer.writeln([
      item.id,
      item.name,
      item.quantity,
      item.unit,
      item.gramsEstimated,
      item.caloriesKcal,
      item.proteinG,
      item.carbsG,
      item.fatG,
      item.notes,
    ].join('|'));
  }
  return buffer.toString();
}

/// Content identity of an item (ignores ids) for highlighting rows that an
/// AI correction actually changed.
String itemContentSignature(MealDraftItem item) => [
      item.name.trim().toLowerCase(),
      item.quantity,
      item.unit.trim().toLowerCase(),
      item.caloriesKcal.round(),
      item.proteinG.round(),
      item.carbsG.round(),
      item.fatG.round(),
    ].join('|');
