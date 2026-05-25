import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import {
  maybeReplayIdempotency,
  storeIdempotency,
} from "../_shared/idempotency.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { parseJsonBody } from "../_shared/request.ts";
import { requireString } from "../_shared/validation.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "PATCH") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    }

    const user = await requireUser(req);
    const { body, bodyText } = await parseJsonBody(req);
    requireString(body.client_request_id, "client_request_id");
    validateSettingsPatch(body);

    const client = serviceClient();
    const idempotencyKey = idempotencyKeyFor(
      req,
      String(body.client_request_id),
    );
    const endpoint = "settings-patch";

    const replay = await maybeReplayIdempotency(
      client,
      user.id,
      endpoint,
      String(idempotencyKey),
      bodyText,
    );
    if (replay) {
      return jsonResponse(replay.response_body, replay.response_status ?? 200);
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

    await storeIdempotency(
      client,
      user.id,
      endpoint,
      String(idempotencyKey),
      bodyText,
      200,
      responseBody,
    );

    return jsonResponse(responseBody);
  } catch (error) {
    console.error("settings-patch failed", error);
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function mapPostgresError(error: { message?: string; code?: string }) {
  if (
    error.code === "22023" || error.code === "23514" ||
    error.code === "22P02" || error.code === "22007"
  ) {
    return new ApiError(
      "INVALID_INPUT",
      error.message ?? "Invalid input",
      400,
      false,
    );
  }
  return error;
}

function idempotencyKeyFor(req: Request, clientRequestId: string) {
  const header = req.headers.get("idempotency-key")?.trim();
  return header && header.length > 0 ? header : clientRequestId;
}

function validateSettingsPatch(body: Record<string, unknown>) {
  if (body.profile_patch != null) {
    assertRecord(body.profile_patch, "profile_patch");
    const profile = body.profile_patch as Record<string, unknown>;
    assertOptionalString(profile.display_name, "display_name");
    assertOptionalString(profile.avatar_path, "avatar_path");
    assertOptionalString(profile.locale, "locale");
    assertOptionalString(profile.timezone, "timezone");
    assertOptionalString(profile.country_code, "country_code");
    assertOptionalBoolean(profile.cloud_media_storage, "cloud_media_storage");
    assertOptionalBoolean(profile.save_original_photos, "save_original_photos");
    assertOptionalBoolean(
      profile.ai_improvement_consent,
      "ai_improvement_consent",
    );
    assertOptionalTimestamp(
      profile.onboarding_completed_at,
      "onboarding_completed_at",
    );
  }
  if (body.active_goal_patch != null) {
    assertRecord(body.active_goal_patch, "active_goal_patch");
    const goal = body.active_goal_patch as Record<string, unknown>;
    assertOptionalNumber(goal.calories_kcal, "calories_kcal");
    assertOptionalNumber(goal.protein_g, "protein_g");
    assertOptionalNumber(goal.carbs_g, "carbs_g");
    assertOptionalNumber(goal.fat_g, "fat_g");
    assertOptionalNumber(goal.fiber_g, "fiber_g");
    assertOptionalDate(goal.starts_on, "starts_on");
    assertOptionalDate(goal.ends_on, "ends_on");
  }
  if (body.body_measurement != null) {
    assertRecord(body.body_measurement, "body_measurement");
    const measurement = body.body_measurement as Record<string, unknown>;
    assertOptionalNumber(measurement.weight_kg, "weight_kg");
    assertOptionalNumber(measurement.body_fat_pct, "body_fat_pct");
    assertOptionalTimestamp(measurement.measured_at, "measured_at");
    assertOptionalString(measurement.source, "source");
  }
}

function assertRecord(value: unknown, field: string) {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new ApiError(
      "INVALID_INPUT",
      `${field} must be an object`,
      400,
      false,
      { field },
    );
  }
}

function assertOptionalString(value: unknown, field: string) {
  if (value != null && typeof value !== "string") {
    throw new ApiError(
      "INVALID_INPUT",
      `${field} must be a string`,
      400,
      false,
      { field },
    );
  }
}

function assertOptionalBoolean(value: unknown, field: string) {
  if (value != null && typeof value !== "boolean") {
    throw new ApiError(
      "INVALID_INPUT",
      `${field} must be a boolean`,
      400,
      false,
      { field },
    );
  }
}

function assertOptionalNumber(value: unknown, field: string) {
  if (value != null && (typeof value !== "number" || Number.isNaN(value))) {
    throw new ApiError(
      "INVALID_INPUT",
      `${field} must be a number`,
      400,
      false,
      { field },
    );
  }
}

function assertOptionalTimestamp(value: unknown, field: string) {
  if (
    value != null &&
    (typeof value !== "string" || Number.isNaN(Date.parse(value)))
  ) {
    throw new ApiError(
      "INVALID_INPUT",
      `${field} must be an ISO timestamp`,
      400,
      false,
      { field },
    );
  }
}

function assertOptionalDate(value: unknown, field: string) {
  if (
    value != null &&
    (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value) ||
      Number.isNaN(Date.parse(`${value}T00:00:00.000Z`)))
  ) {
    throw new ApiError(
      "INVALID_INPUT",
      `${field} must be an ISO date`,
      400,
      false,
      { field },
    );
  }
}
