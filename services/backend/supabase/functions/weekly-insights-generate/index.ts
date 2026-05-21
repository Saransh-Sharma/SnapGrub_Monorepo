import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";

type MealRow = {
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

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    requireServiceRole(req);

    const body = await parseBody(req);
    const weekStart = weekStartDate(optionalString(body.week_start) ?? new Date().toISOString());
    const userId = optionalString(body.user_id);
    const limit = boundedLimit(body.limit);
    const client = serviceClient();

    if (!userId) {
      const { data: dueUsers, error: dueError } = await client.rpc("users_due_for_weekly_insights", {
        p_week_start: weekStart,
        p_limit: limit,
      });
      if (dueError) throw dueError;

      const generated = [];
      for (const dueUser of dueUsers ?? []) {
        generated.push(...await generateForUser(client, String(dueUser.user_id), weekStart));
      }

      return jsonResponse({
        weekly_insights: generated,
        processed_users: dueUsers?.length ?? 0,
        server_time: new Date().toISOString(),
        request_id: requestId,
      });
    }

    const data = await generateForUser(client, userId, weekStart);

    return jsonResponse({
      weekly_insights: data,
      server_time: new Date().toISOString(),
      request_id: requestId,
    });
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

async function generateForUser(client: ReturnType<typeof serviceClient>, userId: string, weekStart: string) {
    const { data: profile, error: profileError } = await client
      .from("profiles")
      .select("id, timezone")
      .eq("id", userId)
      .maybeSingle();
    if (profileError) throw profileError;
    if (!profile) throw new ApiError("NOT_FOUND", "Profile not found", 404, false);

    const { data: goal, error: goalError } = await client
      .from("nutrition_goals")
      .select("*")
      .eq("user_id", userId)
      .eq("is_active", true)
      .maybeSingle();
    if (goalError) throw goalError;

    const meals = await readMeals(client, userId, weekStart, String(profile.timezone ?? "UTC"));
    const insights = buildInsights({
      userId,
      weekStart,
      meals,
      calorieGoal: numberOrNull(goal?.calories_kcal),
      proteinGoal: numberOrNull(goal?.protein_g),
    });

    const { data, error } = await client
      .from("weekly_insights")
      .upsert(insights, { onConflict: "user_id,week_start,insight_type" })
      .select("*")
      .order("insight_type", { ascending: true });
    if (error) throw error;
    return data ?? [];
}

function requireServiceRole(req: Request) {
  const expected = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const auth = req.headers.get("authorization") ?? "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (!expected || token !== expected) {
    throw new ApiError("AUTH_REQUIRED", "Service role authorization is required", 401, false);
  }
}

async function parseBody(req: Request): Promise<Record<string, unknown>> {
  try {
    return await req.json();
  } catch (_) {
    throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
  }
}

async function readMeals(client: ReturnType<typeof serviceClient>, userId: string, weekStart: string, timezone: string) {
  const start = new Date(`${weekStart}T00:00:00.000Z`);
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 7);

  const { data, error } = await client
    .from("meals")
    .select("id,title,meal_type,logged_at,calories_kcal,protein_g,carbs_g,fat_g,deleted_at")
    .eq("user_id", userId)
    .is("deleted_at", null)
    .gte("logged_at", start.toISOString())
    .lt("logged_at", end.toISOString())
    .order("logged_at", { ascending: true });
  if (error) throw error;

  return (data ?? []).map((meal) => ({
    ...meal,
    local_day: localDay(meal.logged_at as string, timezone),
  })) as Array<MealRow & { local_day: string }>;
}

function buildInsights(input: {
  userId: string;
  weekStart: string;
  meals: Array<MealRow & { local_day: string }>;
  calorieGoal: number | null;
  proteinGoal: number | null;
}) {
  const days = new Set(input.meals.map((meal) => meal.local_day));
  const status = input.meals.length >= 3 ? "ready" : "insufficient_data";
  const repeated = mostRepeatedMeal(input.meals);
  const slot = highestVarianceSlot(input.meals);
  const avgCalories = average(input.meals.map((meal) => Number(meal.calories_kcal ?? 0)));
  const proteinHitRate = targetHitRate(input.meals, input.proteinGoal, "protein_g");

  return [
    insight(input, "protein_target_hit_rate", "Protein consistency", proteinSummary(proteinHitRate, input.proteinGoal), {
      hit_rate: proteinHitRate,
      target_g: input.proteinGoal,
    }, status),
    insight(input, "most_repeated_meal", "Reliable repeat", repeated.summary, repeated.payload, status),
    insight(input, "highest_variance_meal_slot", "Most flexible meal slot", slot.summary, slot.payload, status),
    insight(input, "logging_streak", "Logging rhythm", `${days.size} day${days.size === 1 ? "" : "s"} had meals logged this week.`, {
      logged_days: days.size,
      meal_count: input.meals.length,
    }, status),
    insight(input, "average_intake_vs_target", "Average intake", calorieSummary(avgCalories, input.calorieGoal), {
      average_calories_kcal: round(avgCalories),
      target_calories_kcal: input.calorieGoal,
    }, status),
    insight(input, "next_week_suggestion", "Next week", nextWeekSuggestion(proteinHitRate, repeated.title), {
      based_on: {
        protein_hit_rate: proteinHitRate,
        repeated_meal: repeated.title,
      },
    }, status),
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
  const counts = new Map<string, { title: string; count: number }>();
  for (const meal of meals) {
    const key = meal.title.trim().toLowerCase();
    if (!key) continue;
    const current = counts.get(key) ?? { title: meal.title, count: 0 };
    current.count += 1;
    counts.set(key, current);
  }
  const top = [...counts.values()].sort((a, b) => b.count - a.count)[0];
  if (!top) return { title: null, summary: "No repeated meal stood out yet.", payload: { title: null, count: 0 } };
  return {
    title: top.title,
    summary: `${top.title} appeared ${top.count} time${top.count === 1 ? "" : "s"} this week.`,
    payload: { title: top.title, count: top.count },
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
    .map(([slotName, values]) => ({ slotName, variance: variance(values), count: values.length }))
    .sort((a, b) => b.variance - a.variance)[0];
  if (!top || top.count < 2) {
    return { summary: "Meal timing is still settling; a pattern will appear with more logs.", payload: { meal_type: null } };
  }
  return {
    summary: `${label(top.slotName)} varied the most this week, which is a good place to review portions first.`,
    payload: { meal_type: top.slotName, variance: round(top.variance), sample_count: top.count },
  };
}

function targetHitRate(meals: MealRow[], target: number | null, key: "protein_g") {
  if (!target || meals.length === 0) return null;
  const daily = new Map<string, number>();
  for (const meal of meals as Array<MealRow & { local_day?: string }>) {
    const day = meal.local_day ?? meal.logged_at.slice(0, 10);
    daily.set(day, (daily.get(day) ?? 0) + Number(meal[key] ?? 0));
  }
  if (daily.size === 0) return null;
  const hits = [...daily.values()].filter((value) => value >= target * 0.9).length;
  return round(hits / daily.size);
}

function proteinSummary(hitRate: number | null, target: number | null) {
  if (!target || hitRate == null) return "Set a protein target to unlock this weekly check.";
  const pct = Math.round(hitRate * 100);
  return `Protein landed near target on ${pct}% of logged days.`;
}

function calorieSummary(avgCalories: number, target: number | null) {
  if (!target) return `${round(avgCalories)} kcal average across logged meals this week.`;
  const delta = round(avgCalories - target);
  if (Math.abs(delta) < 75) return "Average intake stayed close to your target this week.";
  if (delta > 0) return `Average intake was ${delta} kcal above target on logged days.`;
  return `Average intake was ${Math.abs(delta)} kcal below target on logged days.`;
}

function nextWeekSuggestion(hitRate: number | null, repeatedTitle: string | null) {
  if (hitRate != null && hitRate < 0.5) return "Try anchoring one regular meal with a protein you already like.";
  if (repeatedTitle) return `Keep ${repeatedTitle} handy as a quick repeat log when the week gets busy.`;
  return "Log one familiar meal a few times next week to make repeat tracking faster.";
}

function weekStartDate(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) throw new ApiError("INVALID_INPUT", "week_start is invalid", 400, false);
  const day = date.getUTCDay();
  const diff = day === 0 ? -6 : 1 - day;
  date.setUTCDate(date.getUTCDate() + diff);
  return date.toISOString().slice(0, 10);
}

function localDay(value: string, timezone: string) {
  try {
    const parts = new Intl.DateTimeFormat("en-CA", {
      timeZone: timezone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).formatToParts(new Date(value));
    return `${parts.find((part) => part.type === "year")?.value}-${parts.find((part) => part.type === "month")?.value}-${parts.find((part) => part.type === "day")?.value}`;
  } catch (_) {
    return value.slice(0, 10);
  }
}

function requiredString(value: unknown, field: string) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new ApiError("INVALID_INPUT", `${field} is required`, 400, false, { field });
  }
  return value.trim();
}

function optionalString(value: unknown) {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : null;
}

function boundedLimit(value: unknown) {
  const n = Number(value ?? 500);
  if (!Number.isFinite(n)) return 500;
  return Math.max(1, Math.min(Math.trunc(n), 5000));
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
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
  return value.replaceAll("_", " ").replace(/^\w/, (char) => char.toUpperCase());
}
