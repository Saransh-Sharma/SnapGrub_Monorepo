import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import {
  ApiError,
  errorBody,
  errorStatus,
  logError,
} from "../_shared/errors.ts";
import { requireMethod, requireServiceRole } from "../_shared/request.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { buildInsights, type MealRow } from "./insight_builder.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    requireMethod(req, "POST");
    requireServiceRole(req);

    const body = await parseBody(req);
    const weekStart = weekStartDate(
      optionalString(body.week_start) ?? new Date().toISOString(),
    );
    const userId = optionalString(body.user_id);
    const limit = boundedLimit(body.limit);
    const client = serviceClient();
    const jobRun = await startJobRun(
      client,
      "weekly-insights-generate",
      requestId,
    );

    try {
      if (!userId) {
        const { data: dueUsers, error: dueError } = await client.rpc(
          "users_due_for_weekly_insights",
          {
            p_week_start: weekStart,
            p_limit: limit,
          },
        );
        if (dueError) throw dueError;

        const generated = [];
        const failures: Array<
          { user_id: string; error_code: string; message: string }
        > = [];
        for (const dueUser of dueUsers ?? []) {
          const dueUserId = String(dueUser.user_id);
          try {
            generated.push(
              ...await generateForUser(client, dueUserId, weekStart),
            );
          } catch (error) {
            failures.push({
              user_id: dueUserId,
              error_code: error instanceof ApiError ? error.code : "UNKNOWN",
              message: error instanceof Error ? error.message : "Unknown error",
            });
            logError("weekly-insights-generate.user", requestId, error, {
              user_id: dueUserId,
            });
          }
        }

        const responseBody = {
          weekly_insights: generated,
          processed_users: dueUsers?.length ?? 0,
          succeeded_users: (dueUsers?.length ?? 0) - failures.length,
          failed_users: failures.length,
          failures,
          server_time: new Date().toISOString(),
          request_id: requestId,
        };
        await completeJobRun(
          client,
          jobRun.id,
          failures.length === 0 ? "completed" : "failed",
          {
            processed_users: responseBody.processed_users,
            succeeded_users: responseBody.succeeded_users,
            failed_users: responseBody.failed_users,
            insight_count: generated.length,
          },
          failures.length === 0 ? {} : { failures },
        );
        return jsonResponse(responseBody);
      }

      const data = await generateForUser(client, userId, weekStart);
      await completeJobRun(client, jobRun.id, "completed", {
        processed_users: 1,
        succeeded_users: 1,
        insight_count: data.length,
      });

      return jsonResponse({
        weekly_insights: data,
        server_time: new Date().toISOString(),
        request_id: requestId,
      });
    } catch (error) {
      await completeJobRun(
        client,
        jobRun.id,
        "failed",
        {},
        errorSummary(error),
      );
      throw error;
    }
  } catch (error) {
    logError("weekly-insights-generate", requestId, error);
    return jsonResponse(errorBody(error, requestId), errorStatus(error));
  }
});

async function generateForUser(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  weekStart: string,
) {
  const { data: profile, error: profileError } = await client
    .from("profiles")
    .select("id, timezone")
    .eq("id", userId)
    .maybeSingle();
  if (profileError) throw profileError;
  if (!profile) {
    throw new ApiError("NOT_FOUND", "Profile not found", 404, false);
  }

  const { data: goal, error: goalError } = await client
    .from("nutrition_goals")
    .select("*")
    .eq("user_id", userId)
    .eq("is_active", true)
    .maybeSingle();
  if (goalError) throw goalError;

  const meals = await readMeals(
    client,
    userId,
    weekStart,
    String(profile.timezone ?? "UTC"),
  );
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

async function parseBody(req: Request): Promise<Record<string, unknown>> {
  try {
    return await req.json();
  } catch (_) {
    throw new ApiError(
      "INVALID_INPUT",
      "Request body must be valid JSON",
      400,
      false,
    );
  }
}

async function readMeals(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  weekStart: string,
  timezone: string,
) {
  const start = localDateStartUtc(weekStart, timezone);
  const end = localDateStartUtc(addDays(weekStart, 7), timezone);

  const { data, error } = await client
    .from("meals")
    .select(
      "id,title,meal_type,logged_at,calories_kcal,protein_g,carbs_g,fat_g,deleted_at",
    )
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

function localDateStartUtc(date: string, timezone: string) {
  const [year, month, day] = date.split("-").map(Number);
  const approximateUtc = new Date(Date.UTC(year, month - 1, day, 0, 0, 0));
  try {
    const localParts = new Intl.DateTimeFormat("en-CA", {
      timeZone: timezone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hourCycle: "h23",
    }).formatToParts(approximateUtc);
    const part = (type: string) =>
      Number(localParts.find((item) => item.type === type)?.value ?? 0);
    const renderedAsUtc = Date.UTC(
      part("year"),
      part("month") - 1,
      part("day"),
      part("hour"),
      part("minute"),
      part("second"),
    );
    const targetAsUtc = Date.UTC(year, month - 1, day, 0, 0, 0);
    return new Date(approximateUtc.getTime() + targetAsUtc - renderedAsUtc);
  } catch (_) {
    return approximateUtc;
  }
}

function addDays(date: string, days: number) {
  const value = new Date(`${date}T00:00:00.000Z`);
  value.setUTCDate(value.getUTCDate() + days);
  return value.toISOString().slice(0, 10);
}

function weekStartDate(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new ApiError("INVALID_INPUT", "week_start is invalid", 400, false);
  }
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
    return `${parts.find((part) => part.type === "year")?.value}-${
      parts.find((part) => part.type === "month")?.value
    }-${parts.find((part) => part.type === "day")?.value}`;
  } catch (_) {
    return value.slice(0, 10);
  }
}

function optionalString(value: unknown) {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

function boundedLimit(value: unknown) {
  const n = Number(value ?? 500);
  if (!Number.isFinite(n)) return 500;
  return Math.max(1, Math.min(Math.trunc(n), 5000));
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

async function startJobRun(
  client: ReturnType<typeof serviceClient>,
  jobName: string,
  requestId: string,
) {
  const { data, error } = await client
    .from("job_runs")
    .insert({ job_name: jobName, request_id: requestId, status: "running" })
    .select("id")
    .single();
  if (error) throw error;
  return data;
}

async function completeJobRun(
  client: ReturnType<typeof serviceClient>,
  id: string,
  status: "completed" | "failed",
  counts: Record<string, unknown>,
  errorSummaryPayload: Record<string, unknown> = {},
) {
  const { error } = await client
    .from("job_runs")
    .update({
      status,
      completed_at: new Date().toISOString(),
      counts,
      error_summary: errorSummaryPayload,
    })
    .eq("id", id);
  if (error) throw error;
}

function errorSummary(error: unknown) {
  return {
    message: error instanceof Error ? error.message : "Unknown error",
  };
}
