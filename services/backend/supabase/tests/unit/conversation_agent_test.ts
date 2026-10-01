import { createConversationProposal } from "../../functions/_shared/conversation_agent.ts";

function assert(condition: unknown, message: string) {
  if (!condition) throw new Error(message);
}

Deno.test("conversation agent stages a delete without mutating the ledger", async () => {
  const result = await createConversationProposal({
    message: "Remove Breakfast",
    timezone: "Asia/Kolkata",
    locale: "en-IN",
    cuisineHints: ["indian"],
    mealTypeHint: null,
    calorieGoal: 2000,
    recentMeals: [],
    dayMeals: [{
      id: "meal-1",
      title: "Breakfast",
      meal_type: "breakfast",
      logged_at: "2026-07-14T08:00:00Z",
      revision: 3,
      calories_kcal: 220,
      protein_g: 14,
      carbs_g: 18,
      fat_g: 10,
      items: [{
        name: "Eggs and toast",
        quantity: 1,
        unit: "plate",
        calories_kcal: 220,
        protein_g: 14,
        carbs_g: 18,
        fat_g: 10,
      }],
    }],
  }, { config: null });

  assert(
    result.operation === "delete",
    "delete should be a proposal operation",
  );
  assert(
    result.targetMealId === "meal-1",
    "delete should target an owned day meal",
  );
  assert(result.expectedRevision === 3, "delete should carry revision safety");
  assert(
    result.draft?.title === "Breakfast",
    "delete should preserve a review snapshot",
  );
});

Deno.test("conversation agent stages nothing when no day meal can be targeted", async () => {
  const result = await createConversationProposal({
    message: "Delete lunch",
    timezone: "UTC",
    locale: "en",
    cuisineHints: [],
    mealTypeHint: null,
    calorieGoal: null,
    recentMeals: [],
    dayMeals: [],
  }, { config: null });
  assert(result.operation === "clarify", "missing targets must fail closed");
  assert(result.draft === null, "a clarifying reply carries no draft");
  assert(result.targetMealId === null, "a clarifying reply targets nothing");
});
