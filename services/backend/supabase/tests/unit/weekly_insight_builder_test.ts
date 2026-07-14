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
