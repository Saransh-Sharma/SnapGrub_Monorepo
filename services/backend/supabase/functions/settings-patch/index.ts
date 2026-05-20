import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { requireString } from "../_shared/validation.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "PATCH") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    }

    const user = await requireUser(req);
    const bodyText = await req.text();
    const body = parseJsonBody(bodyText);
    requireString(body.client_request_id, "client_request_id");

    const client = serviceClient();
    const idempotencyKey = req.headers.get("idempotency-key") ?? body.client_request_id;
    const requestHash = await sha256Hex(bodyText);
    const endpoint = "settings-patch";

    const { data: previous, error: previousError } = await client
      .from("api_idempotency")
      .select("request_hash, response_status, response_body")
      .eq("user_id", user.id)
      .eq("endpoint", endpoint)
      .eq("key", idempotencyKey)
      .maybeSingle();
    if (previousError) throw previousError;

    if (previous) {
      if (previous.request_hash !== requestHash) {
        throw new ApiError(
          "IDEMPOTENCY_CONFLICT",
          "Idempotency key was reused with a different request body",
          409,
          false,
        );
      }
      return jsonResponse(previous.response_body, previous.response_status ?? 200);
    }

    const { data: patched, error: patchError } = await client
      .rpc("patch_user_settings", {
        p_user_id: user.id,
        p_profile_patch: body.profile_patch ?? {},
        p_active_goal_patch: body.active_goal_patch ?? null,
        p_body_measurement: body.body_measurement ?? null,
      });
    if (patchError) throw mapPostgresError(patchError);

    const responseBody = {
      profile: patched.profile,
      active_goal: patched.active_goal,
      body_measurement: patched.body_measurement,
      server_time: new Date().toISOString(),
      request_id: requestId,
    };

    const { error: idempotencyError } = await client
      .from("api_idempotency")
      .insert({
        user_id: user.id,
        endpoint,
        key: idempotencyKey,
        request_hash: requestHash,
        response_status: 200,
        response_body: responseBody,
      });
    if (idempotencyError) throw idempotencyError;

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

async function sha256Hex(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function mapPostgresError(error: { message?: string; code?: string }) {
  if (error.code === "22023") {
    return new ApiError("INVALID_INPUT", error.message ?? "Invalid input", 400, false);
  }
  return error;
}
