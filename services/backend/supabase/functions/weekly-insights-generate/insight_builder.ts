export type MealRow = {
  id: string;
  title: string;
  meal_type: string;
  logged_at: string;
  calories_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  deleted_at: string | null;
};

type LocalMealRow = MealRow & { local_day: string };

export function buildInsights(input: {
  userId: string;
  weekStart: string;
  meals: LocalMealRow[];
  calorieGoal: number | null;
  proteinGoal: number | null;
}) {
  const days = new Set(input.meals.map((meal) => meal.local_day));
  const status = input.meals.length >= 3 ? "ready" : "insufficient_data";
  const repeated = mostRepeatedMeal(input.meals);
  const slot = highestVarianceSlot(input.meals);
  const avgCalories = average(
    input.meals.map((meal) => Number(meal.calories_kcal ?? 0)),
  );
  const proteinHitRate = targetHitRate(
    input.meals,
    input.proteinGoal,
    "protein_g",
  );
  const streak = longestStreak([...days].sort());
  const missingWeekdays = missingWeekdaysFor(input.weekStart, days);
  const calorieDelta = input.calorieGoal == null
    ? null
    : round(avgCalories - input.calorieGoal);

  return [
    insight(
      input,
      "protein_target_hit_rate",
      "Protein consistency",
      proteinSummary(proteinHitRate, input.proteinGoal),
      {
        hit_rate: proteinHitRate,
        logged_days: days.size,
        target_g: input.proteinGoal,
      },
      status,
    ),
    insight(
      input,
      "most_repeated_meal",
      "Reliable repeat",
      repeated.summary,
      repeated.payload,
      status,
    ),
    insight(
      input,
      "highest_variance_meal_slot",
      "Most flexible meal slot",
      slot.summary,
      slot.payload,
      status,
    ),
    insight(
      input,
      "logging_streak",
      "Logging rhythm",
      `${days.size} day${
        days.size === 1 ? "" : "s"
      } had meals logged this week.`,
      {
        logged_days: days.size,
        meal_count: input.meals.length,
        longest_streak_days: streak,
        missing_weekdays: missingWeekdays,
      },
      status,
    ),
    insight(
      input,
      "average_intake_vs_target",
      "Average intake",
      calorieSummary(avgCalories, input.calorieGoal),
      {
        average_calories_kcal: round(avgCalories),
        target_calories_kcal: input.calorieGoal,
        delta_kcal: calorieDelta,
        band: calorieBand(calorieDelta),
      },
      status,
    ),
    insight(
      input,
      "next_week_suggestion",
      "Next week",
      nextWeekSuggestion(proteinHitRate, repeated.title),
      nextWeekPayload(proteinHitRate, repeated.title),
      status,
    ),
  ];
}

function insight(
  input: { userId: string; weekStart: string },
  insightType: string,
  title: string,
  summary: string,
  payload: Record<string, unknown>,
  status: string,
) {
  return {
    user_id: input.userId,
    week_start: input.weekStart,
    insight_type: insightType,
    title,
    summary,
    payload,
    status,
    generated_at: new Date().toISOString(),
  };
}

function mostRepeatedMeal(meals: MealRow[]) {
  const counts = new Map<
    string,
    { title: string; count: number; mealTypes: Map<string, number> }
  >();
  for (const meal of meals) {
    const key = meal.title.trim().toLowerCase();
    if (!key) continue;
    const current = counts.get(key) ?? {
      title: meal.title,
      count: 0,
      mealTypes: new Map<string, number>(),
    };
    current.count += 1;
    current.mealTypes.set(
      meal.meal_type,
      (current.mealTypes.get(meal.meal_type) ?? 0) + 1,
    );
    counts.set(key, current);
  }
  const top = [...counts.values()].sort((a, b) => b.count - a.count)[0];
  if (!top) {
    return {
      title: null,
      summary: "No repeated meal stood out yet.",
      payload: { title: null, count: 0, meal_type: null },
    };
  }
  const mealType = [...top.mealTypes.entries()].sort((a, b) => b[1] - a[1])[0]
    ?.[0] ?? null;
  return {
    title: top.title,
    summary: `${top.title} appeared ${top.count} time${
      top.count === 1 ? "" : "s"
    } this week.`,
    payload: { title: top.title, count: top.count, meal_type: mealType },
  };
}

function highestVarianceSlot(meals: MealRow[]) {
  const bySlot = new Map<string, number[]>();
  for (const meal of meals) {
    const values = bySlot.get(meal.meal_type) ?? [];
    values.push(Number(meal.calories_kcal ?? 0));
    bySlot.set(meal.meal_type, values);
  }
  const top = [...bySlot.entries()]
    .map(([slotName, values]) => ({
      slotName,
      variance: variance(values),
      count: values.length,
    }))
    .sort((a, b) => b.variance - a.variance)[0];
  if (!top || top.count < 2) {
    return {
      summary:
        "Meal timing is still settling; a pattern will appear with more logs.",
      payload: {
        meal_type: null,
        variance: null,
        sample_count: top?.count ?? 0,
      },
    };
  }
  return {
    summary: `${
      label(top.slotName)
    } varied the most this week, which is a good place to review portions first.`,
    payload: {
      meal_type: top.slotName,
      variance: round(top.variance),
      sample_count: top.count,
    },
  };
}

function targetHitRate(
  meals: LocalMealRow[],
  target: number | null,
  key: "protein_g",
) {
  if (!target || meals.length === 0) return null;
  const daily = new Map<string, number>();
  for (const meal of meals) {
    daily.set(
      meal.local_day,
      (daily.get(meal.local_day) ?? 0) + Number(meal[key] ?? 0),
    );
  }
  if (daily.size === 0) return null;
  const hits =
    [...daily.values()].filter((value) => value >= target * 0.9).length;
  return round(hits / daily.size);
}

function proteinSummary(hitRate: number | null, target: number | null) {
  if (!target || hitRate == null) {
    return "Set a protein target to unlock this weekly check.";
  }
  const pct = Math.round(hitRate * 100);
  return `Protein landed near target on ${pct}% of logged days.`;
}

function calorieSummary(avgCalories: number, target: number | null) {
  if (!target) {
    return `${round(avgCalories)} kcal average across logged meals this week.`;
  }
  const delta = round(avgCalories - target);
  if (Math.abs(delta) < 75) {
    return "Average intake stayed close to your target this week.";
  }
  if (delta > 0) {
    return `Average intake was ${delta} kcal above target on logged days.`;
  }
  return `Average intake was ${
    Math.abs(delta)
  } kcal below target on logged days.`;
}

function nextWeekSuggestion(
  hitRate: number | null,
  repeatedTitle: string | null,
) {
  return nextWeekPayload(hitRate, repeatedTitle).action_body;
}

function nextWeekPayload(
  hitRate: number | null,
  repeatedTitle: string | null,
) {
  if (hitRate != null && hitRate < 0.5) {
    return {
      action_id: "anchor_protein",
      action_title: "Anchor one meal with protein",
      action_body:
        "Try anchoring one regular meal with a protein you already like.",
      based_on: {
        protein_hit_rate: hitRate,
        repeated_meal: repeatedTitle,
      },
    };
  }
  if (repeatedTitle) {
    return {
      action_id: "reuse_repeat_meal",
      action_title: "Keep a reliable repeat handy",
      action_body:
        `Keep ${repeatedTitle} handy as a quick repeat log when the week gets busy.`,
      based_on: {
        protein_hit_rate: hitRate,
        repeated_meal: repeatedTitle,
      },
    };
  }
  return {
    action_id: "create_repeat_pattern",
    action_title: "Create one repeatable meal",
    action_body:
      "Log one familiar meal a few times next week to make repeat tracking faster.",
    based_on: {
      protein_hit_rate: hitRate,
      repeated_meal: repeatedTitle,
    },
  };
}

function missingWeekdaysFor(weekStart: string, loggedDays: Set<string>) {
  const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const missing: string[] = [];
  for (let i = 0; i < 7; i++) {
    const day = addDays(weekStart, i);
    if (!loggedDays.has(day)) missing.push(labels[i]);
  }
  return missing;
}

function longestStreak(days: string[]) {
  if (days.length === 0) return 0;
  let best = 1;
  let current = 1;
  for (let i = 1; i < days.length; i++) {
    if (addDays(days[i - 1], 1) === days[i]) {
      current += 1;
    } else {
      current = 1;
    }
    best = Math.max(best, current);
  }
  return best;
}

function addDays(date: string, days: number) {
  const value = new Date(`${date}T00:00:00.000Z`);
  value.setUTCDate(value.getUTCDate() + days);
  return value.toISOString().slice(0, 10);
}

function calorieBand(delta: number | null) {
  if (delta == null) return null;
  if (Math.abs(delta) < 75) return "near";
  return delta > 0 ? "above" : "below";
}

function average(values: number[]) {
  if (values.length === 0) return 0;
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function variance(values: number[]) {
  if (values.length < 2) return 0;
  const avg = average(values);
  return average(values.map((value) => (value - avg) ** 2));
}

function round(value: number) {
  return Math.round(value * 100) / 100;
}

function label(value: string) {
  return value.replaceAll("_", " ").replace(
    /^\w/,
    (char) => char.toUpperCase(),
  );
}
