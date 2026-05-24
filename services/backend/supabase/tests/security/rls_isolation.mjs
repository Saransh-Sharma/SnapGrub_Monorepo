import { createClient } from "@supabase/supabase-js";

const url =
  process.env.SUPABASE_URL ?? process.env.API_URL ?? "http://127.0.0.1:54321";
const anonKey = process.env.SUPABASE_ANON_KEY ?? process.env.ANON_KEY;
const serviceRoleKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SERVICE_ROLE_KEY;

if (!anonKey || !serviceRoleKey) {
  throw new Error(
    "SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are required.",
  );
}

const admin = createClient(url, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const random = crypto.randomUUID();
const users = [
  { email: `rls-a-${random}@snapgrub.test`, password: `Pass-${random}-A` },
  { email: `rls-b-${random}@snapgrub.test`, password: `Pass-${random}-B` },
];

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function assertNoRows(data, error, message) {
  if (error) {
    throw new Error(`${message}: unexpected error ${JSON.stringify(error)}`);
  }
  assert(Array.isArray(data) && data.length === 0, message);
}

function assertPermissionDenied(error, message) {
  assert(
    error?.code === "42501",
    `${message}: expected 42501, got ${JSON.stringify(error)}`,
  );
}

async function createSignedInUser({ email, password }) {
  const { data: created, error: createError } =
    await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
  if (createError) throw createError;

  const client = createClient(url, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { error: signInError } = await client.auth.signInWithPassword({
    email,
    password,
  });
  if (signInError) throw signInError;

  return { id: created.user.id, client };
}

const cleanupIds = [];

try {
  const userA = await createSignedInUser(users[0]);
  const userB = await createSignedInUser(users[1]);
  cleanupIds.push(userA.id, userB.id);

  const { error: flagError } = await admin.from("feature_flags").upsert({
    key: "rls.test.enabled",
    enabled: true,
    rollout_percent: 100,
    description: "RLS integration test flag",
  });
  if (flagError) throw flagError;

  for (const user of [userA, userB]) {
    const { error: profileError } = await user.client.from("profiles").insert({
      id: user.id,
      display_name: `User ${user.id.slice(0, 4)}`,
      timezone: "UTC",
      unit_system: "metric",
    });
    if (profileError) throw profileError;

    const { error: goalError } = await user.client
      .from("nutrition_goals")
      .insert({
        user_id: user.id,
        goal_type: "lose",
        calories_kcal: 1900,
        protein_g: 130,
        carbs_g: 190,
        fat_g: 60,
      });
    if (goalError) throw goalError;

    const { error: measurementError } = await admin
      .from("body_measurements")
      .insert({
        user_id: user.id,
        weight_kg: 82,
        source: "manual",
      });
    if (measurementError) throw measurementError;

    const { error: deviceError } = await user.client.from("devices").insert({
      user_id: user.id,
      install_id: `${user.id}-install`,
      platform: "ios",
    });
    if (deviceError) throw deviceError;

    const { data: meal, error: mealError } = await admin
      .from("meals")
      .insert({
        user_id: user.id,
        client_id: `${user.id}-meal`,
        title: "Manual lunch",
        meal_type: "lunch",
        source: "manual",
        logged_at: new Date().toISOString(),
        timezone: "UTC",
        calories_kcal: 300,
        protein_g: 20,
        carbs_g: 35,
        fat_g: 8,
      })
      .select("*")
      .single();
    if (mealError) throw mealError;

    const { error: mealItemError } = await admin.from("meal_items").insert({
      meal_id: meal.id,
      user_id: user.id,
      client_id: `${user.id}-item`,
      position: 0,
      name: "Dal",
      quantity: 1,
      unit: "bowl",
      calories_kcal: 300,
      protein_g: 20,
      carbs_g: 35,
      fat_g: 8,
    });
    if (mealItemError) throw mealItemError;

    const { error: templateError } = await admin.from("meal_templates").insert({
      user_id: user.id,
      client_id: `${user.id}-template`,
      title: "Manual lunch",
      snapshot: { meal_id: meal.id },
      source_meal_id: meal.id,
    });
    if (templateError) throw templateError;

    const { error: customFoodError } = await admin.from("custom_foods").insert({
      user_id: user.id,
      client_id: `${user.id}-custom-food`,
      name: "Home dal",
      calories_kcal: 300,
      protein_g: 20,
      carbs_g: 35,
      fat_g: 8,
    });
    if (customFoodError) throw customFoodError;

    const { error: rollupError } = await admin.from("daily_rollups").insert({
      user_id: user.id,
      day: new Date().toISOString().slice(0, 10),
      calories_kcal: 300,
      protein_g: 20,
      carbs_g: 35,
      fat_g: 8,
      meal_count: 1,
      has_photo_meal: false,
    });
    if (rollupError) throw rollupError;

    const { error: correctionError } = await admin
      .from("correction_events")
      .insert({
        user_id: user.id,
        meal_id: meal.id,
        event_type: "meal_created",
        after_value: { title: "Manual lunch" },
      });
    if (correctionError) throw correctionError;

    const { data: asset, error: assetError } = await admin
      .from("meal_assets")
      .insert({
        user_id: user.id,
        storage_bucket: "meal-originals-private",
        storage_path: `${user.id}/rls-test.jpg`,
        sha256: crypto.randomUUID().replaceAll("-", ""),
        mime_type: "image/jpeg",
        size_bytes: 1000,
      })
      .select("*")
      .single();
    if (assetError) throw assetError;

    const { data: job, error: jobError } = await admin
      .from("analysis_jobs")
      .insert({
        user_id: user.id,
        client_request_id: `${user.id}-analysis`,
        analysis_mode: "photo",
        status: "completed",
        asset_id: asset.id,
        input_payload: { storage_path: asset.storage_path },
      })
      .select("*")
      .single();
    if (jobError) throw jobError;

    const { data: revision, error: revisionError } = await admin
      .from("analysis_revisions")
      .insert({
        analysis_job_id: job.id,
        user_id: user.id,
        revision_no: 1,
        title: "AI lunch",
        meal_type: "lunch",
        calories_kcal: 300,
        protein_g: 20,
        carbs_g: 35,
        fat_g: 8,
        confidence_overall: 0.7,
        result_payload: { title: "AI lunch", components: [] },
      })
      .select("*")
      .single();
    if (revisionError) throw revisionError;

    const { error: candidateError } = await admin
      .from("analysis_candidates")
      .insert({
        analysis_revision_id: revision.id,
        rank: 1,
        candidate_title: "Alternative lunch",
        confidence: 0.5,
        payload: { title: "Alternative lunch" },
      });
    if (candidateError) throw candidateError;

    const { error: invocationError } = await admin
      .from("model_invocations")
      .insert({
        analysis_job_id: job.id,
        user_id: user.id,
        provider: "mock",
        model_name: "mock-photo-analysis",
        status: "completed",
        request_payload: {},
        response_payload: {},
      });
    if (invocationError) throw invocationError;
  }

  const { data: ownProfile } = await userA.client
    .from("profiles")
    .select("*")
    .eq("id", userA.id);
  assert(ownProfile.length === 1, "User A should read own profile.");

  const { data: updatedOwnProfile, error: ownProfileUpdateError } =
    await userA.client
      .from("profiles")
      .update({ display_name: "Updated A" })
      .eq("id", userA.id)
      .select("*");
  if (ownProfileUpdateError) throw ownProfileUpdateError;
  assert(updatedOwnProfile.length === 1, "User A should update own profile.");

  const { data: otherProfile } = await userA.client
    .from("profiles")
    .select("*")
    .eq("id", userB.id);
  assert(otherProfile.length === 0, "User A must not read User B profile.");

  const { data: updatedOtherProfile, error: otherProfileUpdateError } =
    await userA.client
      .from("profiles")
      .update({ display_name: "Leaked update" })
      .eq("id", userB.id)
      .select("*");
  if (otherProfileUpdateError) throw otherProfileUpdateError;
  assert(
    updatedOtherProfile.length === 0,
    "User A must not update User B profile.",
  );

  const { data: updatedOwnGoal, error: ownGoalUpdateError } = await userA.client
    .from("nutrition_goals")
    .update({ calories_kcal: 1950 })
    .eq("user_id", userA.id)
    .select("*");
  if (ownGoalUpdateError) throw ownGoalUpdateError;
  assert(updatedOwnGoal.length === 1, "User A should update own goal.");

  const { data: otherGoals } = await userA.client
    .from("nutrition_goals")
    .select("*")
    .eq("user_id", userB.id);
  assert(otherGoals.length === 0, "User A must not read User B goals.");

  const { data: updatedOtherGoals, error: otherGoalUpdateError } =
    await userA.client
      .from("nutrition_goals")
      .update({ calories_kcal: 2100 })
      .eq("user_id", userB.id)
      .select("*");
  if (otherGoalUpdateError) throw otherGoalUpdateError;
  assert(
    updatedOtherGoals.length === 0,
    "User A must not update User B goals.",
  );

  const { data: updatedOwnMeasurements, error: ownMeasurementUpdateError } =
    await userA.client
      .from("body_measurements")
      .update({ weight_kg: 81 })
      .eq("user_id", userA.id)
      .select("*");
  assert(
    ownMeasurementUpdateError || updatedOwnMeasurements.length === 0,
    "User A must not update body measurements directly.",
  );

  const { data: otherMeasurements } = await userA.client
    .from("body_measurements")
    .select("*")
    .eq("user_id", userB.id);
  assert(
    otherMeasurements.length === 0,
    "User A must not read User B measurements.",
  );

  const { data: updatedOwnDevices, error: ownDeviceUpdateError } =
    await userA.client
      .from("devices")
      .update({ last_sync_cursor: "cursor-a" })
      .eq("user_id", userA.id)
      .select("*");
  if (ownDeviceUpdateError) throw ownDeviceUpdateError;
  assert(updatedOwnDevices.length === 1, "User A should update own device.");

  const { data: otherDevices } = await userA.client
    .from("devices")
    .select("*")
    .eq("user_id", userB.id);
  assert(otherDevices.length === 0, "User A must not read User B devices.");

  const { data: flags } = await userA.client
    .from("feature_flags")
    .select("*")
    .eq("key", "rls.test.enabled");
  assert(
    flags.length === 1,
    "Authenticated users should read global feature flags.",
  );

  const { data: overrides } = await userA.client
    .from("feature_flag_overrides")
    .select("*");
  assert(
    overrides.length === 0,
    "Users must not read feature flag overrides directly.",
  );

  const { data: events } = await userA.client
    .from("analytics_events")
    .select("*");
  assert(events.length === 0, "Users must not read analytics events directly.");

  const { data: ownMeals } = await userA.client
    .from("meals")
    .select("*")
    .eq("user_id", userA.id);
  assert(ownMeals.length === 1, "User A should read own meals.");

  const { data: directMealWrite, error: directMealWriteError } =
    await userA.client
      .from("meals")
      .insert({
        user_id: userA.id,
        client_id: `${userA.id}-direct-denied`,
        title: "Direct denied",
        meal_type: "snack",
        source: "manual",
        logged_at: new Date().toISOString(),
        timezone: "UTC",
      })
      .select("*");
  assertPermissionDenied(
    directMealWriteError,
    "User A must not insert meals directly.",
  );

  const { data: otherMeals, error: otherMealsError } = await userA.client
    .from("meals")
    .select("*")
    .eq("user_id", userB.id);
  assertNoRows(
    otherMeals,
    otherMealsError,
    "User A must not read User B meals.",
  );

  const { data: otherItems, error: otherItemsError } = await userA.client
    .from("meal_items")
    .select("*")
    .eq("user_id", userB.id);
  assertNoRows(
    otherItems,
    otherItemsError,
    "User A must not read User B meal items.",
  );

  const { data: otherTemplates, error: otherTemplatesError } =
    await userA.client
      .from("meal_templates")
      .select("*")
      .eq("user_id", userB.id);
  assertNoRows(
    otherTemplates,
    otherTemplatesError,
    "User A must not read User B meal templates.",
  );

  const { data: otherCustomFoods, error: otherCustomFoodsError } =
    await userA.client.from("custom_foods").select("*").eq("user_id", userB.id);
  assertNoRows(
    otherCustomFoods,
    otherCustomFoodsError,
    "User A must not read User B custom foods.",
  );

  const { data: otherRollups, error: otherRollupsError } = await userA.client
    .from("daily_rollups")
    .select("*")
    .eq("user_id", userB.id);
  assertNoRows(
    otherRollups,
    otherRollupsError,
    "User A must not read User B daily rollups.",
  );

  const { data: otherCorrections, error: otherCorrectionsError } =
    await userA.client
      .from("correction_events")
      .select("*")
      .eq("user_id", userB.id);
  assertNoRows(
    otherCorrections,
    otherCorrectionsError,
    "User A must not read User B correction events.",
  );

  const { data: directCorrectionWrite, error: directCorrectionWriteError } =
    await userA.client
      .from("correction_events")
      .insert({
        user_id: userA.id,
        event_type: "direct_denied",
        after_value: {},
      })
      .select("*");
  assertPermissionDenied(
    directCorrectionWriteError,
    "User A must not insert correction events directly.",
  );

  const { data: ownAssets } = await userA.client
    .from("meal_assets")
    .select("*")
    .eq("user_id", userA.id);
  assert(ownAssets.length === 1, "User A should read own meal assets.");

  const { data: directAssetWrite, error: directAssetWriteError } =
    await userA.client
      .from("meal_assets")
      .insert({
        user_id: userA.id,
        storage_bucket: "meal-originals-private",
        storage_path: `${userA.id}/direct-denied.jpg`,
        sha256: crypto.randomUUID().replaceAll("-", ""),
        mime_type: "image/jpeg",
      })
      .select("*");
  assertPermissionDenied(
    directAssetWriteError,
    "User A must not insert meal assets directly.",
  );

  const { data: otherAssets, error: otherAssetsError } = await userA.client
    .from("meal_assets")
    .select("*")
    .eq("user_id", userB.id);
  assertNoRows(
    otherAssets,
    otherAssetsError,
    "User A must not read User B meal assets.",
  );

  const { data: ownAnalysisJobs } = await userA.client
    .from("analysis_jobs")
    .select("*")
    .eq("user_id", userA.id);
  assert(ownAnalysisJobs.length === 1, "User A should read own analysis jobs.");

  const { data: otherAnalysisJobs, error: otherAnalysisJobsError } =
    await userA.client
      .from("analysis_jobs")
      .select("*")
      .eq("user_id", userB.id);
  assertNoRows(
    otherAnalysisJobs,
    otherAnalysisJobsError,
    "User A must not read User B analysis jobs.",
  );

  const { data: otherRevisions, error: otherRevisionsError } =
    await userA.client
      .from("analysis_revisions")
      .select("*")
      .eq("user_id", userB.id);
  assertNoRows(
    otherRevisions,
    otherRevisionsError,
    "User A must not read User B analysis revisions.",
  );

  const { data: ownInvocations, error: ownInvocationsError } =
    await userA.client
      .from("model_invocations")
      .select("*")
      .eq("user_id", userA.id);
  assertNoRows(
    ownInvocations,
    ownInvocationsError,
    "Users must not read model invocation internals directly.",
  );

  const { data: otherInvocations, error: otherInvocationsError } =
    await userA.client
      .from("model_invocations")
      .select("*")
      .eq("user_id", userB.id);
  assertNoRows(
    otherInvocations,
    otherInvocationsError,
    "User A must not read User B model invocations.",
  );

  console.log("RLS isolation checks passed.");
} finally {
  await admin.from("feature_flags").delete().eq("key", "rls.test.enabled");
  for (const id of cleanupIds) {
    await admin.auth.admin.deleteUser(id);
  }
}
