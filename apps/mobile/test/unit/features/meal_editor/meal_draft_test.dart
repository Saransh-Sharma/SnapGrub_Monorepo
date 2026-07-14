import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/custom_foods/domain/custom_food.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/templates/domain/meal_template.dart';

void main() {
  test('manual draft validates with one complete item', () {
    final draft = MealDraft(
      userId: 'user-a',
      timezone: 'Asia/Kolkata',
      title: 'Dal chawal',
      items: [
        MealDraftItem(
          name: 'Dal',
          quantity: 1,
          unit: 'bowl',
          caloriesKcal: 220,
          proteinG: 12,
          carbsG: 30,
          fatG: 6,
        ),
      ],
    );

    expect(draft.caloriesKcal, 220);
    expect(() => draft.validate(), returnsNormally);
  });

  test('manual draft rejects empty title and invalid quantity', () {
    final draft = MealDraft(
      userId: 'user-a',
      timezone: 'Asia/Kolkata',
      items: [MealDraftItem(name: 'Dal', quantity: 0)],
    );

    expect(() => draft.validate(), throwsArgumentError);
    draft.title = 'Dal';
    expect(() => draft.validate(), throwsArgumentError);
  });

  test('custom food draft validates required fields and non-negative macros',
      () {
    final draft = CustomFoodDraft(
      name: 'Home curd',
      caloriesKcal: 120,
      proteinG: 6,
      carbsG: 10,
      fatG: 5,
    );

    expect(() => draft.validate(), returnsNormally);
    draft.caloriesKcal = -1;
    expect(() => draft.validate(), throwsArgumentError);
  });

  test('meal template snapshot creates duplicate draft', () {
    final template = MealTemplate(
      id: 'template-a',
      userId: 'user-a',
      clientId: 'client-template-a',
      title: 'Dal template',
      syncStatus: 'synced',
      snapshot: {
        'meal_type': 'lunch',
        'items': [
          {
            'name': 'Dal',
            'food_ref_kind': 'canonical',
            'canonical_food_id': 'canonical-dal',
            'branded_product_id': 'brand-dal',
            'custom_food_id': 'custom-dal',
            'quantity': 1,
            'unit': 'bowl',
            'calories_kcal': 220,
            'protein_g': 12,
            'carbs_g': 30,
            'fat_g': 6,
          },
        ],
      },
    );

    final draft = template.toDraft(timezone: 'Asia/Kolkata');

    expect(draft.source, MealSource.duplicate);
    expect(draft.items.single.name, 'Dal');
    expect(draft.items.single.canonicalFoodId, 'canonical-dal');
    expect(draft.items.single.brandedProductId, 'brand-dal');
    expect(draft.items.single.customFoodId, 'custom-dal');
    expect(draft.caloriesKcal, 220);
  });
}
