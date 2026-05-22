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

const email = `auth-profile-${crypto.randomUUID()}@snapgrub.test`;
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

  const { error: signInError } = await anon.auth.signInWithPassword({ email, password });
  if (signInError) throw signInError;

  const bootstrap = await invokeOrThrow(anon, 'profile-bootstrap', {
    body: {
      install_id: `install-${crypto.randomUUID()}`,
      platform: 'ios',
      app_version: '0.1.0',
      build_number: '1',
      locale: 'en-IN',
      timezone: 'Asia/Kolkata',
    },
  });
  assert(bootstrap.profile.id === userId, 'bootstrap should create/read the signed-in profile');
  assert(bootstrap.device.user_id === userId, 'bootstrap should register the signed-in device');
  assert(typeof bootstrap.feature_flags === 'object', 'bootstrap should return feature flags');

  const requestId = crypto.randomUUID();
  const settings = await invokeOrThrow(anon, 'settings-patch', {
    method: 'PATCH',
    headers: { 'Idempotency-Key': requestId },
    body: {
      client_request_id: requestId,
      profile_patch: {
        display_name: 'Auth Profile',
        unit_system: 'metric',
        cuisine_preferences: ['Indian'],
      },
      active_goal_patch: {
        goal_type: 'lose',
        calories_kcal: 1900,
        protein_g: 130,
        carbs_g: 190,
        fat_g: 60,
      },
      body_measurement: {
        weight_kg: 82,
        source: 'onboarding',
      },
    },
  });
  assert(settings.profile.display_name === 'Auth Profile', 'settings-patch should update profile fields');
  assert(settings.active_goal.calories_kcal === 1900, 'settings-patch should create/update active goal');
  assert(settings.body_measurement.weight_kg === 82, 'settings-patch should persist body measurement');

  const eventsRequestId = crypto.randomUUID();
  const events = await invokeOrThrow(anon, 'events-ingest', {
    headers: { 'Idempotency-Key': eventsRequestId },
    body: {
      client_request_id: eventsRequestId,
      events: [
        {
          event_name: 'auth_profile_smoke_event',
          properties: { source: 'profile_settings_events_smoke' },
          occurred_at: new Date().toISOString(),
        },
      ],
    },
  });
  assert(events.accepted === 1, 'events-ingest should accept one valid event');

  const { data: rows, error: eventReadError } = await admin
    .from('analytics_events')
    .select('event_name, user_id')
    .eq('user_id', userId)
    .eq('event_name', 'auth_profile_smoke_event');
  if (eventReadError) throw eventReadError;
  assert(rows.length === 1, 'events-ingest should insert the analytics event');

  console.log('Auth/profile/settings/events smoke checks passed.');
} finally {
  if (userId) {
    await admin.auth.admin.deleteUser(userId);
  }
}
