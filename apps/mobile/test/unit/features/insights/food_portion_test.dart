import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/insights/domain/food_portion.dart';

void main() {
  test('countable units pluralize with the quantity', () {
    expect(foodPortionLabel(1, 'cup'), '1 cup');
    expect(foodPortionLabel(2, 'piece'), '2 pieces');
    expect(foodPortionLabel(1.5, 'katori'), '1.5 katoris');
    expect(foodPortionLabel(1, 'servings'), '1 serving');
    expect(foodPortionLabel(0.5, 'bowl'), '0.5 bowl');
  });

  test('gram and milliliter spellings collapse to short units', () {
    expect(foodPortionLabel(150, 'grams'), '150 g');
    expect(foodPortionLabel(150, 'G'), '150 g');
    expect(foodPortionLabel(250, 'milliliters'), '250 ml');
  });

  test('raw identifiers are never printed as-is', () {
    expect(foodPortionLabel(100, 'serving_g'), '100 g');
    expect(foodPortionLabel(1, '  medium_plate '), '1 medium plate');
  });

  test('blank units show just the amount', () {
    expect(foodPortionLabel(2, '  '), '2');
  });
}
