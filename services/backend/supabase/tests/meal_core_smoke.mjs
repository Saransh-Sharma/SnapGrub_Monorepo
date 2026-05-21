import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL ?? process.env.API_URL ?? 'http://127.0.0.1:54321';
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SERVICE_ROLE_KEY;

if (!serviceRoleKey) {
  throw new Error('SUPABASE_SERVICE_ROLE_KEY is required.');
}

const admin = createClient(url, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const email = `meal-core-${crypto.randomUUID()}@snapgrub.test`;
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
    display_name: 'Meal smoke',
    timezone: 'Asia/Kolkata',
    unit_system: 'metric',
  });
  if (profileError) throw profileError;

  const mealId = crypto.randomUUID();
  const clientId = crypto.randomUUID();
  const itemId = crypto.randomUUID();
  const loggedAt = '2026-05-20T20:30:00.000Z';

  const createPayload = {
    client_id: clientId,
    title: 'Dal chawal',
    meal_type: 'dinner',
    source: 'manual',
    logged_at: loggedAt,
    timezone: 'Asia/Kolkata',
  };
  const createItems = [
    {
      client_id: itemId,
      position: 0,
      name: 'Dal',
      food_ref_kind: 'manual',
      quantity: 1,
      unit: 'bowl',
      calories_kcal: 220,
      protein_g: 12,
      carbs_g: 30,
      fat_g: 6,
    },
  ];

  const { data: createdMeal, error: upsertError } = await admin.rpc('upsert_user_meal', {
    p_user_id: userId,
    p_meal_id: mealId,
    p_meal: createPayload,
    p_items: createItems,
    p_expected_revision: null,
  });
  if (upsertError) throw upsertError;
  assert(createdMeal.meal.id === mealId, 'create should return authoritative meal');
  assert(createdMeal.daily_rollup.calories_kcal === 220, 'create should refresh rollup');
  assert(createdMeal.correction_events.length === 1, 'create should return correction event');
  assert(createdMeal.correction_events[0].event_type === 'meal_created', 'create event type mismatch');

  const { data: updatedMeal, error: updateError } = await admin.rpc('upsert_user_meal', {
    p_user_id: userId,
    p_meal_id: mealId,
    p_meal: { ...createPayload, title: 'Dal chawal and curd' },
    p_items: [
      ...createItems,
      {
        client_id: crypto.randomUUID(),
        position: 1,
        name: 'Curd',
        food_ref_kind: 'manual',
        quantity: 1,
        unit: 'cup',
        calories_kcal: 120,
        protein_g: 6,
        carbs_g: 10,
        fat_g: 5,
      },
    ],
    p_expected_revision: 1,
  });
  if (updateError) throw updateError;
  assert(updatedMeal.meal.revision === 2, 'update should increment revision');
  assert(updatedMeal.daily_rollup.calories_kcal === 340, 'update should refresh rollup totals');
  assert(updatedMeal.correction_events[0].event_type === 'meal_updated', 'update event type mismatch');

  const { data: asset, error: assetError } = await admin.from('meal_assets').insert({
    user_id: userId,
    storage_bucket: 'meal-originals-private',
    storage_path: `${userId}/photo-smoke.jpg`,
    sha256: crypto.randomUUID().replaceAll('-', ''),
    mime_type: 'image/jpeg',
    size_bytes: 1000,
  }).select('*').single();
  if (assetError) throw assetError;

  const { data: analysisJob, error: analysisJobError } = await admin.from('analysis_jobs').insert({
    user_id: userId,
    client_request_id: crypto.randomUUID(),
    analysis_mode: 'photo',
    status: 'completed',
    asset_id: asset.id,
    input_payload: { storage_path: asset.storage_path },
  }).select('*').single();
  if (analysisJobError) throw analysisJobError;

  const { data: photoMeal, error: photoError } = await admin.rpc('upsert_user_meal', {
    p_user_id: userId,
    p_meal_id: mealId,
    p_meal: {
      ...createPayload,
      title: 'Photo dal chawal',
      source: 'photo',
      analysis_job_id: analysisJob.id,
      photo_asset_id: asset.id,
      confidence_overall: 0.72,
      provenance_type: 'ai_photo',
    },
    p_items: createItems.map((item) => ({ ...item, confidence: 0.72, source_type: 'ai_photo' })),
    p_expected_revision: 2,
  });
  if (photoError) throw photoError;
  assert(photoMeal.meal.source === 'photo', 'photo update should be accepted with owned completed analysis');
  assert(photoMeal.meal.analysis_job_id === analysisJob.id, 'photo update should preserve analysis job');

  const { error: forgedPhotoError } = await admin.rpc('upsert_user_meal', {
    p_user_id: userId,
    p_meal_id: mealId,
    p_meal: {
      ...createPayload,
      source: 'photo',
      analysis_job_id: crypto.randomUUID(),
      photo_asset_id: asset.id,
    },
    p_items: createItems,
    p_expected_revision: 3,
  });
  assert(forgedPhotoError, 'forged photo analysis references should fail');

  const { data: deletedMeal, error: deleteError } = await admin.rpc('delete_user_meal', {
    p_user_id: userId,
    p_meal_id: mealId,
    p_expected_revision: 3,
  });
  if (deleteError) throw deleteError;
  assert(deletedMeal.meal.deleted_at !== null, 'delete should soft-delete meal');
  assert(deletedMeal.daily_rollup.calories_kcal === 0, 'delete should remove meal from rollup');
  assert(deletedMeal.correction_events[0].event_type === 'meal_deleted', 'delete event type mismatch');

  const { data: events, error: eventsError } = await admin
    .from('correction_events')
    .select('*')
    .eq('user_id', userId)
    .eq('meal_id', mealId);
  if (eventsError) throw eventsError;
  assert(events.length === 4, 'correction events should be append-only');

  console.log('Meal core smoke checks passed.');
} finally {
  if (userId) {
    await admin.auth.admin.deleteUser(userId);
  }
}
