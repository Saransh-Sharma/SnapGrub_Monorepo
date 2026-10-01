import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/meal_editor/presentation/widgets/meal_review_logic.dart';

MealDraftItem _rice() => MealDraftItem(
      name: 'Rice',
      quantity: 1,
      unit: 'cup',
      gramsEstimated: 180,
      caloriesKcal: 206,
      proteinG: 4.3,
      carbsG: 45,
      fatG: .4,
      confidence: .55,
    );

void main() {
  test('portion base scales calories, macros and grams proportionally', () {
    final item = _rice();
    PortionBase.capture(item).applyTo(item, 1.5);

    expect(item.quantity, 1.5);
    expect(item.caloriesKcal, 309);
    expect(item.proteinG, 6.5);
    expect(item.carbsG, 67.5);
    expect(item.fatG, .6);
    expect(item.gramsEstimated, 270);
  });

  test('portion base keeps scaling from the captured values', () {
    final item = _rice()..quantity = 2;
    final base = PortionBase.capture(item);
    base.applyTo(item, 2.25);
    base.applyTo(item, 1);

    // Per-unit base was 206 / 2 = 103.
    expect(item.caloriesKcal, 103);
  });

  test('zero quantity is treated as one unit', () {
    final item = _rice()..quantity = 0;
    PortionBase.capture(item).applyTo(item, 2);
    expect(item.caloriesKcal, 412);
  });

  test('labels read like people talk', () {
    final item = _rice();
    expect(portionLabel(item), '1 cup · 180 g');
    expect(itemSemanticLabel(item), 'Rice, 1 cup, 206 calories, check portion');
    expect(isLowConfidence(item), isTrue);

    item
      ..gramsEstimated = null
      ..quantity = 1.25
      ..confidence = .9;
    expect(portionLabel(item), '1.25 cup');
    expect(isLowConfidence(item), isFalse);
  });

  test('fingerprint changes with edits and ignores nothing editable', () {
    final draft = MealDraft(
      userId: 'u',
      timezone: 'UTC',
      title: 'Lunch',
      items: [_rice()],
    );
    final before = mealDraftFingerprint(draft);
    expect(mealDraftFingerprint(draft), before);

    draft.items.first.caloriesKcal = 250;
    expect(mealDraftFingerprint(draft), isNot(before));
  });

  test('item source label separates catalog, estimate and hand entry', () {
    expect(
      itemSourceLabel(MealDraftItem(name: 'Roti', foodRefKind: 'canonical')),
      'Verified food',
    );
    expect(
      itemSourceLabel(MealDraftItem(name: 'Salmon', sourceType: 'ai_text')),
      'Estimated',
    );
    expect(itemSourceLabel(MealDraftItem(name: 'Rice')), isNull);
  });
}
