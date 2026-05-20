import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

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
}
