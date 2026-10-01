import { normalizeFoodName } from "./food_lookup.ts";
import { overallConfidence, totalsFor } from "./meal_llm.ts";
import type { EditableMealDraft, MealItemWrite } from "./multimodal.ts";
import type { serviceClient } from "./supabase.ts";

type Client = ReturnType<typeof serviceClient>;
type Row = Record<string, unknown>;

/// A catalog or user food the model's item can take its nutrition from.
export type GroundingMatch =
  | {
    kind: "canonical";
    id: string;
    per100g: Macros;
    /// Grams for one of a household unit, keyed by lower-case unit.
    portions: Record<string, number>;
    sourceType: string;
    sourceId: string | null;
  }
  | {
    kind: "custom";
    id: string;
    servingQuantity: number;
    servingUnit: string | null;
    servingGrams: number | null;
    perServing: Macros;
  };

type Macros = {
  calories_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
};

/// Nutrition-source score for numbers taken from the catalog or the user's
/// own foods.
const GROUNDED_SOURCE_QUALITY = 0.9;

/// A catalog match whose energy is this far from the model's estimate for
/// the same amount is probably a different food, so it is not applied.
const MAX_DISAGREEMENT = 2.5;

export type GroundingOptions = {
  /// Text sources trust the catalog's household portion ("1 katori") over
  /// the model's gram guess; a photo keeps the amount the model saw.
  preferCatalogPortions: boolean;
  /// client_ids eligible for grounding. Null or absent means every item
  /// without a food reference. Items kept from a saved meal or an editor
  /// draft are left out so the user's numbers are never overwritten.
  onlyItems?: string[] | null;
};

/// Replaces estimated nutrition with catalog values wherever an item's name
/// matches a food exactly. Items without a match keep the estimate.
export async function groundDraft(
  client: Client,
  userId: string,
  draft: EditableMealDraft,
  options: GroundingOptions,
): Promise<EditableMealDraft> {
  const eligible = eligibility(options);
  const candidates = draft.components.filter(eligible);
  if (candidates.length === 0) return draft;
  const keys = [
    ...new Set(candidates.flatMap((item) => lookupKeys(item.name))),
  ];
  const [canonical, aliases, custom] = await Promise.all([
    client
      .from("canonical_foods")
      .select("*, food_nutrients(*), food_portions(*)")
      .eq("is_active", true)
      .in("normalized_name", keys),
    client
      .from("food_aliases")
      .select(
        "normalized_alias, canonical_foods(*, food_nutrients(*), food_portions(*))",
      )
      .in("normalized_alias", keys),
    client
      .from("custom_foods")
      .select("*")
      .eq("user_id", userId)
      .is("deleted_at", null)
      .limit(500),
  ]);
  for (const result of [canonical, aliases, custom]) {
    if (result.error) throw result.error;
  }

  const matches = new Map<string, GroundingMatch>();
  const put = (key: string, match: GroundingMatch | null) => {
    if (match && !matches.has(key)) matches.set(key, match);
  };
  // First writer wins: the user's own foods, then catalog names, then aliases.
  for (const row of (custom.data ?? []) as Row[]) {
    put(normalizeFoodName(String(row.name ?? "")), customMatch(row));
  }
  for (const row of (canonical.data ?? []) as Row[]) {
    put(String(row.normalized_name), canonicalMatch(row));
  }
  for (const row of (aliases.data ?? []) as Row[]) {
    if (row.canonical_foods == null) continue;
    put(String(row.normalized_alias), canonicalMatch(row.canonical_foods as Row));
  }
  return applyGrounding(draft, matches, options);
}

/// [groundDraft] that keeps the ungrounded draft if the catalog lookup fails,
/// so a catalog problem never costs the user their analysis.
export async function groundDraftSafely(
  client: Client,
  userId: string,
  draft: EditableMealDraft,
  options: GroundingOptions,
): Promise<EditableMealDraft> {
  try {
    return await groundDraft(client, userId, draft, options);
  } catch (error) {
    console.error(JSON.stringify({
      level: "error",
      scope: "catalog_grounding",
      message: error instanceof Error ? error.message : String(error),
    }));
    return draft;
  }
}

/// Pure half of [groundDraft]: applies already-fetched matches to the draft.
export function applyGrounding(
  draft: EditableMealDraft,
  matches: Map<string, GroundingMatch>,
  options: GroundingOptions,
): EditableMealDraft {
  const eligible = eligibility(options);
  let grounded = 0;
  let estimated = 0;
  const components = draft.components.map((item) => {
    if (!eligible(item)) return item;
    const match = lookupKeys(item.name).map((key) => matches.get(key)).find(
      Boolean,
    );
    const next = match ? groundItem(item, match, options) : null;
    if (next) grounded += 1;
    else estimated += 1;
    return next ?? item;
  });
  if (grounded === 0) return draft;

  const total = totalsFor(components);
  const groundedKcal = components.filter((item) =>
    item.food_ref_kind !== "manual"
  ).reduce((sum, item) => sum + item.calories_kcal, 0);
  const share = total.calories_kcal > 0
    ? Math.min(1, groundedKcal / total.calories_kcal)
    : 0;
  const confidence = {
    ...draft.confidence,
    nutrition_source_quality: round(
      Math.max(
        draft.confidence.nutrition_source_quality,
        share * GROUNDED_SOURCE_QUALITY +
          (1 - share) * draft.confidence.nutrition_source_quality,
      ),
    ),
  };
  confidence.overall = Math.max(
    draft.confidence.overall,
    overallConfidence(confidence),
  );
  return {
    ...draft,
    total,
    confidence,
    components,
    provenance: {
      ...draft.provenance,
      grounding: { matched: grounded, estimated },
    },
  };
}

/// Items that may be grounded: no food reference yet, and produced by this
/// request rather than carried over from something the user already has.
function eligibility(options: GroundingOptions) {
  const only = options.onlyItems == null ? null : new Set(options.onlyItems);
  return (item: MealItemWrite) =>
    item.food_ref_kind === "manual" &&
    (only == null || only.has(item.client_id));
}

function groundItem(
  item: MealItemWrite,
  match: GroundingMatch,
  options: GroundingOptions,
): MealItemWrite | null {
  if (match.kind === "custom") {
    const factor = customFactor(item, match);
    if (factor == null) return null;
    const macros = scale(match.perServing, factor);
    if (disagrees(item, macros)) return null;
    return {
      ...item,
      ...macros,
      food_ref_kind: "custom",
      canonical_food_id: null,
      branded_product_id: null,
      custom_food_id: match.id,
      grams_estimated: match.servingGrams != null
        ? round(match.servingGrams * factor)
        : item.grams_estimated,
      source_type: "custom_food",
      source_id: match.id,
    };
  }
  const portionGrams = match.portions[item.unit.trim().toLowerCase()];
  const fromPortion = portionGrams != null
    ? round(portionGrams * item.quantity)
    : null;
  const grams = options.preferCatalogPortions
    ? fromPortion ?? item.grams_estimated
    : item.grams_estimated ?? fromPortion;
  if (grams == null || grams <= 0) return null;
  const macros = scale(match.per100g, grams / 100);
  if (disagrees(item, macros, grams)) return null;
  return {
    ...item,
    ...macros,
    food_ref_kind: "canonical",
    canonical_food_id: match.id,
    branded_product_id: null,
    custom_food_id: null,
    grams_estimated: grams,
    source_type: match.sourceType,
    source_id: match.sourceId,
  };
}

function customFactor(
  item: MealItemWrite,
  match: Extract<GroundingMatch, { kind: "custom" }>,
) {
  const sameUnit = match.servingUnit != null &&
    match.servingUnit.trim().toLowerCase() === item.unit.trim().toLowerCase();
  if (sameUnit && match.servingQuantity > 0) {
    return item.quantity / match.servingQuantity;
  }
  if (
    item.grams_estimated != null && match.servingGrams != null &&
    match.servingGrams > 0
  ) {
    return item.grams_estimated / match.servingGrams;
  }
  return null;
}

/// True when catalog energy and the model's estimate are too far apart to be
/// the same food. The estimate is compared at the catalog's gram amount.
function disagrees(item: MealItemWrite, macros: Macros, grams?: number) {
  const estimate = grams != null && item.grams_estimated != null &&
      item.grams_estimated > 0
    ? item.calories_kcal * grams / item.grams_estimated
    : item.calories_kcal;
  if (estimate < 20 || macros.calories_kcal < 20) return false;
  const ratio = macros.calories_kcal / estimate;
  return ratio > MAX_DISAGREEMENT || ratio < 1 / MAX_DISAGREEMENT;
}

function canonicalMatch(row: Row): GroundingMatch | null {
  const nutrient = Array.isArray(row.food_nutrients)
    ? row.food_nutrients[0] as Row | undefined
    : undefined;
  if (!nutrient) return null;
  const perGrams = numberOr(nutrient.per_grams, 100);
  if (perGrams <= 0) return null;
  const to100g = 100 / perGrams;
  const portions: Record<string, number> = {};
  const defaultUnit = stringOrNull(row.default_unit);
  const defaultGrams = numberOr(row.default_grams, 0);
  const defaultQuantity = numberOr(row.default_quantity, 1);
  if (defaultUnit && defaultGrams > 0 && defaultQuantity > 0) {
    portions[defaultUnit.toLowerCase()] = defaultGrams / defaultQuantity;
  }
  for (const portion of (row.food_portions ?? []) as Row[]) {
    const unit = stringOrNull(portion.unit);
    const grams = numberOr(portion.grams, 0);
    if (unit && grams > 0) portions[unit.toLowerCase()] = grams;
  }
  portions.g = 1;
  return {
    kind: "canonical",
    id: String(row.id),
    per100g: {
      calories_kcal: numberOr(nutrient.calories_kcal, 0) * to100g,
      protein_g: numberOr(nutrient.protein_g, 0) * to100g,
      carbs_g: numberOr(nutrient.carbs_g, 0) * to100g,
      fat_g: numberOr(nutrient.fat_g, 0) * to100g,
    },
    portions,
    sourceType: String(row.source_type ?? "canonical"),
    sourceId: stringOrNull(row.source_id),
  };
}

function customMatch(row: Row): GroundingMatch | null {
  if (!stringOrNull(row.name)) return null;
  return {
    kind: "custom",
    id: String(row.id),
    servingQuantity: numberOr(row.serving_quantity, 1),
    servingUnit: stringOrNull(row.serving_unit),
    servingGrams: row.serving_grams == null
      ? null
      : numberOr(row.serving_grams, 0) || null,
    perServing: {
      calories_kcal: numberOr(row.calories_kcal, 0),
      protein_g: numberOr(row.protein_g, 0),
      carbs_g: numberOr(row.carbs_g, 0),
      fat_g: numberOr(row.fat_g, 0),
    },
  };
}

/// The normalized name plus its singular forms ("rotis" also tries "roti").
export function lookupKeys(name: string) {
  const normalized = normalizeFoodName(name);
  const keys = [normalized];
  if (normalized.endsWith("es")) keys.push(normalized.slice(0, -2));
  if (normalized.endsWith("s")) keys.push(normalized.slice(0, -1));
  return keys.filter((key) => key.length > 1);
}

function scale(macros: Macros, factor: number): Macros {
  return {
    calories_kcal: round(macros.calories_kcal * factor),
    protein_g: round(macros.protein_g * factor),
    carbs_g: round(macros.carbs_g * factor),
    fat_g: round(macros.fat_g * factor),
  };
}

function numberOr(value: unknown, fallback: number) {
  const parsed = Number(value);
  return value == null || !Number.isFinite(parsed) ? fallback : parsed;
}

function stringOrNull(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function round(value: number) {
  return Number(value.toFixed(2));
}
