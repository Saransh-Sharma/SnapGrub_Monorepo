import assert from "node:assert/strict";
import { createClient } from "@supabase/supabase-js";

export const supabaseUrl = process.env.SUPABASE_URL ?? process.env.API_URL ?? "http://127.0.0.1:54321";
export const functionsUrl = process.env.FUNCTIONS_URL ?? `${supabaseUrl}/functions/v1`;
export const anonKey = process.env.SUPABASE_ANON_KEY ?? process.env.ANON_KEY;
export const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SERVICE_ROLE_KEY;

if (!anonKey) throw new Error("SUPABASE_ANON_KEY is required.");
if (!serviceRoleKey) throw new Error("SUPABASE_SERVICE_ROLE_KEY is required.");

if (!process.env.SNAPGRUB_ALLOW_REMOTE_BACKEND_E2E) {
  assert.match(
    supabaseUrl,
    /^http:\/\/(127\.0\.0\.1|localhost|0\.0\.0\.0)(:|\/|$)/,
    "Backend API E2E is destructive and must target local Supabase unless SNAPGRUB_ALLOW_REMOTE_BACKEND_E2E=1 is set.",
  );
}

export const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

export function anonClient() {
  return createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function createSignedInUser(prefix, options = {}) {
  const email = `${prefix}-${crypto.randomUUID()}@snapgrub.test`;
  const password = `Pass-${crypto.randomUUID()}`;
  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (createError) throw createError;

  const client = anonClient();
  const { error: signInError } = await client.auth.signInWithPassword({ email, password });
  if (signInError) throw signInError;

  if (options.profile) {
    const { error: profileError } = await admin.from("profiles").upsert({
      id: created.user.id,
      display_name: options.displayName ?? prefix,
      timezone: options.timezone ?? "Asia/Kolkata",
      unit_system: "metric",
      locale: "en-IN",
    });
    if (profileError) throw profileError;
  }

  return { id: created.user.id, email, password, client };
}

export async function authToken(user) {
  const { data, error } = await user.client.auth.getSession();
  if (error) throw error;
  const token = data.session?.access_token;
  if (!token) throw new Error(`No auth token for ${user.email}`);
  return token;
}

export async function invokeUser(user, path, options = {}) {
  return invoke(path, {
    ...options,
    bearer: await authToken(user),
    apikey: anonKey,
  });
}

export async function invokeService(path, options = {}) {
  return invoke(path, {
    ...options,
    bearer: serviceRoleKey,
    apikey: serviceRoleKey,
  });
}

export async function invokeAnon(path, options = {}) {
  return invoke(path, {
    ...options,
    apikey: anonKey,
  });
}

export async function invoke(path, options = {}) {
  const method = options.method ?? "POST";
  const headers = {
    apikey: options.apikey ?? anonKey,
    "content-type": "application/json",
    ...(options.bearer ? { authorization: `Bearer ${options.bearer}` } : {}),
    ...(options.headers ?? {}),
  };
  const response = await fetch(`${functionsUrl}/${path}`, {
    method,
    headers,
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  const text = await response.text();
  const body = text ? JSON.parse(text) : null;
  return { status: response.status, body, headers: response.headers };
}

export function assertOk(result, expectedStatus = 200) {
  assert.equal(result.status, expectedStatus, JSON.stringify(result.body));
  assert.ok(result.body?.request_id, "response should include request_id");
  return result.body;
}

export function assertError(result, expectedStatus, expectedCode) {
  assert.equal(result.status, expectedStatus, JSON.stringify(result.body));
  assert.equal(result.body?.code, expectedCode, JSON.stringify(result.body));
  assert.equal(typeof result.body?.user_message, "string");
  assert.equal(typeof result.body?.retryable, "boolean");
  assert.ok(result.body?.request_id, "error response should include request_id");
  return result.body;
}

export async function deleteUsers(userIds) {
  for (const userId of userIds) {
    if (!userId) continue;
    await removeUserStorage(userId).catch(() => {});
    await admin.auth.admin.deleteUser(userId).catch(() => {});
  }
}

export async function removeUserStorage(userId) {
  for (const bucket of ["meal-originals-private", "meal-thumbnails-private", "exports-private"]) {
    const paths = await listStoragePaths(bucket, userId);
    for (const batch of chunks(paths, 100)) {
      if (batch.length > 0) await admin.storage.from(bucket).remove(batch);
    }
  }
}

export async function listStoragePaths(bucket, prefix) {
  const paths = [];
  await collectStoragePaths(bucket, prefix, paths);
  return paths;
}

async function collectStoragePaths(bucket, prefix, paths) {
  const { data, error } = await admin.storage.from(bucket).list(prefix, {
    limit: 1000,
    offset: 0,
    sortBy: { column: "name", order: "asc" },
  });
  if (error) return;
  for (const item of data ?? []) {
    const itemPath = `${prefix}/${item.name}`;
    if (item.id || item.metadata) {
      paths.push(itemPath);
    } else {
      await collectStoragePaths(bucket, itemPath, paths);
    }
  }
}

function chunks(values, size) {
  const batches = [];
  for (let index = 0; index < values.length; index += size) batches.push(values.slice(index, index + size));
  return batches;
}

export const onePixelJpeg = Uint8Array.from([
  0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
  0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xff, 0xdb, 0x00, 0x43,
  0x00, 0xff, 0xc0, 0x00, 0x0b, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01,
  0x11, 0x00, 0xff, 0xc4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xda,
  0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3f, 0x00, 0xd2, 0xcf, 0x20, 0xff,
  0xd9,
]);

export async function uploadUserObject(user, bucket, path, bytes, contentType) {
  const { error } = await user.client.storage
    .from(bucket)
    .upload(path, new Blob([bytes], { type: contentType }), {
      contentType,
      upsert: true,
    });
  if (error) throw error;
}

export function fakeServiceRoleJwt() {
  const encode = (value) => Buffer.from(JSON.stringify(value)).toString("base64url");
  return `${encode({ alg: "none", typ: "JWT" })}.${encode({ role: "service_role" })}.fake`;
}
