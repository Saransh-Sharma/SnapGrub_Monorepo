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
    const client = serviceClient();
    const idempotencyKey = req.headers.get("idempotency-key") ?? clientRequestId;
    const endpoint = "exports:create";
    const replay = await maybeReplayIdempotency(client, user.id, endpoint, idempotencyKey, bodyText);
    if (replay) return jsonResponse(replay.response_body, replay.response_status ?? 202);

    const payload = {
      user_id: user.id,
      client_request_id: clientRequestId,
      export_type: exportType(body.export_type),
      status: "queued",
      filters: isRecord(body.filters) ? body.filters : {},
    };
    const { data, error } = await client
      .from("export_requests")
      .insert(payload)
      .select()
      .single();
    if (error) throw mapPostgresError(error);

    const responseBody = {
      export_request: data,
      server_time: new Date().toISOString(),
      request_id: requestId,
    };
    await storeIdempotency(client, user.id, endpoint, idempotencyKey, bodyText, 202, responseBody);
    return jsonResponse(responseBody, 202);
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

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function exportType(value: unknown) {
  const type = value == null ? "journal_csv" : String(value);
  if (!["journal_csv", "nutrition_json"].includes(type)) {
    throw new ApiError("INVALID_INPUT", "export_type is invalid", 400, false, { field: "export_type" });
  }
  return type;
}

function mapPostgresError(error: { message?: string; code?: string }) {
  if (error.code === "23505") {
    return new ApiError("IDEMPOTENCY_CONFLICT", error.message ?? "Export request already exists", 409, false);
  }
  if (error.code === "23514" || error.code === "22P02") {
    return new ApiError("INVALID_INPUT", error.message ?? "Invalid export request", 400, false);
  }
  return error;
}

