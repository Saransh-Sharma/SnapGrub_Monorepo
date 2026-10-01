import { ApiError } from "./errors.ts";
import { type ModelProvider, textModelConfig } from "./llm.ts";
import {
  type DayMealContext,
  draftFromModelOutput,
  type MealModelDeps,
  requestAgentMeal,
  type UserFoodHint,
} from "./meal_llm.ts";
import {
  buildDraftFromText,
  type EditableMealDraft,
  type MealItemWrite,
} from "./multimodal.ts";

export type ConversationAgentResult = {
  assistantText: string;
  /// Null for "clarify": the assistant asks a question and proposes nothing.
  draft: EditableMealDraft | null;
  /// client_ids of draft items produced in this run; null means all of them.
  /// Items kept from the existing meal are not listed.
  freshItemIds: string[] | null;
  operation: "create" | "update" | "delete" | "clarify";
  targetMealId: string | null;
  expectedRevision: number | null;
  provider: string;
  model: string;
  inputTokens: number | null;
  outputTokens: number | null;
};

type ProposalInput = {
  message: string;
  timezone: string;
  locale: string;
  cuisineHints: string[];
  mealTypeHint: string | null;
  dayMeals: unknown[];
  recentMeals: unknown[];
  calorieGoal: number | null;
  userFoods?: UserFoodHint[];
};

type DayMeal = DayMealContext & { revision: number | null };

/// Reads a conversation message and stages a meal change for the user to
/// confirm. Never mutates the ledger itself.
export async function createConversationProposal(
  input: ProposalInput,
  deps: MealModelDeps = {},
): Promise<ConversationAgentResult> {
  const meals = dayMealsFrom(input.dayMeals);
  const config = deps.config !== undefined ? deps.config : textModelConfig();
  if (!config) return proposeWithRules(input, meals, false);
  try {
    return await proposeWithModel(input, meals, config, deps);
  } catch (error) {
    if (error instanceof ApiError && error.status === 422) throw error;
    console.error(JSON.stringify({
      level: "error",
      scope: "conversation_agent.fallback",
      message: error instanceof Error ? error.message : String(error),
    }));
    try {
      return proposeWithRules(input, meals, true);
    } catch (_) {
      throw new ApiError(
        "PROVIDER_UNAVAILABLE",
        "The food assistant is temporarily unavailable",
        503,
        true,
      );
    }
  }
}

async function proposeWithModel(
  input: ProposalInput,
  meals: DayMeal[],
  config: { provider: ModelProvider; model: string },
  deps: MealModelDeps,
): Promise<ConversationAgentResult> {
  const { output, usage } = await requestAgentMeal({
    message: input.message,
    locale: input.locale,
    timezone: input.timezone,
    cuisineHints: input.cuisineHints,
    mealTypeHint: input.mealTypeHint,
    dayMeals: meals,
    recentMealTitles: recentTitles(input.recentMeals),
    userFoods: input.userFoods ?? [],
  }, config, deps);

  if (output.operation === "clarify") {
    return clarify(output.assistantText || whichMealQuestion(meals), usage);
  }
  if (output.operation === "create") {
    const { draft, freshItemIds } = draftFromModelOutput(output, {
      source: "conversation",
      timezone: input.timezone,
      locale: input.locale,
      cuisineHints: input.cuisineHints,
      mealTypeHint: input.mealTypeHint,
      usage,
    });
    return {
      assistantText: output.assistantText || friendlySummary(draft),
      draft,
      freshItemIds,
      operation: "create",
      targetMealId: null,
      expectedRevision: null,
      ...usage,
    };
  }

  // The model may only target a meal that is really on this day.
  const target = meals.find((meal) => meal.id === output.targetMealId);
  if (!target) return clarify(whichMealQuestion(meals), usage);
  if (output.operation === "delete") {
    return deleteProposal(target, input.timezone, usage);
  }
  const { draft, freshItemIds } = draftFromModelOutput(output, {
    source: "conversation",
    timezone: input.timezone,
    locale: input.locale,
    cuisineHints: input.cuisineHints,
    mealTypeHint: target.mealType,
    baseItems: target.items,
    baseTitle: target.title,
    usage,
  });
  draft.logged_at = target.loggedAt;
  return {
    assistantText: output.assistantText || friendlySummary(draft),
    draft,
    freshItemIds,
    operation: "update",
    targetMealId: target.id,
    expectedRevision: target.revision,
    ...usage,
  };
}

/// Keyword-based stand-in used in mock mode and when the model is down.
function proposeWithRules(
  input: ProposalInput,
  meals: DayMeal[],
  fallback: boolean,
): ConversationAgentResult {
  const usage = {
    provider: "nutrition-tools",
    model: fallback ? "rule_fallback" : "catalog-rule-v2",
    inputTokens: null,
    outputTokens: null,
  };
  const operation = operationFor(input.message);
  const target = operation === "create"
    ? null
    : targetMeal(input.message, meals);
  if (operation !== "create" && !target) {
    return clarify(whichMealQuestion(meals), usage);
  }
  if (operation === "delete") {
    return deleteProposal(target!, input.timezone, usage);
  }
  const draft = buildDraftFromText({
    text: input.message,
    source: "text",
    timezone: input.timezone,
    locale: input.locale,
    cuisineHints: input.cuisineHints,
    mealTypeHint: input.mealTypeHint,
    fallback,
  });
  const unmatched = draft.provenance.unmatched as string[] | undefined;
  if (fallback && unmatched && unmatched.length > 0) {
    throw new ApiError("PROVIDER_UNAVAILABLE", "Partial rule parse", 503, true);
  }
  if (target) draft.logged_at = target.loggedAt;
  return {
    assistantText: friendlySummary(draft),
    draft,
    freshItemIds: null,
    operation,
    targetMealId: target?.id ?? null,
    expectedRevision: target?.revision ?? null,
    ...usage,
  };
}

function deleteProposal(
  target: DayMeal,
  timezone: string,
  usage: Pick<
    ConversationAgentResult,
    "provider" | "model" | "inputTokens" | "outputTokens"
  >,
): ConversationAgentResult {
  return {
    assistantText: `I found ${target.title}. Confirm below to delete it.`,
    draft: draftFromExisting(target, timezone),
    freshItemIds: [],
    operation: "delete",
    targetMealId: target.id,
    expectedRevision: target.revision,
    ...usage,
  };
}

function clarify(
  assistantText: string,
  usage: Pick<
    ConversationAgentResult,
    "provider" | "model" | "inputTokens" | "outputTokens"
  >,
): ConversationAgentResult {
  return {
    assistantText,
    draft: null,
    freshItemIds: [],
    operation: "clarify",
    targetMealId: null,
    expectedRevision: null,
    ...usage,
  };
}

function whichMealQuestion(meals: DayMeal[]) {
  if (meals.length === 0) return "Nothing is logged for this day yet.";
  const titles = meals.slice(0, 4).map((meal) => meal.title);
  return `Which meal do you mean: ${titles.join(", ")}?`;
}

function operationFor(message: string): "create" | "update" | "delete" {
  if (/\b(delete|remove|undo|didn['’]?t eat)\b/i.test(message)) return "delete";
  if (/\b(change|correct|edit|update|actually|instead)\b/i.test(message)) {
    return "update";
  }
  return "create";
}

/// The meal a rule-parsed message refers to: by title, then by meal type,
/// then the only meal of the day. Never guesses between several.
function targetMeal(message: string, meals: DayMeal[]) {
  const normalized = message.toLowerCase();
  const byTitle = meals.filter((meal) => {
    const title = meal.title.toLowerCase();
    return title.length > 2 && normalized.includes(title);
  });
  if (byTitle.length === 1) return byTitle[0];
  const byType = meals.filter((meal) =>
    meal.mealType !== "unknown" &&
    new RegExp(`\\b${meal.mealType}\\b`).test(normalized)
  );
  if (byType.length === 1) return byType[0];
  return meals.length === 1 ? meals[0] : null;
}

function dayMealsFrom(rows: unknown[]): DayMeal[] {
  return rows.filter((row): row is Record<string, unknown> =>
    row != null && typeof row === "object" &&
    (row as Record<string, unknown>).id != null
  ).map((meal) => {
    const nested = Array.isArray(meal.items)
      ? meal.items
      : Array.isArray(meal.meal_items)
      ? meal.meal_items
      : [];
    return {
      id: String(meal.id),
      title: String(meal.title ?? "Meal"),
      mealType: mealType(meal.meal_type),
      loggedAt: String(meal.logged_at ?? new Date().toISOString()),
      revision: numberOrNull(meal.revision),
      items: nested.map((value, position) =>
        itemFromRow(value as Record<string, unknown>, String(meal.id), position)
      ),
    };
  });
}

/// Keeps the saved item's catalog reference so an untouched item survives an
/// update unchanged.
function itemFromRow(
  item: Record<string, unknown>,
  mealId: string,
  position: number,
): MealItemWrite {
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
    client_id: crypto.randomUUID(),
    position,
    name: String(item.name ?? "Food"),
    food_ref_kind: kind,
    canonical_food_id: kind === "canonical" ? canonical : null,
    branded_product_id: kind === "branded" ? branded : null,
    custom_food_id: kind === "custom" ? custom : null,
    quantity: positive(item.quantity, 1),
    unit: stringOr(item.unit, "serving"),
    grams_estimated: nullableNumber(item.grams_estimated),
    calories_kcal: nonNegative(item.calories_kcal),
    protein_g: nonNegative(item.protein_g),
    carbs_g: nonNegative(item.carbs_g),
    fat_g: nonNegative(item.fat_g),
    confidence: nullableNumber(item.confidence),
    source_type: stringOrNull(item.source_type) ?? "existing_meal",
    source_id: stringOrNull(item.source_id) ?? mealId,
    notes: stringOrNull(item.notes),
  };
}

function draftFromExisting(
  meal: DayMeal,
  timezone: string,
): EditableMealDraft {
  const sum = (key: "calories_kcal" | "protein_g" | "carbs_g" | "fat_g") =>
    Number(meal.items.reduce((total, item) => total + item[key], 0).toFixed(2));
  return {
    title: meal.title,
    meal_type: mealType(meal.mealType),
    logged_at: meal.loggedAt,
    timezone,
    total: {
      calories_kcal: sum("calories_kcal"),
      protein_g: sum("protein_g"),
      carbs_g: sum("carbs_g"),
      fat_g: sum("fat_g"),
    },
    confidence: {
      overall: 1,
      item_identification: 1,
      portion_estimation: 1,
      nutrition_source_quality: 1,
      warnings: [],
    },
    components: meal.items,
    alternatives: [],
    provenance: { source_type: "existing_meal", meal_id: meal.id },
  };
}

function recentTitles(rows: unknown[]) {
  const titles = rows.map((row) =>
    row != null && typeof row === "object"
      ? stringOrNull((row as Record<string, unknown>).title)
      : null
  ).filter((title): title is string => title != null);
  return [...new Set(titles)];
}

function friendlySummary(draft: EditableMealDraft) {
  const count = draft.components.length;
  return count === 1
    ? `I found ${draft.components[0].name}. Take a quick look before I log it.`
    : `I found ${count} foods. Take a quick look before I log it.`;
}

function mealType(value: unknown): EditableMealDraft["meal_type"] {
  return ["breakfast", "lunch", "dinner", "snack"].includes(String(value))
    ? String(value) as EditableMealDraft["meal_type"]
    : "unknown";
}

function stringOr(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function stringOrNull(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
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
  return value == null || !Number.isFinite(parsed) ? null : parsed;
}
