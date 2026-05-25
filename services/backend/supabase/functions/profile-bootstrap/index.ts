import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { isRecord } from "../_shared/request.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import {
  assertPlatform,
  optionalString,
  requireString,
} from "../_shared/validation.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    }

    const user = await requireUser(req);
    const body = await req.json().catch(() => ({}));
    const installId = requireString(body.install_id, "install_id");
    const platform = requireString(body.platform, "platform");
    assertPlatform(platform);

    const locale = optionalString(body.locale) ?? "en-US";
    const timezone = requireString(body.timezone, "timezone");
    const client = serviceClient();

    const { data: existingProfile, error: profileReadError } = await client
      .from("profiles")
      .select("*")
      .eq("id", user.id)
      .maybeSingle();
    if (profileReadError) throw profileReadError;

    let profile = existingProfile;
    if (!profile) {
      const { data, error } = await client
        .from("profiles")
        .insert({
          id: user.id,
          display_name: user.user_metadata?.full_name ?? null,
          locale,
          timezone,
          unit_system: "metric",
        })
        .select("*")
        .single();
      if (error) throw error;
      profile = data;
    } else if (
      profile.locale !== locale ||
      profile.timezone !== timezone
    ) {
      const { data, error } = await client
        .from("profiles")
        .update({ locale, timezone })
        .eq("id", user.id)
        .select("*")
        .single();
      if (error) throw error;
      profile = data;
    }

    const { data: existingDevice, error: existingDeviceError } = await client
      .from("devices")
      .select("id,user_id")
      .eq("install_id", installId)
      .maybeSingle();
    if (existingDeviceError) throw existingDeviceError;
    if (existingDevice && existingDevice.user_id !== user.id) {
      throw new ApiError(
        "CONFLICT",
        "install_id is already registered to another user",
        409,
        false,
      );
    }

    const devicePayload = {
      user_id: user.id,
      install_id: installId,
      platform,
      app_version: optionalString(body.app_version),
      build_number: optionalString(body.build_number),
      last_seen_at: new Date().toISOString(),
    };
    const device = existingDevice
      ? await updateDevice(client, String(existingDevice.id), devicePayload)
      : await insertDevice(client, user.id, installId, devicePayload);

    const { data: activeGoal, error: goalError } = await client
      .from("nutrition_goals")
      .select("*")
      .eq("user_id", user.id)
      .eq("is_active", true)
      .maybeSingle();
    if (goalError) throw goalError;

    const { data: flags, error: flagsError } = await client
      .from("feature_flags")
      .select("key, enabled, rollout_percent, rules")
      .order("key");
    if (flagsError) throw flagsError;

    const { data: overrides, error: overridesError } = await client
      .from("feature_flag_overrides")
      .select("flag_key, forced_value")
      .eq("scope_type", "user")
      .eq("scope_id", user.id);
    if (overridesError) throw overridesError;

    const featureFlags: Record<string, unknown> = {};
    for (const flag of flags ?? []) {
      featureFlags[flag.key] = resolveFlag(flag, {
        userId: user.id,
        installId,
        platform,
        appVersion: optionalString(body.app_version),
        buildNumber: optionalString(body.build_number),
        buildEnv: optionalString(body.build_env),
        countryCode: typeof profile?.country_code === "string"
          ? profile.country_code
          : null,
      });
    }
    for (const override of overrides ?? []) {
      featureFlags[override.flag_key] = override.forced_value;
    }

    return jsonResponse({
      profile,
      active_goal: activeGoal,
      device,
      feature_flags: featureFlags,
      server_time: new Date().toISOString(),
      request_id: requestId,
    });
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

async function updateDevice(
  client: ReturnType<typeof serviceClient>,
  id: string,
  devicePayload: Record<string, unknown>,
) {
  const { data, error } = await client
    .from("devices")
    .update(devicePayload)
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

async function insertDevice(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  installId: string,
  devicePayload: Record<string, unknown>,
) {
  const { data, error } = await client
    .from("devices")
    .insert(devicePayload)
    .select("*")
    .single();
  if (!error) return data;
  if (error.code !== "23505") throw error;

  const { data: existing, error: readError } = await client
    .from("devices")
    .select("id,user_id")
    .eq("install_id", installId)
    .maybeSingle();
  if (readError) throw readError;
  if (!existing || existing.user_id !== userId) {
    throw new ApiError(
      "CONFLICT",
      "install_id is already registered to another user",
      409,
      false,
    );
  }
  return await updateDevice(client, String(existing.id), devicePayload);
}

type FlagContext = {
  userId: string;
  installId: string;
  platform: string;
  appVersion: string | null;
  buildNumber: string | null;
  buildEnv: string | null;
  countryCode: string | null;
};

function resolveFlag(flag: Record<string, unknown>, context: FlagContext) {
  if (flag.enabled !== true) return false;
  if (!matchesRules(flag.rules, context)) return false;
  const rolloutPercent = Number(flag.rollout_percent ?? 100);
  if (!Number.isFinite(rolloutPercent)) return false;
  if (rolloutPercent >= 100) return true;
  if (rolloutPercent <= 0) return false;
  return rolloutBucket(`${flag.key}:${context.userId}:${context.installId}`) <
    rolloutPercent;
}

function matchesRules(rules: unknown, context: FlagContext) {
  if (!isRecord(rules)) return true;
  return matchesRuleValue(rules.platform, context.platform) &&
    matchesRuleValue(rules.build_env, context.buildEnv) &&
    matchesRuleValue(rules.country_code, context.countryCode) &&
    matchesMinVersion(rules.app_version_min, context.appVersion) &&
    matchesMaxVersion(rules.app_version_max, context.appVersion) &&
    matchesMinBuild(rules.build_number_min, context.buildNumber) &&
    matchesMaxBuild(rules.build_number_max, context.buildNumber);
}

function matchesRuleValue(rule: unknown, value: string | null) {
  if (rule == null) return true;
  if (typeof rule === "string") return value === rule;
  if (Array.isArray(rule)) {
    return value != null && rule.map(String).includes(value);
  }
  return false;
}

function matchesMinVersion(rule: unknown, value: string | null) {
  if (rule == null) return true;
  if (typeof rule !== "string" || value == null) return false;
  return compareVersion(value, rule) >= 0;
}

function matchesMaxVersion(rule: unknown, value: string | null) {
  if (rule == null) return true;
  if (typeof rule !== "string" || value == null) return false;
  return compareVersion(value, rule) <= 0;
}

function matchesMinBuild(rule: unknown, value: string | null) {
  if (rule == null) return true;
  const ruleNumber = Number(rule);
  const valueNumber = Number(value);
  return Number.isFinite(ruleNumber) && Number.isFinite(valueNumber) &&
    valueNumber >= ruleNumber;
}

function matchesMaxBuild(rule: unknown, value: string | null) {
  if (rule == null) return true;
  const ruleNumber = Number(rule);
  const valueNumber = Number(value);
  return Number.isFinite(ruleNumber) && Number.isFinite(valueNumber) &&
    valueNumber <= ruleNumber;
}

function compareVersion(left: string, right: string) {
  const leftParts = left.split(".").map((part) =>
    Number(part.replace(/\D.*$/, "")) || 0
  );
  const rightParts = right.split(".").map((part) =>
    Number(part.replace(/\D.*$/, "")) || 0
  );
  const length = Math.max(leftParts.length, rightParts.length);
  for (let index = 0; index < length; index += 1) {
    const delta = (leftParts[index] ?? 0) - (rightParts[index] ?? 0);
    if (delta !== 0) return delta;
  }
  return 0;
}

function rolloutBucket(value: string) {
  let hash = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0) % 100;
}
