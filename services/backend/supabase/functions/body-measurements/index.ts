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
    const client = serviceClient();
    const idempotencyKey = req.headers.get("idempotency-key") ?? clientRequestId;
    const endpoint = "body-measurements:create";
    const payload = {
      user_id: user.id,
      measured_at: timestampOrNow(body.measured_at),
      weight_kg: optionalRange(body.weight_kg, "weight_kg", 20, 400),
      body_fat_pct: optionalRange(body.body_fat_pct, "body_fat_pct", 2, 80),
      source: sourceValue(body.source),
    };
    if (payload.weight_kg == null && payload.body_fat_pct == null) {
      throw new ApiError("INVALID_INPUT", "weight_kg or body_fat_pct is required", 400, false);
    }
    const replay = await maybeReplayIdempotency(client, user.id, endpoint, idempotencyKey, bodyText);
    if (replay) return jsonResponse(replay.response_body, replay.response_status ?? 200);

    const { data, error } = await client
      .from("body_measurements")
      .insert(payload)
      .select()
      .single();
    if (error) throw mapPostgresError(error);

    const responseBody = {
      body_measurement: data,
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

function timestampOrNow(value: unknown) {
  if (value == null) return new Date().toISOString();
  if (typeof value !== "string" || Number.isNaN(new Date(value).getTime())) {
    throw new ApiError("INVALID_INPUT", "measured_at must be an ISO timestamp", 400, false, { field: "measured_at" });
  }
  return new Date(value).toISOString();
}

function optionalRange(value: unknown, field: string, min: number, max: number) {
  if (value == null) return null;
  if (typeof value !== "number" || Number.isNaN(value) || value < min || value > max) {
    throw new ApiError("INVALID_INPUT", `${field} is out of range`, 400, false, { field, min, max });
  }
  return value;
}

function sourceValue(value: unknown) {
  const source = value == null ? "manual" : String(value);
  if (!["manual", "onboarding", "imported"].includes(source)) {
    throw new ApiError("INVALID_INPUT", "source is invalid", 400, false, { field: "source" });
  }
  return source;
}

function mapPostgresError(error: { message?: string; code?: string }) {
  if (error.code === "23514" || error.code === "22P02") {
    return new ApiError("INVALID_INPUT", error.message ?? "Invalid body measurement", 400, false);
  }
  return error;
}
