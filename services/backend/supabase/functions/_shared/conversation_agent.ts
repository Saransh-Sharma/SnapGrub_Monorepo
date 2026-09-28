import { ApiError } from "./errors.ts";
import {
  buildDraftFromText,
  type EditableMealDraft,
  type MealItemWrite,
} from "./multimodal.ts";

export type ConversationAgentResult = {
  assistantText: string;
  draft: EditableMealDraft;
  operation: "create" | "update" | "delete";
  targetMealId: string | null;
  expectedRevision: number | null;
  provider: string;
  model: string;
  inputTokens: number | null;
  outputTokens: number | null;
};

export async function createConversationProposal(input: {
  message: string;
  timezone: string;
  locale: string;
  cuisineHints: string[];
  mealTypeHint: string | null;
  dayMeals: unknown[];
  recentMeals: unknown[];
  calorieGoal: number | null;
}): Promise<ConversationAgentResult> {
  const operation = operationFor(input.message);
  const target = operation === "create"
    ? null
    : targetMeal(input.message, input.dayMeals);
  if (operation !== "create" && !target) {
    throw new ApiError(
      "NOT_FOUND",
      "I could not find a meal on this day to change",
      404,
      false,
    );
  }
  if (operation === "delete") {
    const draft = draftFromExisting(target!, input.timezone);
    return {
      assistantText:
        `I found ${draft.title}. Confirm below if you want to remove it.`,
      draft,
      operation,
      targetMealId: String(target!.id),
      expectedRevision: numberOrNull(target!.revision),
      provider: "nutrition-tools",
      model: "ledger-tools-v1",
      inputTokens: null,
      outputTokens: null,
    };
  }
  try {
    const draft = buildDraftFromText({
      text: input.message,
      source: "text",
      timezone: input.timezone,
      locale: input.locale,
      cuisineHints: input.cuisineHints,
      mealTypeHint: input.mealTypeHint,
    });
    return {
      assistantText: friendlySummary(draft),
      draft,
      operation,
      targetMealId: target == null ? null : String(target.id),
      expectedRevision: target == null ? null : numberOrNull(target.revision),
      provider: "nutrition-tools",
      model: "catalog-rule-v2",
      inputTokens: null,
      outputTokens: null,
    };
  } catch (error) {
    const key = Deno.env.get("GEMINI_API_KEY");
    if (!key) throw error;
    return await createWithGemini(input, key, operation, target);
  }
}

async function createWithGemini(
  input: Parameters<typeof createConversationProposal>[0],
  apiKey: string,
  operation: "create" | "update" | "delete",
  target: Record<string, unknown> | null,
): Promise<ConversationAgentResult> {
  const model = Deno.env.get("AGENT_MODEL") ?? "gemini-3.1-flash-lite";
  const prompt = [
    "You are SnapGrub, a warm and concise food logging assistant.",
    "Return JSON only with assistant_text and draft.",
    "draft must contain title, meal_type, total, confidence, components, alternatives, provenance.",
    "Every component needs name, quantity, unit, grams_estimated, calories_kcal, protein_g, carbs_g, fat_g.",
    "Use conservative nutrition estimates and never claim certainty about hidden oil or unclear portions.",
    "Do not say the meal was logged; the user must confirm the proposal.",
    `User message: ${input.message}`,
    `Local day meals: ${JSON.stringify(input.dayMeals).slice(0, 6000)}`,
    `Recent meals: ${JSON.stringify(input.recentMeals).slice(0, 4000)}`,
    `Daily calorie goal: ${input.calorieGoal ?? "unknown"}`,
    `Locale: ${input.locale}; timezone: ${input.timezone}; cuisines: ${
      input.cuisineHints.join(", ") || "none"
    }`,
  ].join("\n");
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.25,
          responseMimeType: "application/json",
        },
      }),
      signal: AbortSignal.timeout(15_000),
    },
  );
  const raw = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new ApiError(
      "UNKNOWN",
      "The food assistant is temporarily unavailable",
      response.status,
      response.status >= 500,
    );
  }
  const text = String(raw?.candidates?.[0]?.content?.parts?.[0]?.text ?? "");
  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(text.replace(/^```json\s*|\s*```$/g, ""));
  } catch (_) {
    throw new ApiError(
      "INVALID_INPUT",
      "The assistant returned an invalid meal",
      502,
      true,
    );
  }
  const draft = normalizeDraft(parsed.draft as Record<string, unknown>, input);
  return {
    assistantText: typeof parsed.assistant_text === "string"
      ? parsed.assistant_text
      : friendlySummary(draft),
    draft,
    operation,
    targetMealId: target == null ? null : String(target.id),
    expectedRevision: target == null ? null : numberOrNull(target.revision),
    provider: "gemini",
    model,
    inputTokens: numberOrNull(raw?.usageMetadata?.promptTokenCount),
    outputTokens: numberOrNull(raw?.usageMetadata?.candidatesTokenCount),
  };
}

function operationFor(message: string): "create" | "update" | "delete" {
  if (/\b(delete|remove|undo|didn['’]?t eat)\b/i.test(message)) return "delete";
  if (/\b(change|correct|edit|update|actually|instead)\b/i.test(message)) {
    return "update";
  }
  return "create";
}

function targetMeal(message: string, meals: unknown[]) {
  const rows = meals.filter((meal): meal is Record<string, unknown> =>
    meal != null && typeof meal === "object"
  );
  const normalized = message.toLowerCase();
  return rows.find((meal) => {
    const title = String(meal.title ?? "").toLowerCase();
    return title.length > 2 && normalized.includes(title);
  }) ?? rows[0] ?? null;
}

function draftFromExisting(
  meal: Record<string, unknown>,
  timezone: string,
): EditableMealDraft {
  const nested = Array.isArray(meal.items)
    ? meal.items
    : Array.isArray(meal.meal_items)
    ? meal.meal_items
    : [];
  const components = nested.map((value, position) => {
    const item = value as Record<string, unknown>;
    return {
      client_id: crypto.randomUUID(),
      position,
      name: String(item.name ?? "Food"),
      food_ref_kind: "manual" as const,
      canonical_food_id: null,
      branded_product_id: null,
      custom_food_id: null,
      quantity: positive(item.quantity, 1),
      unit: stringOr(item.unit, "serving"),
      grams_estimated: nullableNumber(item.grams_estimated),
      calories_kcal: nonNegative(item.calories_kcal),
      protein_g: nonNegative(item.protein_g),
      carbs_g: nonNegative(item.carbs_g),
      fat_g: nonNegative(item.fat_g),
      confidence: nullableNumber(item.confidence),
      source_type: "existing_meal",
      source_id: String(meal.id),
      notes: null,
    } satisfies MealItemWrite;
  });
  return {
    title: String(meal.title ?? "Meal"),
    meal_type: mealType(meal.meal_type),
    logged_at: String(meal.logged_at ?? new Date().toISOString()),
    timezone,
    total: {
      calories_kcal: nonNegative(meal.calories_kcal),
      protein_g: nonNegative(meal.protein_g),
      carbs_g: nonNegative(meal.carbs_g),
      fat_g: nonNegative(meal.fat_g),
    },
    confidence: {
      overall: 1,
      item_identification: 1,
      portion_estimation: 1,
      nutrition_source_quality: 1,
      warnings: [],
    },
    components,
    alternatives: [],
    provenance: { source_type: "existing_meal", meal_id: meal.id },
  };
}

function normalizeDraft(
  raw: Record<string, unknown>,
  input: Parameters<typeof createConversationProposal>[0],
): EditableMealDraft {
  const componentsRaw = Array.isArray(raw?.components) ? raw.components : [];
  const components = componentsRaw.map((value, index) => {
    const item = value as Record<string, unknown>;
    return {
      client_id: crypto.randomUUID(),
      position: index,
      name: stringOr(item.name, ""),
      food_ref_kind: "manual",
      canonical_food_id: null,
      branded_product_id: null,
      custom_food_id: null,
      quantity: positive(item.quantity, 1),
      unit: stringOr(item.unit, "serving"),
      grams_estimated: nullableNumber(item.grams_estimated),
      calories_kcal: nonNegative(item.calories_kcal),
      protein_g: nonNegative(item.protein_g),
      carbs_g: nonNegative(item.carbs_g),
      fat_g: nonNegative(item.fat_g),
      confidence: 0.64,
      source_type: "ai_conversation",
      source_id: null,
      notes: null,
    } satisfies MealItemWrite;
  }).filter((item) => item.name.length > 0);
  if (components.length === 0) {
    throw new ApiError(
      "INVALID_INPUT",
      "I could not identify a food in that message",
      422,
      false,
    );
  }
  const sum = (key: keyof MealItemWrite) =>
    components.reduce((total, item) => total + Number(item[key] ?? 0), 0);
  return {
    title: stringOr(
      raw?.title,
      components.map((item) => item.name).join(" + "),
    ),
    meal_type: mealType(raw?.meal_type ?? input.mealTypeHint),
    logged_at: new Date().toISOString(),
    timezone: input.timezone,
    total: {
      calories_kcal: sum("calories_kcal"),
      protein_g: sum("protein_g"),
      carbs_g: sum("carbs_g"),
      fat_g: sum("fat_g"),
    },
    confidence: {
      overall: 0.64,
      item_identification: 0.68,
      portion_estimation: 0.55,
      nutrition_source_quality: 0.62,
      warnings: [{
        code: "review_estimate",
        message:
          "This conversational estimate should be reviewed before saving.",
        severity: "review",
      }],
    },
    components,
    alternatives: [],
    provenance: { provider: "gemini", source_type: "conversation" },
  };
}

function friendlySummary(draft: EditableMealDraft) {
  const count = draft.components.length;
  return count === 1
    ? `I found ${draft.components[0].name}. Take a quick look before I add it.`
    : `I separated that into ${count} foods. Take a quick look before I add it.`;
}

function mealType(value: unknown): EditableMealDraft["meal_type"] {
  return ["breakfast", "lunch", "dinner", "snack"].includes(String(value))
    ? String(value) as EditableMealDraft["meal_type"]
    : "unknown";
}

function stringOr(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function positive(value: unknown, fallback: number) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function nonNegative(value: unknown) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : 0;
}

function nullableNumber(value: unknown) {
  const parsed = Number(value);
  return value == null || !Number.isFinite(parsed) ? null : parsed;
}

function numberOrNull(value: unknown) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}
