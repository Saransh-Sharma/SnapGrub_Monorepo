import { ApiError } from "./errors.ts";

export type MealItemWrite = {
  client_id: string;
  position: number;
  name: string;
  food_ref_kind: "canonical" | "branded" | "custom" | "manual";
  canonical_food_id: string | null;
  branded_product_id: string | null;
  custom_food_id: string | null;
  quantity: number;
  unit: string;
  grams_estimated: number | null;
  calories_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  confidence: number | null;
  source_type: string | null;
  source_id: string | null;
  notes: string | null;
};

export type EditableMealDraft = {
  title: string;
  meal_type: "breakfast" | "lunch" | "dinner" | "snack" | "unknown";
  logged_at: string;
  timezone: string;
  total: {
    calories_kcal: number;
    protein_g: number;
    carbs_g: number;
    fat_g: number;
  };
  confidence: {
    overall: number;
    item_identification: number;
    portion_estimation: number;
    nutrition_source_quality: number;
    warnings: Array<{ code: string; message: string; severity: "info" | "review" | "high" }>;
  };
  components: MealItemWrite[];
  alternatives: Record<string, unknown>[];
  provenance: Record<string, unknown>;
};

export type FoodResult = {
  id: string;
  result_type: "canonical" | "branded" | "custom" | "recent";
  name: string;
  brand: string | null;
  serving_quantity: number | null;
  serving_unit: string | null;
  serving_grams: number | null;
  calories_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  confidence: number;
  provenance: {
    source_type: string;
    source_id: string | null;
    license_tag: string | null;
    source_quality: string | null;
    raw?: Record<string, unknown>;
  };
};

const localFoods: Record<string, { name: string; quantity: number; unit: string; grams: number; calories: number; protein: number; carbs: number; fat: number }> = {
  roti: { name: "Roti", quantity: 1, unit: "roti", grams: 40, calories: 119, protein: 3.9, carbs: 18.4, fat: 3.0 },
  chapati: { name: "Chapati", quantity: 1, unit: "piece", grams: 40, calories: 119, protein: 3.9, carbs: 18.4, fat: 3.0 },
  phulka: { name: "Phulka", quantity: 1, unit: "piece", grams: 35, calories: 91, protein: 3.0, carbs: 14.7, fat: 1.9 },
  dal: { name: "Dal tadka", quantity: 1, unit: "katori", grams: 180, calories: 212, protein: 10.8, carbs: 28.8, fat: 6.1 },
  rajma: { name: "Rajma curry", quantity: 1, unit: "katori", grams: 180, calories: 225, protein: 11.7, carbs: 36.0, fat: 4.5 },
  chawal: { name: "Steamed rice", quantity: 1, unit: "bowl", grams: 150, calories: 195, protein: 4.1, carbs: 42.0, fat: 0.5 },
  rice: { name: "Steamed rice", quantity: 1, unit: "bowl", grams: 150, calories: 195, protein: 4.1, carbs: 42.0, fat: 0.5 },
  paneer: { name: "Paneer tikka", quantity: 1, unit: "serving", grams: 120, calories: 300, protein: 16.8, carbs: 9.6, fat: 21.6 },
  idli: { name: "Idli", quantity: 1, unit: "piece", grams: 40, calories: 58, protein: 1.7, carbs: 11.6, fat: 0.3 },
  sambar: { name: "Sambar", quantity: 1, unit: "katori", grams: 180, calories: 126, protein: 6.3, carbs: 18.0, fat: 3.6 },
  poha: { name: "Poha", quantity: 1, unit: "bowl", grams: 180, calories: 324, protein: 6.3, carbs: 57.6, fat: 9.0 },
  curd: { name: "Curd", quantity: 1, unit: "katori", grams: 120, calories: 73, protein: 4.2, carbs: 5.6, fat: 4.0 },
  biryani: { name: "Chicken biryani", quantity: 1, unit: "plate", grams: 300, calories: 510, protein: 24.0, carbs: 60.0, fat: 18.0 },
};

export function buildDraftFromText(input: {
  text: string;
  source: "text" | "voice";
  timezone: string;
  mealTypeHint: string | null;
  locale: string;
  cuisineHints: string[];
  transcriptConfidence?: number | null;
}): EditableMealDraft {
  const components = parseMealPhrase(input.text, input.source);
  if (components.length === 0) {
    throw new ApiError("INVALID_INPUT", "Could not identify any meal items", 422, false);
  }
  const warnings = [{
    code: "review_estimate",
    message: input.source === "voice"
      ? "Voice entry was converted from transcript. Please review quantities before saving."
      : "Text entry was parsed as an estimate. Please review quantities before saving.",
    severity: "review" as const,
  }];
  if (input.transcriptConfidence != null && input.transcriptConfidence < 0.75) {
    warnings.push({
      code: "low_transcript_confidence",
      message: "Transcript confidence was low. Edit the meal if any words were misheard.",
      severity: "review",
    });
  }
  return draftFromComponents({
    title: titleFromComponents(components),
    mealType: mealTypeOr(input.mealTypeHint),
    timezone: input.timezone,
    components,
    source: input.source,
    confidenceOverall: input.source === "voice" ? 0.68 : 0.72,
    warnings,
    provenance: {
      source_type: input.source,
      parser: "phase5_rule_parser",
      input_text: input.text,
      locale: input.locale,
      cuisine_hints: input.cuisineHints,
    },
  });
}

export function buildDraftFromLabel(input: {
  ocrText: string;
  productNameHint: string | null;
  barcode: string | null;
  timezone: string;
  locale: string;
  rawImageOptIn: boolean;
}): EditableMealDraft {
  const parsed = parseLabel(input.ocrText);
  const name = input.productNameHint ?? parsed.name ?? "Packaged food";
  const component: MealItemWrite = {
    client_id: crypto.randomUUID(),
    position: 0,
    name,
    food_ref_kind: "manual",
    canonical_food_id: null,
    branded_product_id: null,
    custom_food_id: null,
    quantity: parsed.servingQuantity ?? 1,
    unit: parsed.servingUnit ?? "serving",
    grams_estimated: parsed.grams,
    calories_kcal: parsed.calories ?? 0,
    protein_g: parsed.protein ?? 0,
    carbs_g: parsed.carbs ?? 0,
    fat_g: parsed.fat ?? 0,
    confidence: parsed.complete ? 0.74 : 0.48,
    source_type: "label_ocr",
    source_id: input.barcode,
    notes: parsed.complete ? null : "Nutrition label was incomplete. Review all fields before saving.",
  };
  return draftFromComponents({
    title: name,
    mealType: "unknown",
    timezone: input.timezone,
    components: [component],
    source: "label_ocr",
    confidenceOverall: parsed.complete ? 0.74 : 0.5,
    warnings: parsed.complete
      ? []
      : [{ code: "incomplete_label", message: "Some nutrition fields were not found in the label text.", severity: "review" }],
    provenance: {
      source_type: "label_ocr",
      parser: "phase5_label_parser",
      barcode: input.barcode,
      locale: input.locale,
      raw_image_opt_in: input.rawImageOptIn,
    },
  });
}

export function draftFromFoodResult(food: FoodResult, timezone: string, source: "barcode" | "text" | "voice" = "barcode"): EditableMealDraft {
  const component: MealItemWrite = {
    client_id: crypto.randomUUID(),
    position: 0,
    name: food.name,
    food_ref_kind: food.result_type === "canonical" ? "canonical" : food.result_type === "branded" ? "branded" : "manual",
    canonical_food_id: food.result_type === "canonical" ? food.id : null,
    branded_product_id: food.result_type === "branded" ? food.id : null,
    custom_food_id: food.result_type === "custom" ? food.id : null,
    quantity: food.serving_quantity ?? 1,
    unit: food.serving_unit ?? "serving",
    grams_estimated: food.serving_grams,
    calories_kcal: food.calories_kcal,
    protein_g: food.protein_g,
    carbs_g: food.carbs_g,
    fat_g: food.fat_g,
    confidence: food.confidence,
    source_type: food.provenance.source_type,
    source_id: food.provenance.source_id,
    notes: food.brand ? food.brand : null,
  };
  return draftFromComponents({
    title: food.brand ? `${food.brand} ${food.name}` : food.name,
    mealType: "unknown",
    timezone,
    components: [component],
    source,
    confidenceOverall: food.confidence,
    warnings: [],
    provenance: food.provenance,
  });
}

export function brandedProductToFoodResult(product: Record<string, unknown>): FoodResult {
  const servingQuantity = numberOrNull(product.serving_quantity) ?? 1;
  const servingUnit = stringOrNull(product.serving_unit) ?? "serving";
  const servingGrams = numberOrNull(product.serving_grams);
  return {
    id: String(product.id),
    result_type: "branded",
    name: String(product.name ?? "Packaged food"),
    brand: stringOrNull(product.brand),
    serving_quantity: servingQuantity,
    serving_unit: servingUnit,
    serving_grams: servingGrams,
    calories_kcal: numberOrNull(product.calories_kcal_per_serving) ?? perServing(product.calories_kcal_per_100g, servingGrams),
    protein_g: numberOrNull(product.protein_g_per_serving) ?? perServing(product.protein_g_per_100g, servingGrams),
    carbs_g: numberOrNull(product.carbs_g_per_serving) ?? perServing(product.carbs_g_per_100g, servingGrams),
    fat_g: numberOrNull(product.fat_g_per_serving) ?? perServing(product.fat_g_per_100g, servingGrams),
    confidence: product.source_type === "open_food_facts" ? 0.72 : 0.86,
    provenance: {
      source_type: String(product.source_type ?? "branded_product"),
      source_id: stringOrNull(product.source_id),
      license_tag: stringOrNull(product.license_tag),
      source_quality: stringOrNull(product.source_quality),
    },
  };
}

function parseMealPhrase(text: string, source: "text" | "voice"): MealItemWrite[] {
  const normalized = normalize(text);
  const chunks = normalized
    .replace(/\bwith\b/g, ",")
    .replace(/\band\b/g, ",")
    .split(",")
    .map((part) => part.trim())
    .filter(Boolean);
  const items: MealItemWrite[] = [];
  for (const chunk of chunks.length ? chunks : [normalized]) {
    const keysInChunk = Object.keys(localFoods).filter((candidate) => chunk.includes(candidate));
    if (keysInChunk.length > 1 && !/(\d+(?:\.\d+)?)\s*(g|gram|grams)\b/.test(chunk)) {
      for (const key of keysInChunk) {
        const parsed = itemFromFood(localFoods[key], key, 1, null, null, source, items.length);
        if (parsed) items.push(parsed);
      }
      continue;
    }
    const parsed = parseChunk(chunk, source, items.length);
    if (parsed) items.push(parsed);
  }
  return items;
}

function parseChunk(chunk: string, source: "text" | "voice", position: number): MealItemWrite | null {
  const tokens = chunk.split(/\s+/).filter(Boolean);
  let quantity = 1;
  let grams: number | null = null;
  let unit: string | null = null;
  const numeric = tokens.find((token) => /^\d+(\.\d+)?$/.test(token));
  if (numeric) quantity = Number(numeric);
  const gramMatch = chunk.match(/(\d+(?:\.\d+)?)\s*(g|gram|grams)\b/);
  if (gramMatch) {
    grams = Number(gramMatch[1]);
    quantity = grams;
    unit = "g";
  }
  const unitMatch = chunk.match(/\b(katori|bowl|cup|piece|pieces|plate|serving|roti|rotis)\b/);
  if (unitMatch && unit == null) unit = unitMatch[1].replace(/s$/, "");
  const key = Object.keys(localFoods).find((candidate) => chunk.includes(candidate));
  if (!key) return null;
  const food = localFoods[key];
  return itemFromFood(food, key, quantity, grams, unit, source, position);
}

function itemFromFood(
  food: { name: string; quantity: number; unit: string; grams: number; calories: number; protein: number; carbs: number; fat: number },
  key: string,
  quantity: number,
  grams: number | null,
  unit: string | null,
  source: "text" | "voice",
  position: number,
): MealItemWrite {
  const multiplier = grams != null ? grams / food.grams : quantity / food.quantity;
  return {
    client_id: crypto.randomUUID(),
    position,
    name: food.name,
    food_ref_kind: "manual",
    canonical_food_id: null,
    branded_product_id: null,
    custom_food_id: null,
    quantity,
    unit: unit ?? food.unit,
    grams_estimated: grams ?? round(food.grams * multiplier),
    calories_kcal: round(food.calories * multiplier),
    protein_g: round(food.protein * multiplier),
    carbs_g: round(food.carbs * multiplier),
    fat_g: round(food.fat * multiplier),
    confidence: source === "voice" ? 0.68 : 0.72,
    source_type: source,
    source_id: key,
    notes: "Parsed by SnapGrub starter parser.",
  };
}

function parseLabel(text: string) {
  const normalized = text.replace(/\s+/g, " ");
  const calories = numberAfter(normalized, /(?:calories|energy)\D+(\d+(?:\.\d+)?)/i);
  const protein = numberAfter(normalized, /protein\D+(\d+(?:\.\d+)?)/i);
  const carbs = numberAfter(normalized, /(?:carbohydrate|carbs)\D+(\d+(?:\.\d+)?)/i);
  const fat = numberAfter(normalized, /(?:total\s+fat|fat)\D+(\d+(?:\.\d+)?)/i);
  const serving = normalized.match(/serving\s+size\D+(\d+(?:\.\d+)?)\s*(g|ml|cup|serving|pack)/i);
  const name = normalized.match(/(?:product\s+name|name)\D+([A-Za-z][A-Za-z0-9 &'-]{2,40})/i)?.[1]?.trim();
  return {
    name,
    servingQuantity: serving ? Number(serving[1]) : 1,
    servingUnit: serving?.[2]?.toLowerCase() ?? "serving",
    grams: serving && serving[2].toLowerCase() === "g" ? Number(serving[1]) : null,
    calories,
    protein,
    carbs,
    fat,
    complete: calories != null && protein != null && carbs != null && fat != null,
  };
}

function draftFromComponents(input: {
  title: string;
  mealType: EditableMealDraft["meal_type"];
  timezone: string;
  components: MealItemWrite[];
  source: string;
  confidenceOverall: number;
  warnings: EditableMealDraft["confidence"]["warnings"];
  provenance: Record<string, unknown>;
}): EditableMealDraft {
  return {
    title: input.title,
    meal_type: input.mealType,
    logged_at: new Date().toISOString(),
    timezone: input.timezone,
    total: {
      calories_kcal: sum(input.components, "calories_kcal"),
      protein_g: sum(input.components, "protein_g"),
      carbs_g: sum(input.components, "carbs_g"),
      fat_g: sum(input.components, "fat_g"),
    },
    confidence: {
      overall: clamp01(input.confidenceOverall),
      item_identification: clamp01(input.confidenceOverall),
      portion_estimation: input.source === "barcode" ? 0.86 : 0.62,
      nutrition_source_quality: input.source === "barcode" ? 0.82 : 0.58,
      warnings: input.warnings,
    },
    components: input.components,
    alternatives: [],
    provenance: {
      ...input.provenance,
      analyzed_at: new Date().toISOString(),
    },
  };
}

function titleFromComponents(components: MealItemWrite[]) {
  return components.slice(0, 3).map((item) => item.name).join(", ");
}

function mealTypeOr(value: string | null): EditableMealDraft["meal_type"] {
  return value === "breakfast" || value === "lunch" || value === "dinner" || value === "snack" ? value : "unknown";
}

function normalize(value: string) {
  return value.toLowerCase().replace(/[^\p{L}\p{N}\s,.]/gu, " ").replace(/\s+/g, " ").trim();
}

function sum(items: MealItemWrite[], key: "calories_kcal" | "protein_g" | "carbs_g" | "fat_g") {
  return round(items.reduce((total, item) => total + item[key], 0));
}

function round(value: number) {
  return Number(value.toFixed(2));
}

function clamp01(value: number) {
  return Math.min(1, Math.max(0, value));
}

function numberAfter(value: string, pattern: RegExp) {
  const match = value.match(pattern);
  return match ? Number(match[1]) : null;
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function stringOrNull(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function perServing(per100g: unknown, servingGrams: number | null) {
  const value = numberOrNull(per100g);
  if (value == null || servingGrams == null) return 0;
  return round(value * servingGrams / 100);
}
