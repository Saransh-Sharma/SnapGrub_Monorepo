import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL ?? process.env.API_URL ?? 'http://127.0.0.1:54321';
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SERVICE_ROLE_KEY;
const anonKey = process.env.SUPABASE_ANON_KEY ?? process.env.ANON_KEY;

if (!serviceRoleKey) throw new Error('SUPABASE_SERVICE_ROLE_KEY is required.');
if (!anonKey) throw new Error('SUPABASE_ANON_KEY is required.');

const admin = createClient(url, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const anon = createClient(url, anonKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function invokeOrThrow(client, functionName, options) {
  const { data, error } = await client.functions.invoke(functionName, options);
  if (error) {
    if (error.context && typeof error.context.json === 'function') {
      const body = await error.context.json().catch(() => null);
      throw new Error(`${functionName} returned ${error.context.status}: ${JSON.stringify(body)}`);
    }
    throw error;
  }
  if (data?.error) throw new Error(`${functionName} failed: ${JSON.stringify(data.error)}`);
  return data;
}

async function createSignedInUser(prefix) {
  const email = `${prefix}-${crypto.randomUUID()}@snapgrub.test`;
  const password = `Pass-${crypto.randomUUID()}`;
  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (createError) throw createError;
  const { error: profileError } = await admin.from('profiles').insert({
    id: created.user.id,
    display_name: prefix,
    timezone: 'Asia/Kolkata',
    unit_system: 'metric',
    locale: 'en-IN',
  });
  if (profileError) throw profileError;
  const client = createClient(url, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { error: signInError } = await client.auth.signInWithPassword({ email, password });
  if (signInError) throw signInError;
  return { id: created.user.id, client };
}

let exportUserId;
let deleteUserId;

try {
  const exportUser = await createSignedInUser('phase8-export');
  exportUserId = exportUser.id;

  const { error: goalError } = await admin.from('nutrition_goals').insert({
    user_id: exportUserId,
    goal_type: 'lose',
    calories_kcal: 1900,
    protein_g: 130,
    carbs_g: 190,
    fat_g: 60,
  });
  if (goalError) throw goalError;

  const mealId = crypto.randomUUID();
  const { error: mealError } = await admin.from('meals').insert({
    id: mealId,
    user_id: exportUserId,
    client_id: crypto.randomUUID(),
    title: 'Phase 8 meal',
    meal_type: 'lunch',
    source: 'manual',
    logged_at: new Date().toISOString(),
    timezone: 'Asia/Kolkata',
    calories_kcal: 500,
    protein_g: 25,
    carbs_g: 60,
    fat_g: 15,
  });
  if (mealError) throw mealError;
  const { error: itemError } = await admin.from('meal_items').insert({
    meal_id: mealId,
    user_id: exportUserId,
    client_id: crypto.randomUUID(),
    position: 0,
    name: 'Dal',
    food_ref_kind: 'manual',
    quantity: 1,
    unit: 'bowl',
    calories_kcal: 220,
    protein_g: 14,
    carbs_g: 30,
    fat_g: 6,
  });
  if (itemError) throw itemError;

  const clientRequestId = crypto.randomUUID();
  const exported = await invokeOrThrow(exportUser.client, 'exports-create', {
    headers: { 'Idempotency-Key': clientRequestId },
    body: {
      client_request_id: clientRequestId,
      export_type: 'nutrition_json',
    },
  });
  assert(exported.export_request.status === 'completed', 'export should complete synchronously');
  assert(exported.export_request.result_storage_path, 'export should have a storage path');
  assert(exported.export_request.signed_url, 'export should return a signed URL');
  assert(exported.export_request.row_counts.meals === 1, 'export should count meal rows');

  const recovered = await invokeOrThrow(exportUser.client, `exports-create/${exported.export_request.id}`, {
    method: 'GET',
  });
  assert(recovered.export_request.id === exported.export_request.id, 'export polling should return the same export');

  const { data: artifact, error: downloadError } = await admin.storage
    .from('exports-private')
    .download(exported.export_request.result_storage_path);
  if (downloadError) throw downloadError;
  const artifactText = await artifact.text();
  assert(artifactText.includes('Phase 8 meal'), 'export artifact should contain meal data');

  const deleteUser = await createSignedInUser('phase8-delete');
  deleteUserId = deleteUser.id;
  const storagePath = `${deleteUserId}/${crypto.randomUUID()}.json`;
  const { error: uploadError } = await admin.storage
    .from('exports-private')
    .upload(storagePath, new Blob(['{}'], { type: 'application/json' }), {
      contentType: 'application/json',
      upsert: true,
    });
  if (uploadError) throw uploadError;

  const deletion = await invokeOrThrow(deleteUser.client, 'account-delete', {
    body: { confirmation: 'DELETE' },
  });
  assert(deletion.account_deletion.status === 'completed', 'account deletion should complete');
  deleteUserId = undefined;

  const { data: deletedProfile, error: profileReadError } = await admin
    .from('profiles')
    .select('id')
    .eq('id', deletion.account_deletion.user_id)
    .maybeSingle();
  if (profileReadError) throw profileReadError;
  assert(deletedProfile == null, 'account deletion should remove profile rows');

  const cleanup = await invokeOrThrow(admin, 'media-retention-cleanup', {
    body: { limit: 10 },
  });
  assert(typeof cleanup.export_cleanup.expired_requests === 'number', 'cleanup should return export counts');

  console.log('Phase 8 privacy/export/delete smoke checks passed.');
} finally {
  if (exportUserId) await admin.auth.admin.deleteUser(exportUserId);
  if (deleteUserId) await admin.auth.admin.deleteUser(deleteUserId);
}
