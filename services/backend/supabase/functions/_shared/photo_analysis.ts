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

export async function analyzePhoto(input: AnalysisInput): Promise<ProviderResult> {
  const provider = (Deno.env.get("AI_PROVIDER") ?? defaultProvider()).toLowerCase();
  if (provider === "mock") {
    return mockAnalysis(input);
  }
  if (provider === "openai") return analyzeWithOpenAI(input);
  if (provider === "gemini") return analyzeWithGemini(input);
  throw new ApiError("UNKNOWN", "AI provider is not configured correctly", 500, true, { provider });
}

function defaultProvider() {
  return "mock";
}

async function analyzeWithGemini(input: AnalysisInput): Promise<ProviderResult> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new ApiError("UNKNOWN", "Gemini API key is not configured", 500, true);

  const model = Deno.env.get("GEMINI_PRIMARY_MODEL") ?? "gemini-3.1-flash-lite";
  const body = {
    contents: [
      {
        role: "user",
        parts: [
          { text: promptFor(input) },
          {
            inlineData: {
              mimeType: input.mimeType,
              data: base64(input.imageBytes),
            },
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.2,
      responseMimeType: "application/json",
    },
  };

  const response = await fetchWithTimeout(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    },
  );
  const raw = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new ApiError("UNKNOWN", "Gemini photo analysis failed", response.status, response.status >= 500, raw);
  }
  const text = String(raw?.candidates?.[0]?.content?.parts?.[0]?.text ?? "");
  const result = parseAndValidateModelJson(text, input, { provider: "gemini", model });
  return {
    provider: "gemini",
    model,
    result,
    raw,
    inputTokens: numberOrNull(raw?.usageMetadata?.promptTokenCount),
    outputTokens: numberOrNull(raw?.usageMetadata?.candidatesTokenCount),
  };
}

async function analyzeWithOpenAI(input: AnalysisInput): Promise<ProviderResult> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new ApiError("UNKNOWN", "OpenAI API key is not configured", 500, true);

  const model = Deno.env.get("OPENAI_FALLBACK_MODEL") ?? "gpt-4.1-mini";
  const body = {
    model,
    input: [
      {
        role: "user",
        content: [
          { type: "input_text", text: promptFor(input) },
          { type: "input_image", image_url: `data:${input.mimeType};base64,${base64(input.imageBytes)}` },
        ],
      },
    ],
    text: { format: { type: "json_object" } },
  };
  const response = await fetchWithTimeout("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });
  const raw = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new ApiError("UNKNOWN", "OpenAI photo analysis failed", response.status, response.status >= 500, raw);
  }
  const text = String(raw?.output_text ?? raw?.output?.[0]?.content?.[0]?.text ?? "");
  const result = parseAndValidateModelJson(text, input, { provider: "openai", model });
  return {
    provider: "openai",
    model,
    result,
    raw,
    inputTokens: numberOrNull(raw?.usage?.input_tokens),
    outputTokens: numberOrNull(raw?.usage?.output_tokens),
  };
}

async function fetchWithTimeout(url: string, init: RequestInit, timeoutMs = 12_000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new ApiError("UNKNOWN", "Photo analysis provider timed out", 504, true);
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

function promptFor(input: AnalysisInput) {
  return [
    "You are SnapGrub's food photo analysis engine.",
    "Return JSON only. Do not wrap the JSON in Markdown.",
    "The JSON must contain: title, meal_type, total, confidence, components, alternatives, provenance.",
    "Use conservative estimates. Never imply certainty for hidden oil, sauces, dressings, or unclear portions.",
    "Split mixed plates into components. Include household units and estimated grams when possible.",
    "For Indian foods, prefer realistic serving units such as roti, katori, bowl, cup, piece, plate.",
    "Each component must include client_id, position, name, food_ref_kind, quantity, unit, grams_estimated, calories_kcal, protein_g, carbs_g, fat_g, confidence, source_type, source_id, notes.",
    "Use food_ref_kind='manual', source_type='ai_photo', source_id=null.",
    "Confidence values must be 0..1. Warnings must be objects with code, message, severity.",
    `Locale: ${input.locale}. Timezone: ${input.timezone}.`,
    `Meal type hint: ${input.mealTypeHint ?? "unknown"}.`,
    `Cuisine hints: ${input.cuisineHints.join(", ") || "none"}.`,
    `User hint: ${input.userHintText ?? "none"}.`,
  ].join("\n");
}

function parseAndValidateModelJson(
  text: string,
  input: AnalysisInput,
  provenance: Record<string, unknown>,
): EditableMealDraft {
  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(stripJsonFence(text)) as Record<string, unknown>;
  } catch (_) {
    throw new ApiError("INVALID_INPUT", "Model returned invalid JSON", 502, true);
  }
  return normalizeDraft(parsed, input, provenance);
}

function normalizeDraft(
  parsed: Record<string, unknown>,
  input: AnalysisInput,
  provenance: Record<string, unknown>,
): EditableMealDraft {
  const componentsRaw = Array.isArray(parsed.components) ? parsed.components : [];
  const components = componentsRaw.map((item, index) =>
    normalizeComponent(item as Record<string, unknown>, index)
  ).filter((item) => item.name.length > 0);
  if (components.length === 0) {
    throw new ApiError("INVALID_INPUT", "Model did not identify food components", 422, false);
  }

  const total = {
    calories_kcal: sum(components, "calories_kcal"),
    protein_g: sum(components, "protein_g"),
    carbs_g: sum(components, "carbs_g"),
    fat_g: sum(components, "fat_g"),
  };
  const confidenceRaw = parsed.confidence as Record<string, unknown> | undefined;
  const warningsRaw = Array.isArray(confidenceRaw?.warnings) ? confidenceRaw.warnings : [];
  const confidence = {
    overall: clamp01(confidenceRaw?.overall, 0.6),
    item_identification: clamp01(confidenceRaw?.item_identification, 0.65),
    portion_estimation: clamp01(confidenceRaw?.portion_estimation, 0.5),
    nutrition_source_quality: clamp01(confidenceRaw?.nutrition_source_quality, 0.65),
    warnings: warningsRaw.map(normalizeWarning),
  };
  if (confidence.portion_estimation < 0.6 && confidence.warnings.length === 0) {
    confidence.warnings.push({
      code: "portion_review",
      message: "Portion size is visually uncertain. Please review before saving.",
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
      ? parsed.alternatives.map((item) => ({ ...(item as Record<string, unknown>) }))
      : [],
    provenance: {
      ...provenance,
      analyzed_at: new Date().toISOString(),
      locale: input.locale,
      cuisine_hints: input.cuisineHints,
    },
  };
}

function normalizeComponent(item: Record<string, unknown>, index: number): MealItemWrite {
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

function normalizeWarning(value: unknown): { code: string; message: string; severity: "info" | "review" | "high" } {
  if (typeof value === "string") {
    return { code: "review", message: value, severity: "review" as const };
  }
  const item = value as Record<string, unknown>;
  const severity: "info" | "review" | "high" =
    item?.severity === "high" || item?.severity === "info" ? item.severity : "review";
  return {
    code: stringOr(item?.code, "review"),
    message: stringOr(item?.message, "Please review this estimate."),
    severity,
  };
}

function mockAnalysis(input: AnalysisInput): ProviderResult {
  const result = normalizeDraft({
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
  }, input, { provider: "mock", model: "mock-photo-analysis" });
  return {
    provider: "mock",
    model: "mock-photo-analysis",
    result,
    raw: { mock: true },
    inputTokens: null,
    outputTokens: null,
  };
}

export function estimatedCost(inputTokens: number | null, outputTokens: number | null) {
  if (inputTokens == null && outputTokens == null) return null;
  const inputPrice = Number(Deno.env.get("AI_INPUT_PRICE_PER_1M") ?? "0.25");
  const outputPrice = Number(Deno.env.get("AI_OUTPUT_PRICE_PER_1M") ?? "1.50");
  return ((inputTokens ?? 0) * inputPrice + (outputTokens ?? 0) * outputPrice) / 1_000_000;
}

function stripJsonFence(value: string) {
  return value.trim().replace(/^```(?:json)?/i, "").replace(/```$/i, "").trim();
}

function base64(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function nullableNumber(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function numberOr(value: unknown, fallback: number) {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function stringOr(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : fallback;
}

function clamp01(value: unknown, fallback: number) {
  return Math.min(1, Math.max(0, numberOr(value, fallback)));
}

function mealTypeOr(value: unknown, fallback: string | null) {
  const candidate = typeof value === "string" ? value : fallback;
  return candidate === "breakfast" || candidate === "lunch" || candidate === "dinner" || candidate === "snack"
    ? candidate
    : "unknown";
}

function sum(items: MealItemWrite[], key: "calories_kcal" | "protein_g" | "carbs_g" | "fat_g") {
  return Number(items.reduce((total, item) => total + item[key], 0).toFixed(2));
}
