import { ApiError } from "./errors.ts";
import {
  callJsonModel,
  type JsonModelResult,
  type ModelDeps,
  type ModelSchema,
} from "./llm.ts";

export { estimatedCost } from "./llm.ts";

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
    warnings: Array<
      { code: string; message: string; severity: "info" | "review" | "high" }
    >;
  };
  components: MealItemWrite[];
  alternatives: Record<string, unknown>[];
  provenance: Record<string, unknown>;
};

export type ProviderResult = {
  provider: string;
  model: string;
  result: EditableMealDraft;
  raw: Record<string, unknown>;
  inputTokens: number | null;
  outputTokens: number | null;
};

type AnalysisInput = {
  imageBytes: Uint8Array;
  mimeType: string;
  locale: string;
  timezone: string;
  mealTypeHint: string | null;
  cuisineHints: string[];
  userHintText: string | null;
};

export async function analyzePhoto(
  input: AnalysisInput,
  deps: ModelDeps = {},
): Promise<ProviderResult> {
  const providerEnv = Deno.env.get("AI_PROVIDER")?.trim();
  if (!providerEnv) {
    throw new ApiError(
      "UNKNOWN",
      "AI_PROVIDER must be set explicitly",
      500,
      true,
      { provider: null },
    );
  }
  const provider = providerEnv.toLowerCase();
  if (provider === "mock") {
    return mockAnalysis(input);
  }
  if (provider === "openai") {
    return analyzeWithModel(
      input,
      "openai",
      Deno.env.get("OPENAI_FALLBACK_MODEL") ?? "gpt-4.1-mini",
      deps,
    );
  }
  if (provider === "gemini") {
    return analyzeWithModel(
      input,
      "gemini",
      Deno.env.get("GEMINI_PRIMARY_MODEL") ?? "gemini-3.1-flash-lite",
      deps,
    );
  }
  throw new ApiError(
    "UNKNOWN",
    "AI provider is not configured correctly",
    500,
    true,
    { provider },
  );
}

async function analyzeWithModel(
  input: AnalysisInput,
  provider: JsonModelResult["provider"],
  model: string,
  deps: ModelDeps,
): Promise<ProviderResult> {
  const reply = await callJsonModel({
    provider,
    model,
    purpose: "Photo analysis",
    prompt: promptFor(input),
    schema: PHOTO_SCHEMA,
    image: { bytes: input.imageBytes, mimeType: input.mimeType },
    temperature: 0.2,
    timeoutMs: 12_000,
  }, deps);
  return {
    provider,
    model,
    result: normalizeDraft(reply.json, input, { provider, model }),
    raw: reply.raw,
    inputTokens: reply.inputTokens,
    outputTokens: reply.outputTokens,
  };
}

const CONFIDENCE: ModelSchema = {
  type: "NUMBER",
  description: "0 to 1",
};

const PHOTO_SCHEMA: ModelSchema = {
  type: "OBJECT",
  properties: {
    title: { type: "STRING" },
    meal_type: {
      type: "STRING",
      enum: ["breakfast", "lunch", "dinner", "snack", "unknown"],
    },
    confidence: {
      type: "OBJECT",
      properties: {
        overall: CONFIDENCE,
        item_identification: CONFIDENCE,
        portion_estimation: CONFIDENCE,
        nutrition_source_quality: CONFIDENCE,
        warnings: {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              code: { type: "STRING" },
              message: { type: "STRING" },
              severity: { type: "STRING", enum: ["info", "review", "high"] },
            },
            required: ["code", "message", "severity"],
          },
        },
      },
      required: [
        "overall",
        "item_identification",
        "portion_estimation",
        "nutrition_source_quality",
        "warnings",
      ],
    },
    components: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          name: { type: "STRING" },
          quantity: { type: "NUMBER" },
          unit: { type: "STRING" },
          grams_estimated: { type: "NUMBER", nullable: true },
          calories_kcal: { type: "NUMBER" },
          protein_g: { type: "NUMBER" },
          carbs_g: { type: "NUMBER" },
          fat_g: { type: "NUMBER" },
          confidence: CONFIDENCE,
          notes: { type: "STRING", nullable: true },
        },
        required: [
          "name",
          "quantity",
          "unit",
          "grams_estimated",
          "calories_kcal",
          "protein_g",
          "carbs_g",
          "fat_g",
          "confidence",
        ],
      },
    },
    alternatives: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          title: { type: "STRING" },
          confidence: CONFIDENCE,
        },
        required: ["title", "confidence"],
      },
    },
  },
  required: ["title", "meal_type", "confidence", "components", "alternatives"],
};

function promptFor(input: AnalysisInput) {
  return [
    "You are SnapGrub's food photo analysis engine.",
    "Return JSON only. Do not wrap the JSON in Markdown.",
    "The JSON must contain: title, meal_type, confidence, components, alternatives.",
    "Use conservative estimates. Never imply certainty for hidden oil, sauces, dressings, or unclear portions.",
    "Split mixed plates into components. Include household units and estimated grams when possible.",
    "For Indian foods, prefer realistic serving units such as roti, katori, bowl, cup, piece, plate.",
    "Each component must include name, quantity, unit, grams_estimated, calories_kcal, protein_g, carbs_g, fat_g, confidence, notes.",
    "Name each component with its plain, singular food name so it can be matched to a nutrition database.",
    "Confidence values must be 0..1. Warnings must be objects with code, message, severity.",
    `Locale: ${input.locale}. Timezone: ${input.timezone}.`,
    `Meal type hint: ${input.mealTypeHint ?? "unknown"}.`,
    `Cuisine hints: ${input.cuisineHints.join(", ") || "none"}.`,
    `User hint: ${input.userHintText ?? "none"}.`,
  ].join("\n");
}

function normalizeDraft(
  parsed: Record<string, unknown>,
  input: AnalysisInput,
  provenance: Record<string, unknown>,
): EditableMealDraft {
  const componentsRaw = Array.isArray(parsed.components)
    ? parsed.components
    : [];
  const components = componentsRaw.map((item, index) =>
    normalizeComponent(item as Record<string, unknown>, index)
  ).filter((item) => item.name.length > 0);
  if (components.length === 0) {
    throw new ApiError(
      "INVALID_INPUT",
      "Model did not identify food components",
      422,
      false,
    );
  }

  const total = {
    calories_kcal: sum(components, "calories_kcal"),
    protein_g: sum(components, "protein_g"),
    carbs_g: sum(components, "carbs_g"),
    fat_g: sum(components, "fat_g"),
  };
  const confidenceRaw = parsed.confidence as
    | Record<string, unknown>
    | undefined;
  const warningsRaw = Array.isArray(confidenceRaw?.warnings)
    ? confidenceRaw.warnings
    : [];
  const confidence = {
    overall: clamp01(confidenceRaw?.overall, 0.6),
    item_identification: clamp01(confidenceRaw?.item_identification, 0.65),
    portion_estimation: clamp01(confidenceRaw?.portion_estimation, 0.5),
    nutrition_source_quality: clamp01(
      confidenceRaw?.nutrition_source_quality,
      0.65,
    ),
    warnings: warningsRaw.map(normalizeWarning),
  };
  if (confidence.portion_estimation < 0.6 && confidence.warnings.length === 0) {
    confidence.warnings.push({
      code: "portion_review",
      message:
        "Portion size is visually uncertain. Please review before saving.",
      severity: "review",
    });
  }

  return {
    title: stringOr(parsed.title, "Photo meal"),
    meal_type: mealTypeOr(parsed.meal_type, input.mealTypeHint),
    logged_at: new Date().toISOString(),
    timezone: input.timezone,
    total,
    confidence,
    components,
    alternatives: Array.isArray(parsed.alternatives)
      ? parsed.alternatives.map((item) => ({
        ...(item as Record<string, unknown>),
      }))
      : [],
    provenance: {
      ...provenance,
      analyzed_at: new Date().toISOString(),
      locale: input.locale,
      cuisine_hints: input.cuisineHints,
    },
  };
}

function normalizeComponent(
  item: Record<string, unknown>,
  index: number,
): MealItemWrite {
  return {
    client_id: stringOr(item.client_id, crypto.randomUUID()),
    position: numberOr(item.position, index),
    name: stringOr(item.name, ""),
    food_ref_kind: "manual",
    canonical_food_id: null,
    branded_product_id: null,
    custom_food_id: null,
    quantity: Math.max(numberOr(item.quantity, 1), 0.01),
    unit: stringOr(item.unit, "serving"),
    grams_estimated: nullableNumber(item.grams_estimated),
    calories_kcal: Math.max(numberOr(item.calories_kcal, 0), 0),
    protein_g: Math.max(numberOr(item.protein_g, 0), 0),
    carbs_g: Math.max(numberOr(item.carbs_g, 0), 0),
    fat_g: Math.max(numberOr(item.fat_g, 0), 0),
    confidence: clamp01(item.confidence, 0.6),
    source_type: "ai_photo",
    source_id: null,
    notes: typeof item.notes === "string" ? item.notes : null,
  };
}

function normalizeWarning(
  value: unknown,
): { code: string; message: string; severity: "info" | "review" | "high" } {
  if (typeof value === "string") {
    return { code: "review", message: value, severity: "review" as const };
  }
  const item = value as Record<string, unknown>;
  const severity: "info" | "review" | "high" =
    item?.severity === "high" || item?.severity === "info"
      ? item.severity
      : "review";
  return {
    code: stringOr(item?.code, "review"),
    message: stringOr(item?.message, "Please review this estimate."),
    severity,
  };
}

function mockAnalysis(input: AnalysisInput): ProviderResult {
  const result = normalizeDraft(
    {
      title: input.userHintText || "Photo meal",
      meal_type: input.mealTypeHint ?? "unknown",
      confidence: {
        overall: 0.62,
        item_identification: 0.68,
        portion_estimation: 0.5,
        nutrition_source_quality: 0.6,
        warnings: [
          {
            code: "mock_analysis",
            message: "Mock analysis is enabled. Review all nutrition values.",
            severity: "review",
          },
        ],
      },
      components: [
        {
          name: input.userHintText || "Estimated meal",
          quantity: 1,
          unit: "plate",
          grams_estimated: 350,
          calories_kcal: 520,
          protein_g: 22,
          carbs_g: 58,
          fat_g: 21,
          confidence: 0.58,
          notes: "Generated by local mock provider.",
        },
      ],
    },
    input,
    { provider: "mock", model: "mock-photo-analysis" },
  );
  return {
    provider: "mock",
    model: "mock-photo-analysis",
    result,
    raw: { mock: true },
    inputTokens: null,
    outputTokens: null,
  };
}

function nullableNumber(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function numberOr(value: unknown, fallback: number) {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function stringOr(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : fallback;
}

function clamp01(value: unknown, fallback: number) {
  return Math.min(1, Math.max(0, numberOr(value, fallback)));
}

function mealTypeOr(value: unknown, fallback: string | null) {
  const candidate = typeof value === "string" ? value : fallback;
  return candidate === "breakfast" || candidate === "lunch" ||
      candidate === "dinner" || candidate === "snack"
    ? candidate
    : "unknown";
}

function sum(
  items: MealItemWrite[],
  key: "calories_kcal" | "protein_g" | "carbs_g" | "fat_g",
) {
  return Number(items.reduce((total, item) => total + item[key], 0).toFixed(2));
}
