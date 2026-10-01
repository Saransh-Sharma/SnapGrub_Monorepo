// Maps USDA FoodData Central (FDC) records to SnapGrub catalog rows.
// Works on the "Foundation Foods" and "SR Legacy" JSON downloads from
// https://fdc.nal.usda.gov/download-datasets (public domain, CC0 1.0).

export const FDC_SOURCE_TYPE = 'usda_fdc';
export const FDC_LICENSE_TAG = 'CC0-1.0';

// FDC nutrient numbers. Amounts are per 100 g of food.
const ENERGY_KCAL = ['208', '958', '957'];
const PROTEIN = '203';
const FAT = '204';
const CARBS = '205';
const FIBER = '291';

/** Foods in an FDC download, whichever dataset it is. */
export function fdcFoods(json) {
  if (Array.isArray(json)) return json;
  return json?.FoundationFoods ?? json?.SRLegacyFoods ?? json?.foods ?? [];
}

/** Same normalisation the backend applies to search and grounding keys. */
export function normalizeFoodName(value) {
  return String(value ?? '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * One catalog food with nutrients per 100 g and household portions, or null
 * when the record has no usable macros.
 */
export function mapFdcFood(food) {
  const name = String(food?.description ?? '').trim();
  if (!name || food?.fdcId == null) return null;

  const amounts = new Map();
  for (const entry of food.foodNutrients ?? []) {
    const number = String(entry?.nutrient?.number ?? '');
    const amount = Number(entry?.amount);
    if (!number || !Number.isFinite(amount) || amount < 0) continue;
    // Energy is also published in kJ under other numbers; keep kcal only.
    if (ENERGY_KCAL.includes(number) && !/kcal/i.test(entry.nutrient.unitName ?? '')) continue;
    if (!amounts.has(number)) amounts.set(number, amount);
  }
  const protein = amounts.get(PROTEIN);
  const fat = amounts.get(FAT);
  const carbs = amounts.get(CARBS);
  if (protein == null || fat == null || carbs == null) return null;
  const energyNumber = ENERGY_KCAL.find((number) => amounts.has(number));
  const calories = energyNumber
    ? amounts.get(energyNumber)
    : 4 * protein + 4 * carbs + 9 * fat;

  const portions = [];
  const seen = new Set();
  for (const portion of food.foodPortions ?? []) {
    const grams = Number(portion?.gramWeight);
    const amount = Number(portion?.amount ?? portion?.value ?? 1) || 1;
    const unit = portionUnit(portion);
    if (!unit || !Number.isFinite(grams) || grams <= 0 || seen.has(unit)) continue;
    seen.add(unit);
    portions.push({ unit, grams: round(grams / amount) });
  }

  return {
    source_id: `fdc:${food.fdcId}`,
    name,
    normalized_name: normalizeFoodName(name),
    category: food.foodCategory?.description ?? null,
    default_unit: portions[0]?.unit ?? 'g',
    default_quantity: portions[0] ? 1 : 100,
    default_grams: portions[0]?.grams ?? 100,
    source_quality: /legacy/i.test(food.dataType ?? '') ? 'sr_legacy' : 'foundation',
    nutrients: {
      per_grams: 100,
      calories_kcal: round(calories),
      protein_g: round(protein),
      carbs_g: round(carbs),
      fat_g: round(fat),
      fiber_g: amounts.has(FIBER) ? round(amounts.get(FIBER)) : null,
    },
    portions,
  };
}

// Foundation Foods name the unit in measureUnit; SR Legacy leaves it
// "undetermined" and puts "cup, chopped" in the modifier.
function portionUnit(portion) {
  const measure = String(portion?.measureUnit?.name ?? '').toLowerCase();
  const text = measure && measure !== 'undetermined'
    ? measure
    : String(portion?.modifier ?? portion?.portionDescription ?? '').toLowerCase();
  const unit = text.split(/[,(]/)[0].replace(/[^a-z\s]/g, ' ').replace(/\s+/g, ' ').trim();
  return unit.length > 0 && unit.length <= 24 ? unit : null;
}

function round(value) {
  return Number(Number(value).toFixed(2));
}
