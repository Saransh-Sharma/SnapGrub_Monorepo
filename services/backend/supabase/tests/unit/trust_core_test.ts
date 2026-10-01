import { buildRunEvents } from "../../functions/_shared/agent_events.ts";
import {
  applyGrounding,
  type GroundingMatch,
  lookupKeys,
} from "../../functions/_shared/catalog_grounding.ts";
import { createConversationProposal } from "../../functions/_shared/conversation_agent.ts";
import { rankFoodResults } from "../../functions/_shared/food_lookup.ts";
import { parseMealText } from "../../functions/_shared/meal_llm.ts";
import {
  buildDraftFromText,
  type EditableMealDraft,
  type FoodResult,
  type MealItemWrite,
} from "../../functions/_shared/multimodal.ts";
import {
  loggedAtForDay,
  zonedTimeToUtc,
} from "../../functions/_shared/time.ts";

function assert(condition: unknown, message: string) {
  if (!condition) throw new Error(message);
}

function assertEquals(actual: unknown, expected: unknown, message: string) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `${message}: expected ${JSON.stringify(expected)}, got ${
        JSON.stringify(actual)
      }`,
    );
  }
}

const GEMINI = { provider: "gemini" as const, model: "test-model" };

Deno.env.set("GEMINI_API_KEY", "test-key");

type Call = { url: string; headers: Headers; body: Record<string, unknown> };

/// A fetch that answers each call with the next queued reply.
function stubFetch(replies: Array<{ status?: number; text?: string }>) {
  const calls: Call[] = [];
  const fetchStub = ((url: string | URL | Request, init?: RequestInit) => {
    calls.push({
      url: String(url),
      headers: new Headers(init?.headers),
      body: JSON.parse(String(init?.body ?? "{}")),
    });
    const reply = replies[Math.min(calls.length - 1, replies.length - 1)];
    return Promise.resolve(
      new Response(
        JSON.stringify({
          candidates: [{ content: { parts: [{ text: reply.text ?? "" }] } }],
          usageMetadata: { promptTokenCount: 100, candidatesTokenCount: 40 },
        }),
        { status: reply.status ?? 200 },
      ),
    );
  }) as typeof fetch;
  return { fetch: fetchStub, calls };
}

function modelItem(overrides: Record<string, unknown>) {
  return {
    name: "Food",
    quantity: 1,
    unit: "serving",
    grams_estimated: 100,
    calories_kcal: 100,
    protein_g: 5,
    carbs_g: 10,
    fat_g: 3,
    confidence: 0.7,
    change: "new",
    base_index: null,
    ...overrides,
  };
}

function modelReply(overrides: Record<string, unknown>) {
  return JSON.stringify({
    operation: "create",
    target_meal_id: null,
    assistant_text: "",
    title: "Meal",
    meal_type: "lunch",
    item_confidence: 0.8,
    portion_confidence: 0.6,
    unresolved: [],
    items: [],
    ...overrides,
  });
}

const textInput = {
  source: "text" as const,
  timezone: "Asia/Kolkata",
  locale: "en-IN",
  cuisineHints: ["indian"],
  mealTypeHint: null,
};

function item(overrides: Partial<MealItemWrite>): MealItemWrite {
  return {
    client_id: crypto.randomUUID(),
    position: 0,
    name: "Food",
    food_ref_kind: "manual",
    canonical_food_id: null,
    branded_product_id: null,
    custom_food_id: null,
    quantity: 1,
    unit: "serving",
    grams_estimated: 100,
    calories_kcal: 100,
    protein_g: 5,
    carbs_g: 10,
    fat_g: 3,
    confidence: 0.7,
    source_type: "ai_text",
    source_id: null,
    notes: null,
    ...overrides,
  };
}

function draftOf(components: MealItemWrite[]): EditableMealDraft {
  return {
    title: "Meal",
    meal_type: "lunch",
    logged_at: "2026-07-14T08:00:00.000Z",
    timezone: "Asia/Kolkata",
    total: { calories_kcal: 0, protein_g: 0, carbs_g: 0, fat_g: 0 },
    confidence: {
      overall: 0.6,
      item_identification: 0.8,
      portion_estimation: 0.6,
      nutrition_source_quality: 0.5,
      warnings: [],
    },
    components,
    alternatives: [],
    provenance: {},
  };
}

// --- Rule parser -----------------------------------------------------------

Deno.test("rule parser matches whole words only", () => {
  let code = "";
  try {
    buildDraftFromText({ ...textInput, text: "pineapple" });
  } catch (error) {
    code = (error as { code?: string }).code ?? "";
  }
  assertEquals(code, "INVALID_INPUT", "pineapple must not match apple");
});

Deno.test("rule parser reports the words it could not place", () => {
  const draft = buildDraftFromText({
    ...textInput,
    text: "Salmon, rice and greens",
  });
  assertEquals(
    draft.components.map((component) => component.name),
    ["Steamed rice"],
    "only the known food is itemised",
  );
  assertEquals(
    draft.provenance.unmatched,
    ["salmon", "greens"],
    "unknown foods are listed",
  );
  assert(
    draft.confidence.warnings.some((warning) =>
      warning.code === "unmatched_words" && warning.message.includes("salmon")
    ),
    "the user is told what was left out",
  );
});

Deno.test("rule parser keeps the stated count for plurals", () => {
  const draft = buildDraftFromText({ ...textInput, text: "3 eggs" });
  assertEquals(draft.components.length, 1, "one item");
  assertEquals(draft.components[0].quantity, 3, "three eggs");
  assertEquals(draft.components[0].calories_kcal, 216, "scaled energy");
});

// --- Model-first parsing ---------------------------------------------------

Deno.test("text parsing asks the model and itemises every food", async () => {
  const stub = stubFetch([{
    text: modelReply({
      title: "Salmon, rice and greens",
      items: [
        modelItem({ name: "grilled salmon", grams_estimated: 150 }),
        modelItem({ name: "steamed rice", unit: "bowl" }),
        modelItem({ name: "sauteed greens" }),
      ],
    }),
  }]);
  const result = await parseMealText(
    { ...textInput, text: "Salmon, rice and greens" },
    { config: GEMINI, fetch: stub.fetch },
  );
  assertEquals(result.draft.components.length, 3, "three foods");
  assertEquals(
    result.freshItemIds,
    result.draft.components.map((component) => component.client_id),
    "every item is new and may be grounded",
  );
  assertEquals(result.provider, "gemini", "model answered");
  assertEquals(result.inputTokens, 100, "token usage is reported");
  assertEquals(
    result.draft.components[0].source_type,
    "ai_text",
    "items are marked as model estimates",
  );
  const call = stub.calls[0];
  assert(!call.url.includes("key="), "the API key is not in the URL");
  assertEquals(
    call.headers.get("x-goog-api-key"),
    "test-key",
    "the API key travels in a header",
  );
  const config = call.body.generationConfig as Record<string, unknown>;
  assert(config.responseSchema != null, "the reply schema is enforced");
});

Deno.test("an unparseable model reply is retried once", async () => {
  const stub = stubFetch([
    { text: "Sure! Here is your meal" },
    { text: modelReply({ items: [modelItem({ name: "idli" })] }) },
  ]);
  const result = await parseMealText(
    { ...textInput, text: "idli" },
    { config: GEMINI, fetch: stub.fetch },
  );
  assertEquals(stub.calls.length, 2, "two attempts");
  assertEquals(result.draft.components[0].name, "idli", "second reply is used");
  assertEquals(result.inputTokens, 200, "tokens from both attempts count");
});

Deno.test("words the model could not interpret become a warning", async () => {
  const stub = stubFetch([{
    text: modelReply({
      items: [modelItem({ name: "dal" })],
      unresolved: ["zxcv"],
    }),
  }]);
  const result = await parseMealText(
    { ...textInput, text: "dal and zxcv" },
    { config: GEMINI, fetch: stub.fetch },
  );
  assert(
    result.draft.confidence.warnings.some((warning) =>
      warning.code === "unmatched_words" && warning.message.includes("zxcv")
    ),
    "unresolved words are surfaced",
  );
});

Deno.test("a model reply with no food is a clear not-found", async () => {
  const stub = stubFetch([{ text: modelReply({ items: [] }) }]);
  let message = "";
  try {
    await parseMealText(
      { ...textInput, text: "hello there" },
      { config: GEMINI, fetch: stub.fetch },
    );
  } catch (error) {
    message = (error as Error).message;
  }
  assert(
    message.toLowerCase().includes("could not identify"),
    "the app keys its friendly copy on this phrase",
  );
});

Deno.test("a provider outage falls back only when every word is understood", async () => {
  const outage = stubFetch([{ status: 503 }]);
  const full = await parseMealText(
    { ...textInput, text: "2 rotis and dal" },
    { config: GEMINI, fetch: outage.fetch },
  );
  assertEquals(full.provider, "snapgrub", "rule parser stood in");
  assertEquals(full.draft.provenance.parser, "rule_fallback", "and says so");

  let code = "";
  try {
    await parseMealText(
      { ...textInput, text: "Salmon, rice and greens" },
      { config: GEMINI, fetch: outage.fetch },
    );
  } catch (error) {
    code = (error as { code?: string }).code ?? "";
  }
  assertEquals(
    code,
    "PROVIDER_UNAVAILABLE",
    "a partial parse is refused rather than logged short",
  );
});

Deno.test("without a configured model the rule parser is used", async () => {
  const result = await parseMealText(
    { ...textInput, text: "one bowl rice and curd" },
    { config: null },
  );
  assertEquals(result.provider, "snapgrub", "no model call");
  assertEquals(result.draft.components.length, 2, "both foods parsed");
});

// --- Corrections -----------------------------------------------------------

Deno.test("a correction leaves untouched items exactly as they were", async () => {
  const roti = item({
    name: "Roti",
    food_ref_kind: "canonical",
    canonical_food_id: "food-roti",
    quantity: 2,
    unit: "roti",
    grams_estimated: 80,
    calories_kcal: 237.6,
    protein_g: 7.84,
    carbs_g: 36.8,
    fat_g: 6,
    source_type: "curated",
    source_id: "curated:roti",
  });
  const dal = item({
    name: "Dal tadka",
    position: 1,
    unit: "katori",
    grams_estimated: 180,
    calories_kcal: 212.4,
  });
  const stub = stubFetch([{
    text: modelReply({
      operation: "update",
      items: [
        modelItem({
          name: "Roti",
          quantity: 3,
          unit: "roti",
          grams_estimated: 120,
          calories_kcal: 999,
          change: "scale",
          base_index: 0,
        }),
        modelItem({ name: "Dal", calories_kcal: 1, change: "keep", base_index: 1 }),
      ],
    }),
  }]);
  const result = await parseMealText(
    { ...textInput, text: "it was 3 rotis", baseItems: [roti, dal], baseTitle: "Lunch" },
    { config: GEMINI, fetch: stub.fetch },
  );
  const [scaled, kept] = result.draft.components;
  assertEquals(scaled.quantity, 3, "the amount changed");
  assertEquals(scaled.calories_kcal, 356.4, "energy scales from the original, not the model");
  assertEquals(scaled.canonical_food_id, "food-roti", "the catalog reference survives");
  assertEquals(kept.name, "Dal tadka", "the kept item keeps its name");
  assertEquals(kept.calories_kcal, 212.4, "and its numbers");
  assertEquals(result.freshItemIds, [], "carried-over items are not re-grounded");
  const prompt = String(
    ((stub.calls[0].body.contents as Record<string, unknown>[])[0]
      .parts as Record<string, unknown>[])[0].text,
  );
  assert(prompt.includes("<current_meal>"), "the model sees the current meal");
});

Deno.test("a correction during an outage fails as retryable", async () => {
  const outage = stubFetch([{ status: 503 }]);
  let code = "";
  try {
    await parseMealText(
      { ...textInput, text: "it was 3 rotis", baseItems: [item({})] },
      { config: GEMINI, fetch: outage.fetch },
    );
  } catch (error) {
    code = (error as { code?: string }).code ?? "";
  }
  assertEquals(code, "PROVIDER_UNAVAILABLE", "not a raw provider error");
});

Deno.test("corrections are refused when no model is configured", async () => {
  let code = "";
  try {
    await parseMealText(
      { ...textInput, text: "it was 3 rotis", baseItems: [item({})] },
      { config: null },
    );
  } catch (error) {
    code = (error as { code?: string }).code ?? "";
  }
  assertEquals(code, "PROVIDER_UNAVAILABLE", "the rule parser cannot correct");
});

// --- Conversation agent ----------------------------------------------------

const agentInput = {
  timezone: "Asia/Kolkata",
  locale: "en-IN",
  cuisineHints: [],
  mealTypeHint: null,
  calorieGoal: 2000,
  recentMeals: [],
};

function dayMeal(id: string, title: string, mealType: string) {
  return {
    id,
    title,
    meal_type: mealType,
    logged_at: "2026-07-14T03:00:00Z",
    revision: 2,
    items: [{
      name: "Roti",
      quantity: 2,
      unit: "roti",
      grams_estimated: 80,
      calories_kcal: 238,
      protein_g: 8,
      carbs_g: 37,
      fat_g: 6,
      canonical_food_id: "food-roti",
      source_type: "curated",
    }],
  };
}

Deno.test("the rule agent never guesses between several meals", async () => {
  const result = await createConversationProposal({
    ...agentInput,
    message: "delete that",
    dayMeals: [
      dayMeal("meal-1", "Eggs and toast", "breakfast"),
      dayMeal("meal-2", "Dal rice", "lunch"),
    ],
  }, { config: null });
  assertEquals(result.operation, "clarify", "it asks instead of picking one");
  assert(result.assistantText.includes("Dal rice"), "and names the options");
});

Deno.test("the rule agent resolves a meal by its type", async () => {
  const result = await createConversationProposal({
    ...agentInput,
    message: "delete my lunch",
    dayMeals: [
      dayMeal("meal-1", "Eggs and toast", "breakfast"),
      dayMeal("meal-2", "Dal rice", "lunch"),
    ],
  }, { config: null });
  assertEquals(result.operation, "delete", "delete is staged");
  assertEquals(result.targetMealId, "meal-2", "for the lunch");
});

Deno.test("a model target that is not on the day becomes a question", async () => {
  const stub = stubFetch([{
    text: modelReply({ operation: "delete", target_meal_id: "meal-999" }),
  }]);
  const result = await createConversationProposal({
    ...agentInput,
    message: "remove dinner",
    dayMeals: [dayMeal("meal-1", "Eggs and toast", "breakfast")],
  }, { config: GEMINI, fetch: stub.fetch });
  assertEquals(result.operation, "clarify", "an invented id is never acted on");
  assertEquals(result.draft, null, "nothing is staged");
});

Deno.test("a model update keeps the meal's time and untouched items", async () => {
  const stub = stubFetch([{
    text: modelReply({
      operation: "update",
      target_meal_id: "meal-1",
      assistant_text: "I added curd. Take a look.",
      title: "Roti and curd",
      items: [
        modelItem({ name: "Roti", change: "keep", base_index: 0 }),
        modelItem({ name: "curd", unit: "katori", grams_estimated: 120 }),
      ],
    }),
  }]);
  const result = await createConversationProposal({
    ...agentInput,
    message: "add a katori of curd to breakfast",
    dayMeals: [dayMeal("meal-1", "Roti", "breakfast")],
  }, { config: GEMINI, fetch: stub.fetch });
  assertEquals(result.operation, "update", "update is staged");
  assertEquals(result.expectedRevision, 2, "with revision safety");
  assertEquals(
    result.draft?.logged_at,
    "2026-07-14T03:00:00Z",
    "the meal keeps its original time",
  );
  assertEquals(
    result.draft?.components[0].canonical_food_id,
    "food-roti",
    "the saved item keeps its catalog reference",
  );
  assertEquals(result.draft?.components.length, 2, "and the new item is added");
  assertEquals(
    result.freshItemIds,
    [result.draft?.components[1].client_id],
    "only the added item may be grounded",
  );
});

Deno.test("an agent outage with an unparseable message is retryable", async () => {
  const outage = stubFetch([{ status: 500 }]);
  let code = "";
  try {
    await createConversationProposal({
      ...agentInput,
      message: "I had salmon and greens",
      dayMeals: [],
    }, { config: GEMINI, fetch: outage.fetch });
  } catch (error) {
    code = (error as { code?: string }).code ?? "";
  }
  assertEquals(code, "PROVIDER_UNAVAILABLE", "the user can try again");
});

// --- Time ------------------------------------------------------------------

Deno.test("a meal logged just after midnight in India stays on that day", () => {
  // 02:00 on 14 July in Kolkata is 20:30 UTC on 13 July.
  const now = new Date("2026-07-13T20:30:00.000Z");
  assertEquals(
    loggedAtForDay("2026-07-14", "Asia/Kolkata", now),
    "2026-07-13T20:30:00.000Z",
    "today's thread gets the real instant",
  );
  assertEquals(
    loggedAtForDay("2026-07-12", "Asia/Kolkata", now),
    "2026-07-11T20:30:00.000Z",
    "an earlier thread gets the same local time on that day",
  );
});

Deno.test("wall-clock conversion follows daylight saving", () => {
  assertEquals(
    zonedTimeToUtc("2026-01-15", 12, 0, "America/New_York").toISOString(),
    "2026-01-15T17:00:00.000Z",
    "standard time is UTC-5",
  );
  assertEquals(
    zonedTimeToUtc("2026-07-15", 12, 0, "America/New_York").toISOString(),
    "2026-07-15T16:00:00.000Z",
    "daylight time is UTC-4",
  );
});

Deno.test("an unknown time zone is rejected", () => {
  let code = "";
  try {
    loggedAtForDay("2026-07-14", "Mars/Olympus");
  } catch (error) {
    code = (error as { code?: string }).code ?? "";
  }
  assertEquals(code, "INVALID_INPUT", "bad zones are a client error");
});

// --- Catalog grounding -----------------------------------------------------

const rotiMatch: GroundingMatch = {
  kind: "canonical",
  id: "food-roti",
  per100g: { calories_kcal: 297, protein_g: 9.8, carbs_g: 46, fat_g: 7.5 },
  portions: { roti: 40, g: 1 },
  sourceType: "curated",
  sourceId: "curated:roti",
};

Deno.test("a matched item takes its nutrition from the catalog", () => {
  const draft = draftOf([
    item({
      name: "Rotis",
      quantity: 2,
      unit: "roti",
      grams_estimated: 60,
      calories_kcal: 180,
    }),
    item({ name: "grilled salmon", position: 1, calories_kcal: 280 }),
  ]);
  const grounded = applyGrounding(
    draft,
    new Map([["roti", rotiMatch]]),
    { preferCatalogPortions: true },
  );
  const [roti, salmon] = grounded.components;
  assertEquals(roti.food_ref_kind, "canonical", "the roti is tied to the catalog");
  assertEquals(roti.canonical_food_id, "food-roti", "by id");
  assertEquals(roti.grams_estimated, 80, "two catalog rotis are 80 g");
  assertEquals(roti.calories_kcal, 237.6, "energy comes from the catalog");
  assertEquals(salmon.food_ref_kind, "manual", "the unmatched item stays an estimate");
  assertEquals(salmon.calories_kcal, 280, "with the model's numbers");
  assertEquals(grounded.total.calories_kcal, 517.6, "totals are recomputed");
  assert(
    grounded.confidence.nutrition_source_quality > 0.5,
    "source quality rises with the grounded share",
  );
  assertEquals(
    grounded.provenance.grounding,
    { matched: 1, estimated: 1 },
    "the split is recorded",
  );
});

Deno.test("a photo keeps the amount the model saw", () => {
  const draft = draftOf([
    item({
      name: "roti",
      quantity: 1,
      unit: "roti",
      grams_estimated: 55,
      calories_kcal: 150,
      source_type: "ai_photo",
    }),
  ]);
  const grounded = applyGrounding(
    draft,
    new Map([["roti", rotiMatch]]),
    { preferCatalogPortions: false },
  );
  assertEquals(grounded.components[0].grams_estimated, 55, "visual grams win");
  assertEquals(grounded.components[0].calories_kcal, 163.35, "at catalog density");
});

Deno.test("a match that contradicts the estimate is not applied", () => {
  const draft = draftOf([
    item({
      name: "roti",
      quantity: 1,
      unit: "roti",
      grams_estimated: 40,
      calories_kcal: 400,
    }),
  ]);
  const grounded = applyGrounding(
    draft,
    new Map([["roti", rotiMatch]]),
    { preferCatalogPortions: true },
  );
  assertEquals(
    grounded.components[0].food_ref_kind,
    "manual",
    "a 3x disagreement means a different food",
  );
});

Deno.test("items carried over from the user's meal are never re-grounded", () => {
  const roti = { name: "roti", unit: "roti", grams_estimated: 40 };
  const kept = item({ ...roti, calories_kcal: 95 });
  const added = item({ ...roti, calories_kcal: 110, position: 1 });
  const grounded = applyGrounding(
    draftOf([kept, added]),
    new Map([["roti", rotiMatch]]),
    { preferCatalogPortions: true, onlyItems: [added.client_id] },
  );
  assertEquals(grounded.components[0], kept, "the kept item is untouched");
  assertEquals(
    grounded.components[1].food_ref_kind,
    "canonical",
    "the new item is grounded",
  );
});

Deno.test("rule-parsed items are grounded like any new item", () => {
  const draft = buildDraftFromText({ ...textInput, text: "2 rotis" });
  const grounded = applyGrounding(
    draft,
    new Map([["roti", rotiMatch]]),
    { preferCatalogPortions: true },
  );
  assertEquals(grounded.components[0].food_ref_kind, "canonical", "tied to the catalog");
  assertEquals(grounded.components[0].calories_kcal, 237.6, "with catalog energy");
});

Deno.test("lookup keys include singular forms", () => {
  assertEquals(lookupKeys("Rotis"), ["rotis", "roti"], "plural s");
  assertEquals(
    lookupKeys("Mangoes"),
    ["mangoes", "mango", "mangoe"],
    "plural es",
  );
});

// --- Food search -----------------------------------------------------------

function food(name: string, type: FoodResult["result_type"]): FoodResult {
  return {
    id: name,
    result_type: type,
    name,
    brand: null,
    serving_quantity: 1,
    serving_unit: "serving",
    serving_grams: 100,
    calories_kcal: 100,
    protein_g: 1,
    carbs_g: 1,
    fat_g: 1,
    confidence: 0.8,
    provenance: {
      source_type: type,
      source_id: null,
      license_tag: null,
      source_quality: null,
    },
  };
}

Deno.test("search ranks exact names ahead of longer matches", () => {
  const ranked = rankFoodResults("rice", [
    food("Rice bran oil", "canonical"),
    food("Basmati rice cooked", "canonical"),
    food("Licorice", "canonical"),
    food("Rice", "canonical"),
  ]).map((result) => result.name);
  assertEquals(
    ranked,
    ["Rice", "Rice bran oil", "Basmati rice cooked", "Licorice"],
    "exact, prefix, whole word, substring",
  );
});

Deno.test("search puts the user's own food first on a tie", () => {
  const ranked = rankFoodResults("dal", [
    food("Dal", "canonical"),
    food("Dal", "custom"),
  ]).map((result) => result.result_type);
  assertEquals(ranked, ["custom", "canonical"], "own foods lead");
});

// --- Agent events ----------------------------------------------------------

Deno.test("a clarifying reply streams text and no proposal", () => {
  const events = buildRunEvents({
    runId: "run-1",
    assistantId: "message-1",
    assistantText: "Which meal do you mean: Breakfast, Lunch?",
    proposal: null,
  });
  const names = events.map((event) => event.event);
  assert(names.includes("assistant.delta"), "the question is streamed");
  assert(!names.includes("proposal.ready"), "nothing is staged");
  assertEquals(names.at(-1), "run.completed", "the run completes");
  assertEquals(
    events.map((event) => event.sequence),
    events.map((_, index) => index + 1),
    "sequence numbers are contiguous",
  );
});
