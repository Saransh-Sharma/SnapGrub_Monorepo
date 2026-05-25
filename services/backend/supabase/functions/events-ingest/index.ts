import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { maybeReplayIdempotency, storeIdempotency } from "../_shared/idempotency.ts";
import { parseJsonBody } from "../_shared/request.ts";
import { anonClient, serviceClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    }

    const { body, bodyText } = await parseJsonBody(req);
    if (!Array.isArray(body.events) || body.events.length === 0 || body.events.length > 50) {
      throw new ApiError("INVALID_INPUT", "events must contain 1 to 50 items", 400);
    }

    const token = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
    let userId: string | null = null;
    if (token) {
      const { data } = await anonClient().auth.getUser(token);
      userId = data.user?.id ?? null;
    }
    const client = serviceClient();
    const clientRequestId = typeof body.client_request_id === "string" ? body.client_request_id : null;
    const idempotencyKey = req.headers.get("idempotency-key") ?? clientRequestId;
    if (userId && idempotencyKey) {
      const replay = await maybeReplayIdempotency(client, userId, "events-ingest", idempotencyKey, bodyText);
      if (replay) return jsonResponse(replay.response_body, replay.response_status ?? 200);
    }

    const rows = body.events.map((event: Record<string, unknown>) => {
      if (typeof event.event_name !== "string" || event.event_name.length === 0 || event.event_name.length > 80) {
        throw new ApiError("INVALID_INPUT", "event_name is required", 400);
      }
      if (!/^[a-z0-9_]+$/.test(event.event_name)) {
        throw new ApiError("INVALID_INPUT", "event_name must be snake_case", 400);
      }
      if (event.properties != null && !isPlainObject(event.properties)) {
        throw new ApiError("INVALID_INPUT", "properties must be an object", 400);
      }
      if (event.device_id != null && typeof event.device_id !== "string") {
        throw new ApiError("INVALID_INPUT", "device_id must be a string", 400);
      }
      const occurredAt = parseOccurredAt(event.occurred_at);
      return {
        user_id: userId,
        device_id: event.device_id ?? null,
        event_name: event.event_name,
        properties: event.properties ?? {},
        occurred_at: occurredAt,
      };
    });

    const { error } = await client.from("analytics_events").insert(rows);
    if (error) throw error;

    const responseBody = { accepted: rows.length, request_id: requestId };
    if (userId && idempotencyKey) {
      await storeIdempotency(client, userId, "events-ingest", idempotencyKey, bodyText, 200, responseBody);
    }

    return jsonResponse(responseBody);
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function parseOccurredAt(value: unknown) {
  if (value == null) return new Date().toISOString();
  if (typeof value !== "string") {
    throw new ApiError("INVALID_INPUT", "occurred_at must be an ISO timestamp", 400);
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new ApiError("INVALID_INPUT", "occurred_at must be an ISO timestamp", 400);
  }
  return parsed.toISOString();
}
