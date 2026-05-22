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
  if (error) throw error;
  if (data?.error) throw new Error(`${functionName} failed: ${JSON.stringify(data.error)}`);
  return data;
}

const onePixelJpeg = Uint8Array.from([
  0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
  0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xff, 0xdb, 0x00, 0x43,
  0x00, 0xff, 0xc0, 0x00, 0x0b, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01,
  0x11, 0x00, 0xff, 0xc4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xda,
  0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3f, 0x00, 0xd2, 0xcf, 0x20, 0xff,
  0xd9,
]);

const email = `photo-analysis-${crypto.randomUUID()}@snapgrub.test`;
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
    display_name: 'Photo Analysis',
    timezone: 'Asia/Kolkata',
    unit_system: 'metric',
    locale: 'en-IN',
  });
  if (profileError) throw profileError;

  const { error: signInError } = await anon.auth.signInWithPassword({ email, password });
  if (signInError) throw signInError;

  const storagePath = `${userId}/${crypto.randomUUID()}.jpg`;
  const { error: uploadError } = await anon.storage
    .from('meal-originals-private')
    .upload(storagePath, new Blob([onePixelJpeg], { type: 'image/jpeg' }), {
      contentType: 'image/jpeg',
      upsert: true,
    });
  if (uploadError) throw uploadError;

  const clientRequestId = crypto.randomUUID();
  const analysis = await invokeOrThrow(anon, 'analysis-photo-create', {
    body: {
      client_request_id: clientRequestId,
      storage_bucket: 'meal-originals-private',
      storage_path: storagePath,
      asset_sha256: 'photo-analysis-smoke-sha',
      mime_type: 'image/jpeg',
      width: 1,
      height: 1,
      size_bytes: onePixelJpeg.length,
      locale: 'en-IN',
      timezone: 'Asia/Kolkata',
      meal_type_hint: 'lunch',
      cuisine_hints: ['Indian'],
      user_hint_text: 'dal and roti',
    },
  });

  assert(analysis.status === 'completed', 'photo analysis should complete with mock provider');
  assert(analysis.asset_id, 'photo analysis should return a persisted asset id');
  assert(analysis.result?.title, 'photo analysis should return an editable draft');
  assert(analysis.result?.confidence?.warnings?.length >= 1, 'photo analysis should include review warnings');

  const { data: invocations, error: invocationError } = await admin
    .from('model_invocations')
    .select('provider, model_name, status')
    .eq('analysis_job_id', analysis.analysis_id);
  if (invocationError) throw invocationError;
  assert(invocations.length === 1, 'photo analysis should log one model invocation');
  assert(invocations[0].status === 'completed', 'model invocation should be completed');

  const recovered = await invokeOrThrow(anon, `analysis-get/${analysis.analysis_id}`, {
    method: 'GET',
  });
  assert(recovered.analysis_id === analysis.analysis_id, 'analysis-get should recover the analysis by id');
  assert(recovered.result?.title === analysis.result.title, 'analysis-get should return the latest result payload');

  const badPath = `${crypto.randomUUID()}/not-owned.jpg`;
  const { data: rejected, error: rejectError } = await anon.functions.invoke('analysis-photo-create', {
    body: {
      client_request_id: crypto.randomUUID(),
      storage_path: badPath,
      locale: 'en-IN',
      timezone: 'Asia/Kolkata',
    },
  });
  assert(rejectError || rejected?.error?.code === 'INVALID_INPUT', 'cross-user storage path should be rejected');

  console.log('Photo analysis smoke checks passed.');
} finally {
  if (userId) {
    await admin.auth.admin.deleteUser(userId);
  }
}
