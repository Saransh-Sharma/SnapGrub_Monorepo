import type { UserFoodHint } from "./meal_llm.ts";
import type { MealItemWrite } from "./multimodal.ts";
import type { serviceClient } from "./supabase.ts";

/// The foods this user logs most, used as personal priors in model prompts.
/// A failed read never blocks parsing.
export async function readUserFoodHints(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  limit = 20,
): Promise<UserFoodHint[]> {
  const { data, error } = await client
    .from("user_food_defaults")
    .select(
      "food_name, preferred_quantity, preferred_unit, preferred_grams, calories_kcal, protein_g, carbs_g, fat_g",
    )
    .eq("user_id", userId)
    .order("use_count", { ascending: false })
    .limit(limit);
  if (error) {
    console.error(JSON.stringify({
      level: "error",
      scope: "user_foods.read",
      message: error.message,
    }));
    return [];
  }
  return (data ?? []).map((row) => ({
    name: String(row.food_name),
    quantity: Number(row.preferred_quantity) || 1,
    unit: String(row.preferred_unit ?? "serving"),
    grams: row.preferred_grams == null ? null : Number(row.preferred_grams),
    calories_kcal: Number(row.calories_kcal) || 0,
    protein_g: Number(row.protein_g) || 0,
    carbs_g: Number(row.carbs_g) || 0,
    fat_g: Number(row.fat_g) || 0,
  }));
}

const MAX_BASE_ITEMS = 50;

/// Reads the `base_draft` of a correction request: the meal as it stands in
/// the editor. Returns null when the request is a plain new entry.
export function baseDraftFromJson(
  value: unknown,
): { title: string | null; items: MealItemWrite[] } | null {
  if (value == null || typeof value !== "object") return null;
  const raw = value as Record<string, unknown>;
  if (!Array.isArray(raw.items)) return null;
  const items = raw.items.slice(0, MAX_BASE_ITEMS).map((entry, position) => {
    const item = (entry ?? {}) as Record<string, unknown>;
    const canonical = stringOrNull(item.canonical_food_id);
    const branded = stringOrNull(item.branded_product_id);
    const custom = stringOrNull(item.custom_food_id);
    const kind = canonical
      ? "canonical"
      : branded
      ? "branded"
      : custom
      ? "custom"
      : "manual";
    return {
      client_id: stringOrNull(item.client_id) ?? crypto.randomUUID(),
      position,
      name: stringOrNull(item.name) ?? "",
      food_ref_kind: kind,
      canonical_food_id: kind === "canonical" ? canonical : null,
      branded_product_id: kind === "branded" ? branded : null,
      custom_food_id: kind === "custom" ? custom : null,
      quantity: positive(item.quantity, 1),
      unit: stringOrNull(item.unit) ?? "serving",
      grams_estimated: numberOrNull(item.grams_estimated),
      calories_kcal: nonNegative(item.calories_kcal),
      protein_g: nonNegative(item.protein_g),
      carbs_g: nonNegative(item.carbs_g),
      fat_g: nonNegative(item.fat_g),
      confidence: numberOrNull(item.confidence),
      source_type: stringOrNull(item.source_type),
      source_id: stringOrNull(item.source_id),
      notes: stringOrNull(item.notes),
    } satisfies MealItemWrite;
  }).filter((item) => item.name.length > 0);
  return { title: stringOrNull(raw.title), items };
}

function stringOrNull(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function positive(value: unknown, fallback: number) {
  return typeof value === "number" && Number.isFinite(value) && value > 0
    ? value
    : fallback;
}

function nonNegative(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) && value >= 0
    ? value
    : 0;
}
