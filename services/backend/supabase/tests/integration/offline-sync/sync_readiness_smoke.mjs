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

const email = `offline-sync-${crypto.randomUUID()}@snapgrub.test`;
const password = `Pass-${crypto.randomUUID()}`;
let userId;

try {
  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (createError) throw createError;
  userId = created.user.id;

  const { error: profileError } = await admin.from('profiles').insert({
    id: userId,
    display_name: 'Offline Sync',
    timezone: 'Asia/Kolkata',
    unit_system: 'metric',
  });
  if (profileError) throw profileError;

  const { error: signInError } = await anon.auth.signInWithPassword({ email, password });
  if (signInError) throw signInError;

  const { error: rollupInsertError } = await anon.from('daily_rollups').insert({
    user_id: userId,
    day: '2026-05-21',
    calories_kcal: 1,
    protein_g: 1,
    carbs_g: 1,
    fat_g: 1,
    meal_count: 1,
    has_photo_meal: false,
  });
  assert(rollupInsertError, 'authenticated clients must not write derived daily_rollups');

  const expiredKey = crypto.randomUUID();
  const { error: idemInsertError } = await admin.from('api_idempotency').insert({
    user_id: userId,
    endpoint: 'offline-sync-smoke',
    key: expiredKey,
    request_hash: 'abc',
    response_status: 200,
    response_body: { ok: true },
    expires_at: '2020-01-01T00:00:00.000Z',
  });
  if (idemInsertError) throw idemInsertError;

  const { data: deleted, error: purgeError } = await admin.rpc('purge_expired_api_idempotency', { p_limit: 10 });
  if (purgeError) throw purgeError;
  assert(deleted >= 1, 'purge_expired_api_idempotency should delete expired rows');

  const { error: uploadError } = await admin.from('pending_uploads').insert({
    user_id: userId,
    storage_bucket: 'meal-originals-private',
    storage_path: `${userId}/offline-sync.jpg`,
    sha256: crypto.randomUUID().replaceAll('-', ''),
  });
  if (uploadError) throw uploadError;

  const { error: exportError } = await admin.from('export_requests').insert({
    user_id: userId,
    client_request_id: crypto.randomUUID(),
    export_type: 'journal_csv',
  });
  if (exportError) throw exportError;

  console.log('Offline sync readiness smoke checks passed.');
} finally {
  if (userId) {
    await admin.auth.admin.deleteUser(userId);
  }
}
