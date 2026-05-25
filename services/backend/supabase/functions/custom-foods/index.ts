import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { maybeReplayIdempotency, storeIdempotency } from "../_shared/idempotency.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { parseJsonBody } from "../_shared/request.ts";
import { requireString } from "../_shared/validation.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    }

    const user = await requireUser(req);
    const { body, bodyText } = await parseJsonBody(req);
    const clientRequestId = requireString(body.client_request_id, "client_request_id");
    const clientId = requireString(body.client_id, "client_id");
    const client = serviceClient();
    const idempotencyKey = req.headers.get("idempotency-key") ?? clientRequestId;
    const endpoint = body.deleted_at == null ? "custom-foods:upsert" : `custom-foods:delete:${clientId}`;
    if (body.deleted_at == null) {
      customFoodPayload(user.id, body);
    } else {
      optionalTimestamp(body.deleted_at);
    }
    const replay = await maybeReplayIdempotency(client, user.id, endpoint, idempotencyKey, bodyText);
    if (replay) return jsonResponse(replay.response_body, replay.response_status ?? 200);

    const data = body.deleted_at == null
      ? await upsertCustomFood(client, user.id, body)
      : await softDeleteCustomFood(client, user.id, body);

    const responseBody = {
      custom_food: data,
      server_time: new Date().toISOString(),
      request_id: requestId,
    };
    await storeIdempotency(client, user.id, endpoint, idempotencyKey, bodyText, 200, responseBody);
    return jsonResponse(responseBody);
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function customFoodPayload(userId: string, body: Record<string, unknown>) {
  const name = body.deleted_at == null ? requireString(body.name, "name") : (body.name as string | undefined);
  return {
    id: optionalUuid(body.id),
    user_id: userId,
    client_id: requireString(body.client_id, "client_id"),
    name: name ?? "Deleted custom food",
    brand: optionalString(body.brand),
    serving_quantity: optionalNumber(body.serving_quantity),
    serving_unit: optionalString(body.serving_unit),
    serving_grams: optionalNumber(body.serving_grams),
    calories_kcal: requiredNonNegative(body.calories_kcal, "calories_kcal", body.deleted_at != null),
    protein_g: requiredNonNegative(body.protein_g, "protein_g", body.deleted_at != null),
    carbs_g: requiredNonNegative(body.carbs_g, "carbs_g", body.deleted_at != null),
    fat_g: requiredNonNegative(body.fat_g, "fat_g", body.deleted_at != null),
    deleted_at: optionalTimestamp(body.deleted_at),
  };
}

async function upsertCustomFood(client: ReturnType<typeof serviceClient>, userId: string, body: Record<string, unknown>) {
  const { data, error } = await client
    .from("custom_foods")
    .upsert(customFoodPayload(userId, body), { onConflict: "user_id,client_id" })
    .select()
    .single();
  if (error) throw mapPostgresError(error);
  return data;
}

async function softDeleteCustomFood(client: ReturnType<typeof serviceClient>, userId: string, body: Record<string, unknown>) {
  const clientId = requireString(body.client_id, "client_id");
  const deletedAt = optionalTimestamp(body.deleted_at);
  const { data, error } = await client
    .from("custom_foods")
    .update({ deleted_at: deletedAt })
    .eq("user_id", userId)
    .eq("client_id", clientId)
    .select()
    .maybeSingle();
  if (error) throw mapPostgresError(error);
  if (data) return data;
  return await upsertCustomFood(client, userId, body);
}

function requiredNonNegative(value: unknown, field: string, allowMissing = false) {
  if (value == null && allowMissing) return 0;
  if (typeof value !== "number" || Number.isNaN(value) || value < 0) {
    throw new ApiError("INVALID_INPUT", `${field} must be a non-negative number`, 400, false, { field });
  }
  return value;
}

function optionalNumber(value: unknown) {
  if (value == null) return null;
  if (typeof value !== "number" || Number.isNaN(value)) {
    throw new ApiError("INVALID_INPUT", "Numeric field is invalid", 400, false);
  }
  return value;
}

function optionalString(value: unknown) {
  if (value == null) return null;
  const trimmed = String(value).trim();
  return trimmed.length === 0 ? null : trimmed;
}

function optionalUuid(value: unknown) {
  return typeof value === "string" && value.trim().length > 0 ? value : undefined;
}

function optionalTimestamp(value: unknown) {
  if (value == null) return null;
  if (typeof value !== "string" || Number.isNaN(new Date(value).getTime())) {
    throw new ApiError("INVALID_INPUT", "deleted_at must be an ISO timestamp", 400, false, { field: "deleted_at" });
  }
  return new Date(value).toISOString();
}

function mapPostgresError(error: { message?: string; code?: string }) {
  if (error.code === "23505") {
    return new ApiError("CONFLICT", error.message ?? "Custom food conflict", 409, false);
  }
  if (error.code === "23514" || error.code === "22P02") {
    return new ApiError("INVALID_INPUT", error.message ?? "Invalid custom food", 400, false);
  }
  return error;
}
