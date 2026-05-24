import { createClient } from "@supabase/supabase-js";

const url =
  process.env.SUPABASE_URL ?? process.env.API_URL ?? "http://127.0.0.1:54321";
const functionsUrl = process.env.FUNCTIONS_URL ?? `${url}/functions/v1`;
const serviceRoleKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SERVICE_ROLE_KEY;
const anonKey = process.env.SUPABASE_ANON_KEY ?? process.env.ANON_KEY;

if (!serviceRoleKey) throw new Error("SUPABASE_SERVICE_ROLE_KEY is required.");
if (!anonKey) throw new Error("SUPABASE_ANON_KEY is required.");

const admin = createClient(url, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function createSignedInUser(prefix) {
  const email = `${prefix}-${crypto.randomUUID()}@snapgrub.test`;
  const password = `Pass-${crypto.randomUUID()}`;
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

async function invoke(client, functionName, options) {
  const { data, error } = await client.functions.invoke(functionName, options);
  return { data, error };
}

async function assertFunctionCode(result, expectedCode, message) {
  let body = result.data ?? null;
  if (
    !body?.code &&
    result.error?.context &&
    typeof result.error.context.clone === "function"
  ) {
    body = await result.error.context
      .clone()
      .json()
      .catch(() => null);
  }
  assert(
    body?.code === expectedCode,
    `${message}: expected ${expectedCode}, got ${JSON.stringify({ body, error: result.error?.message })}`,
  );
}

function fakeServiceRoleJwt() {
  const header = btoa(JSON.stringify({ alg: "none", typ: "JWT" }))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
  const payload = btoa(JSON.stringify({ role: "service_role" }))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
  return `${header}.${payload}.fake`;
}

const cleanupIds = [];

try {
  const spoofResponse = await fetch(`${functionsUrl}/media-retention-cleanup`, {
    method: "POST",
    headers: {
      apikey: anonKey,
      authorization: `Bearer ${fakeServiceRoleJwt()}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({ limit: 1 }),
  });
  assert(
    spoofResponse.status === 401,
    "unsigned service_role JWT must not authorize cleanup.",
  );

  const userA = await createSignedInUser("remediation-a");
  const userB = await createSignedInUser("remediation-b");
  cleanupIds.push(userA.id, userB.id);

  const installId = `shared-install-${crypto.randomUUID()}`;
  const firstBootstrap = await invoke(userA.client, "profile-bootstrap", {
    body: { install_id: installId, platform: "ios", timezone: "UTC" },
  });
  if (firstBootstrap.error) throw firstBootstrap.error;
  assert(
    firstBootstrap.data.device.install_id === installId,
    "first device bootstrap should succeed.",
  );

  const secondBootstrap = await invoke(userB.client, "profile-bootstrap", {
    body: { install_id: installId, platform: "ios", timezone: "UTC" },
  });
  await assertFunctionCode(
    secondBootstrap,
    "CONFLICT",
    "install_id takeover must be rejected",
  );

  const mealId = crypto.randomUUID();
  const { error: mealInsertError } = await admin.from("meals").insert({
    id: mealId,
    user_id: userA.id,
    client_id: crypto.randomUUID(),
    title: "Deleted meal",
    meal_type: "snack",
    source: "manual",
    logged_at: new Date().toISOString(),
    timezone: "UTC",
    deleted_at: new Date().toISOString(),
  });
  if (mealInsertError) throw mealInsertError;
  const deletedRead = await invoke(userA.client, `meals/${mealId}`, {
    method: "GET",
  });
  await assertFunctionCode(
    deletedRead,
    "NOT_FOUND",
    "soft-deleted meal detail should return not found",
  );

  const { data: userBCustomFood, error: customFoodError } = await admin
    .from("custom_foods")
    .insert({
      user_id: userB.id,
      client_id: crypto.randomUUID(),
      name: "Other user food",
      calories_kcal: 100,
      protein_g: 5,
      carbs_g: 10,
      fat_g: 2,
    })
    .select("id")
    .single();
  if (customFoodError) throw customFoodError;

  const crossUserCustomFoodMeal = await invoke(userA.client, "meals", {
    body: {
      client_request_id: crypto.randomUUID(),
      client_id: crypto.randomUUID(),
      title: "Cross-user custom food",
      meal_type: "snack",
      source: "manual",
      logged_at: new Date().toISOString(),
      timezone: "UTC",
      items: [
        {
          client_id: crypto.randomUUID(),
          position: 0,
          name: "Other user food",
          food_ref_kind: "custom",
          custom_food_id: userBCustomFood.id,
          quantity: 1,
          unit: "serving",
          calories_kcal: 100,
          protein_g: 5,
          carbs_g: 10,
          fat_g: 2,
        },
      ],
    },
  });
  await assertFunctionCode(
    crossUserCustomFoodMeal,
    "INVALID_INPUT",
    "meal write must reject another user custom_food_id",
  );

  const idempotencyKey = crypto.randomUUID();
  const badSettingsBody = {
    client_request_id: idempotencyKey,
    profile_patch: { cloud_media_storage: "yes" },
  };
  const firstBadSettings = await invoke(userA.client, "settings-patch", {
    method: "PATCH",
    headers: { "Idempotency-Key": idempotencyKey },
    body: badSettingsBody,
  });
  await assertFunctionCode(
    firstBadSettings,
    "INVALID_INPUT",
    "invalid settings input should fail validation",
  );
  const secondBadSettings = await invoke(userA.client, "settings-patch", {
    method: "PATCH",
    headers: { "Idempotency-Key": idempotencyKey },
    body: badSettingsBody,
  });
  await assertFunctionCode(
    secondBadSettings,
    "INVALID_INPUT",
    "invalid settings retry must not become in-progress idempotency conflict",
  );

  console.log("Backend remediation smoke checks passed.");
} finally {
  for (const id of cleanupIds) {
    await admin.auth.admin.deleteUser(id);
  }
}
