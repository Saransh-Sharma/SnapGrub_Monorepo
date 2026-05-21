import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { maybeReplayIdempotency, storeIdempotency } from "../_shared/idempotency.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { requireString } from "../_shared/validation.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    }

    const user = await requireUser(req);
    const bodyText = await req.text();
    const body = parseJsonBody(bodyText);
    const clientRequestId = requireString(body.client_request_id, "client_request_id");
    const clientId = requireString(body.client_id, "client_id");
    const client = serviceClient();
    const idempotencyKey = req.headers.get("idempotency-key") ?? clientRequestId;
    const endpoint = body.deleted_at == null ? "meal-templates:upsert" : `meal-templates:delete:${clientId}`;
    const replay = await maybeReplayIdempotency(client, user.id, endpoint, idempotencyKey, bodyText);
    if (replay) return jsonResponse(replay.response_body, replay.response_status ?? 200);

    const data = body.deleted_at == null
      ? await upsertTemplate(client, user.id, body)
      : await softDeleteTemplate(client, user.id, body);

    const responseBody = {
      meal_template: data,
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

function parseJsonBody(bodyText: string): Record<string, unknown> {
  if (!bodyText) return {};
  try {
    return JSON.parse(bodyText);
  } catch (_) {
    throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
  }
}

function templatePayload(userId: string, body: Record<string, unknown>) {
  const title = body.deleted_at == null ? requireString(body.title, "title") : (body.title as string | undefined);
  return {
    id: optionalUuid(body.id),
    user_id: userId,
    client_id: requireString(body.client_id, "client_id"),
    title: title ?? "Deleted template",
    snapshot: isRecord(body.snapshot) ? body.snapshot : {},
    source_meal_id: optionalString(body.source_meal_id),
    deleted_at: optionalTimestamp(body.deleted_at),
  };
}

async function upsertTemplate(client: ReturnType<typeof serviceClient>, userId: string, body: Record<string, unknown>) {
  const { data, error } = await client
    .from("meal_templates")
    .upsert(templatePayload(userId, body), { onConflict: "user_id,client_id" })
    .select()
    .single();
  if (error) throw mapPostgresError(error);
  return data;
}

async function softDeleteTemplate(client: ReturnType<typeof serviceClient>, userId: string, body: Record<string, unknown>) {
  const clientId = requireString(body.client_id, "client_id");
  const deletedAt = optionalTimestamp(body.deleted_at);
  const { data, error } = await client
    .from("meal_templates")
    .update({ deleted_at: deletedAt })
    .eq("user_id", userId)
    .eq("client_id", clientId)
    .select()
    .maybeSingle();
  if (error) throw mapPostgresError(error);
  if (data) return data;
  return await upsertTemplate(client, userId, body);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
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
    return new ApiError("CONFLICT", error.message ?? "Template conflict", 409, false);
  }
  if (error.code === "23514" || error.code === "22P02") {
    return new ApiError("INVALID_INPUT", error.message ?? "Invalid template", 400, false);
  }
  return error;
}
