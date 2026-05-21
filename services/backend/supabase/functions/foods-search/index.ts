import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import type { FoodResult } from "../_shared/multimodal.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    const user = await requireUser(req);
    const body = await req.json().catch(() => {
      throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
    }) as Record<string, unknown>;
    const query = typeof body.query === "string" ? body.query.trim() : "";
    if (!query) throw new ApiError("INVALID_INPUT", "query is required", 400, false);
    const limit = Math.min(Math.max(Number(body.limit ?? 10), 1), 25);
    const client = serviceClient();
    const normalized = query.toLowerCase();
    const pattern = `%${normalized.replace(/[%_]/g, "")}%`;

    const [canonical, aliases, branded, custom, recent] = await Promise.all([
      client
        .from("canonical_foods")
        .select("*, food_nutrients(*), food_portions(*)")
        .eq("is_active", true)
        .ilike("normalized_name", pattern)
        .limit(limit),
      client
        .from("food_aliases")
        .select("alias, canonical_foods(*, food_nutrients(*), food_portions(*))")
        .ilike("normalized_alias", pattern)
        .limit(limit),
      client
        .from("branded_products")
        .select("*")
        .or(`normalized_name.ilike.${pattern},brand.ilike.${pattern}`)
        .limit(limit),
      client
        .from("custom_foods")
        .select("*")
        .eq("user_id", user.id)
        .is("deleted_at", null)
        .ilike("normalized_name", pattern)
        .limit(limit),
      client
        .from("meal_items")
        .select("name, quantity, unit, grams_estimated, calories_kcal, protein_g, carbs_g, fat_g, source_type, source_id, created_at")
        .eq("user_id", user.id)
        .ilike("name", pattern)
        .order("created_at", { ascending: false })
        .limit(limit),
    ]);

    for (const result of [canonical, aliases, branded, custom, recent]) {
      if (result.error) throw result.error;
    }

    const results = dedupe([
      ...((canonical.data ?? []) as Record<string, unknown>[]).map(canonicalFoodToResult),
      ...((aliases.data ?? []) as Record<string, unknown>[]).map((row) =>
        canonicalFoodToResult(row.canonical_foods as Record<string, unknown>, 0.78)
      ),
      ...((branded.data ?? []) as Record<string, unknown>[]).map(brandedToResult),
      ...((custom.data ?? []) as Record<string, unknown>[]).map(customToResult),
      ...((recent.data ?? []) as Record<string, unknown>[]).map(recentToResult),
    ]).slice(0, limit);

    return jsonResponse({
      results,
      server_time: new Date().toISOString(),
      request_id: requestId,
    });
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function canonicalFoodToResult(row: Record<string, unknown>, confidence = 0.82): FoodResult {
  const nutrient = first(row.food_nutrients);
  const portion = first(row.food_portions);
  const grams = numberOrNull(portion?.grams) ?? numberOrNull(row.default_grams) ?? 100;
  return {
    id: String(row.id),
    result_type: "canonical",
    name: String(row.name ?? "Food"),
    brand: null,
    serving_quantity: numberOrNull(row.default_quantity) ?? 1,
    serving_unit: stringOrNull(row.default_unit) ?? stringOrNull(portion?.unit) ?? "serving",
    serving_grams: grams,
    calories_kcal: perServing(nutrient?.calories_kcal, grams),
    protein_g: perServing(nutrient?.protein_g, grams),
    carbs_g: perServing(nutrient?.carbs_g, grams),
    fat_g: perServing(nutrient?.fat_g, grams),
    confidence,
    provenance: {
      source_type: String(row.source_type ?? "canonical"),
      source_id: stringOrNull(row.source_id),
      license_tag: stringOrNull(row.license_tag),
      source_quality: stringOrNull(row.source_quality),
    },
  };
}

function brandedToResult(row: Record<string, unknown>): FoodResult {
  const grams = numberOrNull(row.serving_grams);
  return {
    id: String(row.id),
    result_type: "branded",
    name: String(row.name ?? "Packaged food"),
    brand: stringOrNull(row.brand),
    serving_quantity: numberOrNull(row.serving_quantity) ?? 1,
    serving_unit: stringOrNull(row.serving_unit) ?? "serving",
    serving_grams: grams,
    calories_kcal: numberOrNull(row.calories_kcal_per_serving) ?? perServing(row.calories_kcal_per_100g, grams),
    protein_g: numberOrNull(row.protein_g_per_serving) ?? perServing(row.protein_g_per_100g, grams),
    carbs_g: numberOrNull(row.carbs_g_per_serving) ?? perServing(row.carbs_g_per_100g, grams),
    fat_g: numberOrNull(row.fat_g_per_serving) ?? perServing(row.fat_g_per_100g, grams),
    confidence: row.source_type === "open_food_facts" ? 0.72 : 0.86,
    provenance: {
      source_type: String(row.source_type ?? "branded_product"),
      source_id: stringOrNull(row.source_id),
      license_tag: stringOrNull(row.license_tag),
      source_quality: stringOrNull(row.source_quality),
    },
  };
}

function customToResult(row: Record<string, unknown>): FoodResult {
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

function recentToResult(row: Record<string, unknown>): FoodResult {
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

function dedupe(results: FoodResult[]) {
  const seen = new Set<string>();
  return results.filter((result) => {
    const key = `${result.result_type}:${result.id}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function first(value: unknown): Record<string, unknown> | null {
  return Array.isArray(value) && value.length > 0 ? value[0] as Record<string, unknown> : null;
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function stringOrNull(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function perServing(per100g: unknown, grams: number | null) {
  const value = numberOrNull(per100g);
  if (value == null || grams == null) return 0;
  return Number((value * grams / 100).toFixed(2));
}
