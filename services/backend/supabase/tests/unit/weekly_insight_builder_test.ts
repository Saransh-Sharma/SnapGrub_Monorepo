import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildInsights,
  type MealRow,
} from "../../functions/weekly-insights-generate/insight_builder.ts";

const baseMeal = {
  id: "meal-a",
  title: "Dal bowl",
  meal_type: "lunch",
  logged_at: "2026-05-18T07:30:00.000Z",
  calories_kcal: 500,
  protein_g: 30,
  carbs_g: 60,
  fat_g: 12,
  deleted_at: null,
} satisfies MealRow;

Deno.test("buildInsights enriches weekly check-in payloads", () => {
  const insights = buildInsights({
    userId: "user-a",
    weekStart: "2026-05-18",
    calorieGoal: 2000,
    proteinGoal: 80,
    meals: [
      { ...baseMeal, id: "meal-a", local_day: "2026-05-18" },
      {
        ...baseMeal,
        id: "meal-b",
        title: "Dal bowl",
        local_day: "2026-05-19",
        protein_g: 70,
      },
      {
        ...baseMeal,
        id: "meal-c",
        title: "Paneer",
        meal_type: "dinner",
        local_day: "2026-05-21",
        calories_kcal: 900,
      },
    ],
  });

  const byType = Object.fromEntries(
    insights.map((insight) => [insight.insight_type, insight]),
  );

  assertEquals(insights.length, 6);
  assertEquals(byType.logging_streak.status, "ready");
  assertEquals(byType.logging_streak.payload.logged_days, 3);
  assertEquals(byType.logging_streak.payload.longest_streak_days, 2);
  assertExists(byType.logging_streak.payload.missing_weekdays);
  assertEquals(byType.most_repeated_meal.payload.title, "Dal bowl");
  assertEquals(byType.most_repeated_meal.payload.meal_type, "lunch");
  assertExists(byType.average_intake_vs_target.payload.delta_kcal);
  assertExists(byType.average_intake_vs_target.payload.band);
  assertExists(byType.next_week_suggestion.payload.action_id);
  assertExists(byType.next_week_suggestion.payload.action_title);
  assertExists(byType.next_week_suggestion.payload.action_body);

  // Copy follows docs/09-design/voice.md: terse, plurals correct, no raw ids.
  assertEquals(byType.logging_streak.title, "Logging");
  assertEquals(byType.logging_streak.summary, "Logged 3 days this week.");
  assertEquals(byType.most_repeated_meal.summary, "Dal bowl came up 2 times.");
  assertEquals(
    byType.highest_variance_meal_slot.summary,
    "Lunch varied most. Start there.",
  );
  assertEquals(
    byType.protein_target_hit_rate.summary,
    "Protein was near target on 0% of days.",
  );
  assertEquals(byType.average_intake_vs_target.payload.band, "below");
  assertEquals(
    byType.average_intake_vs_target.summary,
    "1,367 kcal below target.",
  );
  assertEquals(byType.next_week_suggestion.payload.action_id, "anchor_protein");
  assertEquals(
    byType.next_week_suggestion.payload.action_title,
    "Add protein to one meal",
  );
  assertEquals(
    byType.next_week_suggestion.summary,
    "Add a protein you like to one regular meal.",
  );
});

Deno.test("buildInsights copy handles singulars, no targets and repeats", () => {
  const insights = buildInsights({
    userId: "user-a",
    weekStart: "2026-05-18",
    calorieGoal: null,
    proteinGoal: null,
    meals: [
      { ...baseMeal, id: "meal-a", local_day: "2026-05-18" },
      { ...baseMeal, id: "meal-b", local_day: "2026-05-18" },
      {
        ...baseMeal,
        id: "meal-c",
        local_day: "2026-05-18",
        calories_kcal: 4520,
      },
    ],
  });

  const byType = Object.fromEntries(
    insights.map((insight) => [insight.insight_type, insight]),
  );

  assertEquals(byType.logging_streak.summary, "Logged 1 day this week.");
  assertEquals(byType.most_repeated_meal.summary, "Dal bowl came up 3 times.");
  assertEquals(
    byType.protein_target_hit_rate.summary,
    "Set a protein target to unlock this.",
  );
  assertEquals(
    byType.average_intake_vs_target.summary,
    "Averaged 1,840 kcal a day.",
  );
  assertEquals(byType.average_intake_vs_target.payload.band, null);
  assertEquals(
    byType.next_week_suggestion.payload.action_title,
    "Keep a go-to handy",
  );
  assertEquals(
    byType.next_week_suggestion.summary,
    "Log Dal bowl again when the week gets busy.",
  );
});

Deno.test("buildInsights copy for an empty week", () => {
  const insights = buildInsights({
    userId: "user-a",
    weekStart: "2026-05-18",
    calorieGoal: 2000,
    proteinGoal: 80,
    meals: [],
  });

  const byType = Object.fromEntries(
    insights.map((insight) => [insight.insight_type, insight]),
  );

  assertEquals(byType.most_repeated_meal.summary, "No repeat stood out yet.");
  assertEquals(
    byType.highest_variance_meal_slot.summary,
    "Log more to see a pattern.",
  );
  assertEquals(
    byType.next_week_suggestion.payload.action_title,
    "Make one meal a go-to",
  );
  assertEquals(
    byType.next_week_suggestion.summary,
    "Log one familiar meal a few times next week.",
  );
});

Deno.test("buildInsights marks sparse weeks as insufficient data", () => {
  const insights = buildInsights({
    userId: "user-a",
    weekStart: "2026-05-18",
    calorieGoal: null,
    proteinGoal: null,
    meals: [{ ...baseMeal, local_day: "2026-05-18" }],
  });

  assertEquals(
    insights.every((insight) => insight.status === "insufficient_data"),
    true,
  );
});
