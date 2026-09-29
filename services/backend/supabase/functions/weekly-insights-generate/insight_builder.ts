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
      "Protein",
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
      "Top repeat",
      repeated.summary,
      repeated.payload,
      status,
    ),
    insight(
      input,
      "highest_variance_meal_slot",
      "Most varied meal",
      slot.summary,
      slot.payload,
      status,
    ),
    insight(
      input,
      "logging_streak",
      "Logging",
      `Logged ${count(days.size, "day")} this week.`,
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
      "Calories",
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
      summary: "No repeat stood out yet.",
      payload: { title: null, count: 0, meal_type: null },
    };
  }
  const mealType = [...top.mealTypes.entries()].sort((a, b) => b[1] - a[1])[0]
    ?.[0] ?? null;
  return {
    title: top.title,
    summary: `${top.title} came up ${count(top.count, "time")}.`,
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
      summary: "Log more to see a pattern.",
      payload: {
        meal_type: null,
        variance: null,
        sample_count: top?.count ?? 0,
      },
    };
  }
  return {
    summary: `${mealTypeLabel(top.slotName)} varied most. Start there.`,
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
    return "Set a protein target to unlock this.";
  }
  const pct = Math.round(hitRate * 100);
  return `Protein was near target on ${pct}% of days.`;
}

function calorieSummary(avgCalories: number, target: number | null) {
  if (!target) {
    return `Averaged ${formatKcal(avgCalories)} a day.`;
  }
  const delta = round(avgCalories - target);
  if (Math.abs(delta) < 75) {
    return "Close to your target.";
  }
  if (delta > 0) {
    return `${formatKcal(delta)} above target.`;
  }
  return `${formatKcal(Math.abs(delta))} below target.`;
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
      action_title: "Add protein to one meal",
      action_body: "Add a protein you like to one regular meal.",
      based_on: {
        protein_hit_rate: hitRate,
        repeated_meal: repeatedTitle,
      },
    };
  }
  if (repeatedTitle) {
    return {
      action_id: "reuse_repeat_meal",
      action_title: "Keep a go-to handy",
      action_body: `Log ${repeatedTitle} again when the week gets busy.`,
      based_on: {
        protein_hit_rate: hitRate,
        repeated_meal: repeatedTitle,
      },
    };
  }
  return {
    action_id: "create_repeat_pattern",
    action_title: "Make one meal a go-to",
    action_body: "Log one familiar meal a few times next week.",
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

/** "1 day" / "3 days". Keep in step with the app's `Labels.count`. */
function count(n: number, singular: string, plural = `${singular}s`) {
  return `${formatNumber(n)} ${n === 1 ? singular : plural}`;
}

/** 1840.4 -> "1,840". */
function formatNumber(value: number) {
  return String(Math.round(value)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function formatKcal(value: number) {
  return `${formatNumber(value)} kcal`;
}

const MEAL_TYPE_LABELS: Record<string, string> = {
  breakfast: "Breakfast",
  lunch: "Lunch",
  dinner: "Dinner",
  snack: "Snack",
  unknown: "Other",
};

/** Human label for a meal slot. Matches the app's `Labels.mealType`. */
function mealTypeLabel(value: string) {
  const known = MEAL_TYPE_LABELS[value.trim().toLowerCase()];
  if (known) return known;
  return value.replaceAll("_", " ").replace(
    /^\w/,
    (char) => char.toUpperCase(),
  );
}
