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

const email = `phase5-${crypto.randomUUID()}@snapgrub.test`;
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
    display_name: 'Phase 5',
    timezone: 'Asia/Kolkata',
    unit_system: 'metric',
  });
  if (profileError) throw profileError;

  const { data: roti, error: rotiError } = await admin
    .from('canonical_foods')
    .select('*, food_nutrients(*)')
    .eq('source_id', 'curated:roti')
    .single();
  if (rotiError) throw rotiError;
  assert(roti.food_nutrients.length === 1, 'curated roti should have nutrient seed data');

  const { data: barcode, error: barcodeError } = await admin
    .from('product_barcodes')
    .select('barcode, branded_products(*)')
    .eq('barcode', '8901719101018')
    .single();
  if (barcodeError) throw barcodeError;
  assert(barcode.branded_products.name.includes('Parle'), 'hot barcode cache should contain Parle-G');

  for (const source of ['barcode', 'text', 'voice']) {
    const mealId = crypto.randomUUID();
    const clientId = crypto.randomUUID();
    const { data, error } = await admin.rpc('upsert_user_meal', {
      p_user_id: userId,
      p_meal_id: mealId,
      p_meal: {
        client_id: clientId,
        title: `${source} meal`,
        meal_type: 'snack',
        source,
        logged_at: '2026-05-20T10:30:00.000Z',
        timezone: 'Asia/Kolkata',
        provenance_type: `${source}_parser`,
      },
      p_items: [
        {
          client_id: crypto.randomUUID(),
          position: 0,
          name: source === 'barcode' ? 'Parle-G Original Gluco Biscuits' : 'Roti',
          food_ref_kind: source === 'text' ? 'canonical' : 'manual',
          canonical_food_id: source === 'text' ? roti.id : null,
          quantity: 1,
          unit: source === 'text' ? 'roti' : 'serving',
          calories_kcal: 119,
          protein_g: 3.9,
          carbs_g: 18.4,
          fat_g: 3,
          confidence: 0.7,
          source_type: source,
        },
      ],
      p_expected_revision: null,
    });
    if (error) throw error;
    assert(data.meal.source === source, `${source} source should be accepted by meal RPC`);
  }

  const { data: voiceJob, error: voiceJobError } = await admin.from('analysis_jobs').insert({
    user_id: userId,
    client_request_id: crypto.randomUUID(),
    analysis_mode: 'voice',
    status: 'completed',
    input_payload: { transcript: '2 rotis and dal' },
  }).select('*').single();
  if (voiceJobError) throw voiceJobError;
  assert(voiceJob.analysis_mode === 'voice', 'analysis_jobs should allow voice mode');

  console.log('Phase 5 multimodal smoke checks passed.');
} finally {
  if (userId) {
    await admin.auth.admin.deleteUser(userId);
  }
}
