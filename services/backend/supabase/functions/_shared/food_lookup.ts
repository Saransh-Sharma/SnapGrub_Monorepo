import type { FoodResult } from "./multimodal.ts";
import type { serviceClient } from "./supabase.ts";

type Client = ReturnType<typeof serviceClient>;
type Row = Record<string, unknown>;

/// How many rows to pull per source before ranking. Substring matches come
/// back unordered, so ranking needs more than the page it returns.
const CANDIDATES_PER_SOURCE = 40;

/// Foods matching [query] across the catalog and the user's own foods, best
/// match first.
export async function searchFoods(
  client: Client,
  userId: string,
  query: string,
  limit: number,
): Promise<FoodResult[]> {
  const normalized = normalizeFoodName(query);
  const pattern = `%${normalized.replace(/[%_]/g, "")}%`;

  const [canonical, aliases, branded, custom, defaults, recent] = await Promise
    .all([
      client
        .from("canonical_foods")
        .select("*, food_nutrients(*), food_portions(*)")
        .eq("is_active", true)
        .ilike("normalized_name", pattern)
        .limit(CANDIDATES_PER_SOURCE),
      client
        .from("food_aliases")
        .select(
          "alias, canonical_foods(*, food_nutrients(*), food_portions(*))",
        )
        .ilike("normalized_alias", pattern)
        .limit(CANDIDATES_PER_SOURCE),
      client
        .from("branded_products")
        .select("*")
        .or(`normalized_name.ilike.${pattern},brand.ilike.${pattern}`)
        .limit(CANDIDATES_PER_SOURCE),
      client
        .from("custom_foods")
        .select("*")
        .eq("user_id", userId)
        .is("deleted_at", null)
        .ilike("name", pattern)
        .limit(CANDIDATES_PER_SOURCE),
      client
        .from("user_food_defaults")
        .select("*")
        .eq("user_id", userId)
        .ilike("food_name", pattern)
        .order("use_count", { ascending: false })
        .limit(limit),
      client
        .from("meal_items")
        .select(
          "name, quantity, unit, grams_estimated, calories_kcal, protein_g, carbs_g, fat_g, source_type, source_id, created_at",
        )
        .eq("user_id", userId)
        .ilike("name", pattern)
        .order("created_at", { ascending: false })
        .limit(limit),
    ]);

  for (const result of [canonical, aliases, branded, custom, defaults, recent]) {
    if (result.error) throw result.error;
  }

  const results = dedupe([
    ...((custom.data ?? []) as Row[]).map(customToResult),
    ...((defaults.data ?? []) as Row[]).map(defaultToResult),
    ...((canonical.data ?? []) as Row[]).map((row) =>
      canonicalFoodToResult(row)
    ),
    ...((aliases.data ?? []) as Row[])
      .filter((row) => row.canonical_foods != null)
      .map((row) => canonicalFoodToResult(row.canonical_foods as Row, 0.78)),
    ...((branded.data ?? []) as Row[]).map(brandedToResult),
    ...((recent.data ?? []) as Row[]).map(recentToResult),
  ]);
  return rankFoodResults(normalized, results).slice(0, limit);
}

/// Orders results by how closely the name matches the query: exact, then
/// prefix, then whole-word, then substring. Ties keep source order, which
/// puts the user's own foods ahead of the shared catalog.
export function rankFoodResults(query: string, results: FoodResult[]) {
  const normalized = normalizeFoodName(query);
  return results
    .map((result, index) => ({
      result,
      index,
      score: matchScore(normalized, result),
    }))
    .sort((a, b) =>
      b.score - a.score ||
      a.result.name.length - b.result.name.length ||
      a.index - b.index
    )
    .map((entry) => entry.result);
}

function matchScore(query: string, result: FoodResult) {
  const name = normalizeFoodName(result.name);
  const own = result.result_type === "custom" ||
      result.provenance.source_type === "user_food_default"
    ? 0.5
    : 0;
  if (name === query) return 4 + own;
  if (name.startsWith(`${query} `)) return 3 + own;
  if (name.split(" ").includes(query)) return 2 + own;
  if (name.startsWith(query)) return 1.5 + own;
  return 1 + own;
}

/// Lower-case, punctuation-free, single-spaced food name.
export function normalizeFoodName(value: string) {
  return value.toLowerCase().replace(/[^\p{L}\p{N}\s]/gu, " ").replace(
    /\s+/g,
    " ",
  ).trim();
}

export function canonicalFoodToResult(row: Row, confidence = 0.82): FoodResult {
  const nutrient = first(row.food_nutrients);
  const portion = first(row.food_portions);
  const grams = numberOrNull(portion?.grams) ??
    numberOrNull(row.default_grams) ?? 100;
  const perGrams = numberOrNull(nutrient?.per_grams) ?? 100;
  return {
    id: String(row.id),
    result_type: "canonical",
    name: String(row.name ?? "Food"),
    brand: null,
    serving_quantity: numberOrNull(row.default_quantity) ?? 1,
    serving_unit: stringOrNull(row.default_unit) ??
      stringOrNull(portion?.unit) ?? "serving",
    serving_grams: grams,
    calories_kcal: scaled(nutrient?.calories_kcal, grams, perGrams),
    protein_g: scaled(nutrient?.protein_g, grams, perGrams),
    carbs_g: scaled(nutrient?.carbs_g, grams, perGrams),
    fat_g: scaled(nutrient?.fat_g, grams, perGrams),
    confidence,
    provenance: {
      source_type: String(row.source_type ?? "canonical"),
      source_id: stringOrNull(row.source_id),
      license_tag: stringOrNull(row.license_tag),
      source_quality: stringOrNull(row.source_quality),
    },
  };
}

function brandedToResult(row: Row): FoodResult {
  const grams = numberOrNull(row.serving_grams);
  return {
    id: String(row.id),
    result_type: "branded",
    name: String(row.name ?? "Packaged food"),
    brand: stringOrNull(row.brand),
    serving_quantity: numberOrNull(row.serving_quantity) ?? 1,
    serving_unit: stringOrNull(row.serving_unit) ?? "serving",
    serving_grams: grams,
    calories_kcal: numberOrNull(row.calories_kcal_per_serving) ??
      scaled(row.calories_kcal_per_100g, grams, 100),
    protein_g: numberOrNull(row.protein_g_per_serving) ??
      scaled(row.protein_g_per_100g, grams, 100),
    carbs_g: numberOrNull(row.carbs_g_per_serving) ??
      scaled(row.carbs_g_per_100g, grams, 100),
    fat_g: numberOrNull(row.fat_g_per_serving) ??
      scaled(row.fat_g_per_100g, grams, 100),
    confidence: row.source_type === "open_food_facts" ? 0.72 : 0.86,
    provenance: {
      source_type: String(row.source_type ?? "branded_product"),
      source_id: stringOrNull(row.source_id),
      license_tag: stringOrNull(row.license_tag),
      source_quality: stringOrNull(row.source_quality),
    },
  };
}

function customToResult(row: Row): FoodResult {
  return {
    id: String(row.id),
    result_type: "custom",
    name: String(row.name ?? "Custom food"),
    brand: stringOrNull(row.brand),
    serving_quantity: numberOrNull(row.serving_quantity) ?? 1,
    serving_unit: stringOrNull(row.serving_unit) ?? "serving",
    serving_grams: numberOrNull(row.serving_grams),
    calories_kcal: numberOrNull(row.calories_kcal) ?? 0,
    protein_g: numberOrNull(row.protein_g) ?? 0,
    carbs_g: numberOrNull(row.carbs_g) ?? 0,
    fat_g: numberOrNull(row.fat_g) ?? 0,
    confidence: 1,
    provenance: {
      source_type: "custom_food",
      source_id: String(row.id),
      license_tag: "user-owned",
      source_quality: "user_entered",
    },
  };
}

function defaultToResult(row: Row): FoodResult {
  return {
    id: `default:${row.food_ref_kind}:${row.food_ref_id}`,
    result_type: "recent",
    name: String(row.food_name ?? "Frequent food"),
    brand: null,
    serving_quantity: numberOrNull(row.preferred_quantity) ?? 1,
    serving_unit: stringOrNull(row.preferred_unit) ?? "serving",
    serving_grams: numberOrNull(row.preferred_grams),
    calories_kcal: numberOrNull(row.calories_kcal) ?? 0,
    protein_g: numberOrNull(row.protein_g) ?? 0,
    carbs_g: numberOrNull(row.carbs_g) ?? 0,
    fat_g: numberOrNull(row.fat_g) ?? 0,
    confidence: 0.86,
    provenance: {
      source_type: "user_food_default",
      source_id: String(row.id),
      license_tag: "user-owned",
      source_quality: "learned_default",
    },
  };
}

function recentToResult(row: Row): FoodResult {
  return {
    id: `recent:${row.source_id ?? row.name}`,
    result_type: "recent",
    name: String(row.name ?? "Recent food"),
    brand: null,
    serving_quantity: numberOrNull(row.quantity) ?? 1,
    serving_unit: stringOrNull(row.unit) ?? "serving",
    serving_grams: numberOrNull(row.grams_estimated),
    calories_kcal: numberOrNull(row.calories_kcal) ?? 0,
    protein_g: numberOrNull(row.protein_g) ?? 0,
    carbs_g: numberOrNull(row.carbs_g) ?? 0,
    fat_g: numberOrNull(row.fat_g) ?? 0,
    confidence: 0.7,
    provenance: {
      source_type: stringOrNull(row.source_type) ?? "recent_meal_item",
      source_id: stringOrNull(row.source_id),
      license_tag: "user-owned",
      source_quality: "recent",
    },
  };
}

/// One entry per food. Recent items repeat the same name, and an alias can
/// point at a food the name search already returned.
function dedupe(results: FoodResult[]) {
  const seen = new Set<string>();
  return results.filter((result) => {
    const key = result.result_type === "recent"
      ? `recent:${normalizeFoodName(result.name)}`
      : `${result.result_type}:${result.id}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function first(value: unknown): Row | null {
  return Array.isArray(value) && value.length > 0 ? value[0] as Row : null;
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function stringOrNull(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function scaled(amount: unknown, grams: number | null, perGrams: number) {
  const value = numberOrNull(amount);
  if (value == null || grams == null || perGrams <= 0) return 0;
  return Number((value * grams / perGrams).toFixed(2));
}
