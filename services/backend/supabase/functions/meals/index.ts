import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { requireString } from "../_shared/validation.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    const user = await requireUser(req);
    const client = serviceClient();
    const url = new URL(req.url);
    const mealId = mealIdFromPath(url.pathname);

    if (req.method === "GET" && mealId == null) {
      const day = url.searchParams.get("day");
      const limit = Math.min(Math.max(Number(url.searchParams.get("limit") ?? 50), 1), 100);
      let query = client
        .from("meals")
        .select("*, meal_items(*)")
        .eq("user_id", user.id)
        .is("deleted_at", null)
        .order("logged_at", { ascending: false })
        .limit(limit);

      if (day) {
        const start = new Date(`${day}T00:00:00.000Z`);
        if (Number.isNaN(start.getTime())) {
          throw new ApiError("INVALID_INPUT", "day must be a valid date", 400, false);
        }
        const end = new Date(start);
        end.setUTCDate(end.getUTCDate() + 1);
        query = query.gte("logged_at", start.toISOString()).lt("logged_at", end.toISOString());
      }

      const { data: meals, error } = await query;
      if (error) throw error;

      const rollupQuery = client.from("daily_rollups").select("*").eq("user_id", user.id);
      if (day) rollupQuery.eq("day", day);
      const { data: dailyRollups, error: rollupError } = await rollupQuery;
      if (rollupError) throw rollupError;

      return jsonResponse({
        meals: (meals ?? []).map(normalizeMealRow),
        daily_rollups: dailyRollups ?? [],
        server_time: new Date().toISOString(),
        request_id: requestId,
      });
    }

    if (req.method === "GET" && mealId != null) {
      const meal = await readMeal(client, user.id, mealId);
      return jsonResponse({
        meal,
        daily_rollup: await readRollupForMeal(client, user.id, meal),
        server_time: new Date().toISOString(),
        request_id: requestId,
      });
    }

    if (req.method === "POST" || req.method === "PATCH") {
      const bodyText = await req.text();
      const body = parseJsonBody(bodyText);
      const clientRequestId = requireString(body.client_request_id, "client_request_id");
      const idempotencyKey = req.headers.get("idempotency-key") ?? clientRequestId;
      const endpoint = req.method === "POST" ? "meals:create" : `meals:update:${mealId}`;
      const replay = await maybeReplayIdempotency(client, user.id, endpoint, idempotencyKey, bodyText);
      if (replay) return jsonResponse(replay.response_body, replay.response_status ?? 200);

      if (req.method === "PATCH" && mealId == null) {
        throw new ApiError("INVALID_INPUT", "meal_id is required", 400, false);
      }
      validateMealWrite(body);

      const { data, error } = await client.rpc("upsert_user_meal", {
        p_user_id: user.id,
        p_meal_id: mealId ?? body.id ?? null,
        p_meal: body,
        p_items: body.items,
        p_expected_revision: body.expected_revision ?? null,
      });
      if (error) throw mapPostgresError(error);

      const responseBody = {
        meal: data.meal,
        daily_rollup: data.daily_rollup,
        correction_events: [],
        server_time: new Date().toISOString(),
        request_id: requestId,
      };
      await storeIdempotency(client, user.id, endpoint, idempotencyKey, bodyText, 200, responseBody);
      return jsonResponse(responseBody);
    }

    if (req.method === "DELETE") {
      if (mealId == null) throw new ApiError("INVALID_INPUT", "meal_id is required", 400, false);
      const bodyText = await req.text();
      const body = parseJsonBody(bodyText || "{}");
      const clientRequestId = requireString(body.client_request_id, "client_request_id");
      const idempotencyKey = req.headers.get("idempotency-key") ?? clientRequestId;
      const endpoint = `meals:delete:${mealId}`;
      const replay = await maybeReplayIdempotency(client, user.id, endpoint, idempotencyKey, bodyText);
      if (replay) return jsonResponse(replay.response_body, replay.response_status ?? 200);

      const { data, error } = await client.rpc("delete_user_meal", {
        p_user_id: user.id,
        p_meal_id: mealId,
        p_expected_revision: body.expected_revision ?? null,
      });
      if (error) throw mapPostgresError(error);

      const responseBody = {
        meal: data.meal,
        daily_rollup: data.daily_rollup,
        correction_events: [],
        server_time: new Date().toISOString(),
        request_id: requestId,
      };
      await storeIdempotency(client, user.id, endpoint, idempotencyKey, bodyText, 200, responseBody);
      return jsonResponse(responseBody);
    }

    throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function mealIdFromPath(pathname: string) {
  const parts = pathname.split("/").filter(Boolean);
  const mealsIndex = parts.lastIndexOf("meals");
  if (mealsIndex < 0 || parts.length <= mealsIndex + 1) return null;
  return parts[mealsIndex + 1];
}

function parseJsonBody(bodyText: string): Record<string, unknown> {
  if (!bodyText) return {};
  try {
    return JSON.parse(bodyText);
  } catch (_) {
    throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
  }
}

function validateMealWrite(body: Record<string, unknown>) {
  requireString(body.client_id, "client_id");
  requireString(body.title, "title");
  requireString(body.meal_type, "meal_type");
  requireString(body.source, "source");
  requireString(body.logged_at, "logged_at");
  requireString(body.timezone, "timezone");
  if (!Array.isArray(body.items) || body.items.length === 0) {
    throw new ApiError("INVALID_INPUT", "items must contain at least one item", 400, false);
  }
  for (const item of body.items) {
    if (!isRecord(item)) throw new ApiError("INVALID_INPUT", "items must be objects", 400, false);
    requireString(item.client_id, "items.client_id");
    requireString(item.name, "items.name");
    requireString(item.unit, "items.unit");
    requireNumber(item.quantity, "items.quantity", true);
    requireNumber(item.calories_kcal, "items.calories_kcal");
    requireNumber(item.protein_g, "items.protein_g");
    requireNumber(item.carbs_g, "items.carbs_g");
    requireNumber(item.fat_g, "items.fat_g");
  }
}

function requireNumber(value: unknown, field: string, positive = false) {
  if (typeof value !== "number" || Number.isNaN(value) || (positive ? value <= 0 : value < 0)) {
    throw new ApiError("INVALID_INPUT", `${field} is invalid`, 400, false);
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

async function readMeal(client: ReturnType<typeof serviceClient>, userId: string, mealId: string) {
  const { data, error } = await client
    .from("meals")
    .select("*, meal_items(*)")
    .eq("user_id", userId)
    .eq("id", mealId)
    .maybeSingle();
  if (error) throw error;
  if (!data) throw new ApiError("NOT_FOUND", "Meal not found", 404, false);
  return normalizeMealRow(data);
}

async function readRollupForMeal(client: ReturnType<typeof serviceClient>, userId: string, meal: Record<string, unknown>) {
  const loggedAt = new Date(meal.logged_at as string);
  const day = loggedAt.toISOString().slice(0, 10);
  const { data, error } = await client
    .from("daily_rollups")
    .select("*")
    .eq("user_id", userId)
    .eq("day", day)
    .maybeSingle();
  if (error) throw error;
  return data;
}

function normalizeMealRow(row: Record<string, unknown>) {
  const items = Array.isArray(row.meal_items) ? [...row.meal_items] : [];
  const { meal_items: _mealItems, ...meal } = row;
  return {
    ...meal,
    items: items.sort((a, b) => {
      const left = isRecord(a) ? Number(a.position ?? 0) : 0;
      const right = isRecord(b) ? Number(b.position ?? 0) : 0;
      return left - right;
    }),
  };
}

async function maybeReplayIdempotency(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  endpoint: string,
  key: string,
  bodyText: string,
) {
  const requestHash = await sha256Hex(bodyText);
  const { data: previous, error } = await client
    .from("api_idempotency")
    .select("request_hash, response_status, response_body")
    .eq("user_id", userId)
    .eq("endpoint", endpoint)
    .eq("key", key)
    .maybeSingle();
  if (error) throw error;
  if (!previous) return null;
  if (previous.request_hash !== requestHash) {
    throw new ApiError("IDEMPOTENCY_CONFLICT", "Idempotency key was reused with a different request body", 409, false);
  }
  return previous;
}

async function storeIdempotency(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  endpoint: string,
  key: string,
  bodyText: string,
  responseStatus: number,
  responseBody: Record<string, unknown>,
) {
  const { error } = await client.from("api_idempotency").insert({
    user_id: userId,
    endpoint,
    key,
    request_hash: await sha256Hex(bodyText),
    response_status: responseStatus,
    response_body: responseBody,
  });
  if (error) throw error;
}

async function sha256Hex(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function mapPostgresError(error: { message?: string; code?: string }) {
  if (error.code === "22023") {
    return new ApiError("INVALID_INPUT", error.message ?? "Invalid input", 400, false);
  }
  if (error.code === "40001") {
    return new ApiError("CONFLICT", error.message ?? "Revision conflict", 409, false);
  }
  if (error.code === "02000") {
    return new ApiError("NOT_FOUND", error.message ?? "Meal not found", 404, false);
  }
  return error;
}
