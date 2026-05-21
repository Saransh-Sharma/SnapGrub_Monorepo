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

const email = `phase7-${crypto.randomUUID()}@snapgrub.test`;
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

  const { error: profileError } = await admin.from('profiles').insert({
    id: userId,
    display_name: 'Phase 7',
    timezone: 'Asia/Kolkata',
    unit_system: 'metric',
  });
  if (profileError) throw profileError;

  const mealId = crypto.randomUUID();
  const clientId = crypto.randomUUID();
  const { data: mealWrite, error: mealError } = await admin.rpc('upsert_user_meal', {
    p_user_id: userId,
    p_meal_id: mealId,
    p_meal: {
      client_id: clientId,
      title: 'Roti and dal',
      meal_type: 'lunch',
      source: 'manual',
      logged_at: '2026-05-18T07:30:00.000Z',
      timezone: 'Asia/Kolkata',
      provenance_type: 'manual',
    },
    p_items: [
      {
        client_id: crypto.randomUUID(),
        position: 0,
        name: 'Roti',
        food_ref_kind: 'manual',
        quantity: 2,
        unit: 'roti',
        grams_estimated: 80,
        calories_kcal: 240,
        protein_g: 7,
        carbs_g: 44,
        fat_g: 5,
        source_type: 'manual',
      },
    ],
    p_expected_revision: null,
  });
  if (mealError) throw mealError;
  assert(mealWrite.meal.id === mealId, 'meal should be created for defaults smoke');

  const { data: defaultsUpdated, error: defaultsError } = await admin.rpc('refresh_user_food_defaults_for_meal', {
    p_user_id: userId,
    p_meal_id: mealId,
  });
  if (defaultsError) throw defaultsError;
  assert(defaultsUpdated >= 1, 'refresh_user_food_defaults_for_meal should upsert defaults');

  const { data: defaults, error: defaultsReadError } = await anon
    .from('user_food_defaults')
    .select('*')
    .eq('user_id', userId);
  if (defaultsReadError) throw defaultsReadError;
  assert(defaults.length >= 1, 'authenticated user should read own food defaults');

  const { error: insightInsertError } = await admin.from('weekly_insights').insert({
    user_id: userId,
    week_start: '2026-05-18',
    insight_type: 'logging_streak',
    title: 'Logging rhythm',
    summary: '1 day had meals logged this week.',
    payload: { logged_days: 1 },
    status: 'insufficient_data',
  });
  if (insightInsertError) throw insightInsertError;

  const { data: insights, error: insightReadError } = await anon
    .from('weekly_insights')
    .select('*')
    .eq('user_id', userId);
  if (insightReadError) throw insightReadError;
  assert(insights.length === 1, 'authenticated user should read own weekly insights');

  const { data: flag, error: flagError } = await admin
    .from('feature_flags')
    .select('*')
    .eq('key', 'weekly_insights.enabled')
    .single();
  if (flagError) throw flagError;
  assert(flag.enabled === false, 'weekly insights should start cohort-gated');

  console.log('Phase 7 insights/defaults smoke checks passed.');
} finally {
  if (userId) {
    await admin.auth.admin.deleteUser(userId);
  }
}
