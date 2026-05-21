import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { assertPlatform, optionalString, requireString } from "../_shared/validation.ts";

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
    }

    const { data: device, error: deviceError } = await client
      .from("devices")
      .upsert({
        user_id: user.id,
        install_id: installId,
        platform,
        app_version: optionalString(body.app_version),
        build_number: optionalString(body.build_number),
        last_seen_at: new Date().toISOString(),
      }, { onConflict: "install_id" })
      .select("*")
      .single();
    if (deviceError) throw deviceError;

    const { data: activeGoal, error: goalError } = await client
      .from("nutrition_goals")
      .select("*")
      .eq("user_id", user.id)
      .eq("is_active", true)
      .maybeSingle();
    if (goalError) throw goalError;

    const { data: flags, error: flagsError } = await client
      .from("feature_flags")
      .select("key, enabled")
      .order("key");
    if (flagsError) throw flagsError;

    const { data: overrides, error: overridesError } = await client
      .from("feature_flag_overrides")
      .select("flag_key, forced_value")
      .eq("scope_type", "user")
      .eq("scope_id", user.id);
    if (overridesError) throw overridesError;

    const featureFlags: Record<string, unknown> = {};
    for (const flag of flags ?? []) featureFlags[flag.key] = flag.enabled;
    for (const override of overrides ?? []) featureFlags[override.flag_key] = override.forced_value;

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
