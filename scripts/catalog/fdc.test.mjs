import assert from 'node:assert/strict';
import test from 'node:test';

import { fdcFoods, mapFdcFood, normalizeFoodName } from './fdc.mjs';

// Shaped like an FDC record; the values are test fixtures, not reference data.
const nutrient = (number, amount, unitName = 'g') => ({ nutrient: { number, unitName }, amount });

const foundationFood = {
  fdcId: 1001,
  description: 'Rice, white, long-grain, cooked',
  dataType: 'Foundation',
  foodCategory: { description: 'Cereal Grains and Pasta' },
  foodNutrients: [
    nutrient('268', 544, 'kJ'),
    nutrient('208', 130, 'kcal'),
    nutrient('203', 2.7),
    nutrient('204', 0.3),
    nutrient('205', 28.2),
    nutrient('291', 0.4),
  ],
  foodPortions: [
    { gramWeight: 158, amount: 1, measureUnit: { name: 'cup' }, modifier: 'cooked' },
    { gramWeight: 316, amount: 2, measureUnit: { name: 'cup' } },
  ],
};

test('maps macros per 100 g and ignores kJ energy', () => {
  const mapped = mapFdcFood(foundationFood);
  assert.equal(mapped.source_id, 'fdc:1001');
  assert.equal(mapped.normalized_name, 'rice white long grain cooked');
  assert.deepEqual(mapped.nutrients, {
    per_grams: 100,
    calories_kcal: 130,
    protein_g: 2.7,
    carbs_g: 28.2,
    fat_g: 0.3,
    fiber_g: 0.4,
  });
  assert.equal(mapped.source_quality, 'foundation');
});

test('keeps one portion per unit, as grams for one of that unit', () => {
  const mapped = mapFdcFood(foundationFood);
  assert.deepEqual(mapped.portions, [{ unit: 'cup', grams: 158 }]);
  assert.equal(mapped.default_unit, 'cup');
  assert.equal(mapped.default_grams, 158);
});

test('reads SR Legacy portions from the modifier', () => {
  const mapped = mapFdcFood({
    ...foundationFood,
    dataType: 'SR Legacy',
    foodPortions: [
      { gramWeight: 50, amount: 1, measureUnit: { name: 'undetermined' }, modifier: 'large' },
      { gramWeight: 243, amount: 1, measureUnit: { name: 'undetermined' }, modifier: 'cup, chopped' },
    ],
  });
  assert.deepEqual(mapped.portions, [
    { unit: 'large', grams: 50 },
    { unit: 'cup', grams: 243 },
  ]);
  assert.equal(mapped.source_quality, 'sr_legacy');
});

test('derives energy from macros when no kcal value is published', () => {
  const mapped = mapFdcFood({
    ...foundationFood,
    foodNutrients: [nutrient('203', 10), nutrient('204', 5), nutrient('205', 20)],
    foodPortions: [],
  });
  assert.equal(mapped.nutrients.calories_kcal, 165);
  assert.equal(mapped.nutrients.fiber_g, null);
  assert.equal(mapped.default_unit, 'g');
  assert.equal(mapped.default_quantity, 100);
});

test('skips records without macros', () => {
  assert.equal(mapFdcFood({ fdcId: 1, description: 'Salt', foodNutrients: [] }), null);
  assert.equal(mapFdcFood({ description: 'No id' }), null);
});

test('reads either dataset wrapper', () => {
  assert.equal(fdcFoods({ FoundationFoods: [foundationFood] }).length, 1);
  assert.equal(fdcFoods({ SRLegacyFoods: [foundationFood] }).length, 1);
  assert.equal(fdcFoods([foundationFood]).length, 1);
  assert.equal(normalizeFoodName('Dal, Tadka (home-style)'), 'dal tadka home style');
});
