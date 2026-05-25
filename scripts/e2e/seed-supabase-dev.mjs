import { createClient } from "@supabase/supabase-js";
import fs from "node:fs";
import path from "node:path";
import ws from "ws";

const repoRoot = path.resolve(import.meta.dirname, "../..");
const platform = process.env.E2E_PLATFORM || process.argv[2] || "android";
const target = process.env.E2E_TARGET || process.argv[3] || "local";

if (platform !== "android" && platform !== "ios") {
  throw new Error("E2E_PLATFORM must be android or ios.");
}

if (target !== "local" && target !== "developer") {
  throw new Error("E2E_TARGET must be local or developer.");
}

function loadEnv(file) {
  if (!fs.existsSync(file)) return;
  for (const line of fs.readFileSync(file, "utf8").split(/\r?\n/)) {
    if (!line || line.trimStart().startsWith("#")) continue;
    const index = line.indexOf("=");
    if (index === -1) continue;
    const key = line.slice(0, index).trim();
    const value = line.slice(index + 1).trim().replace(/^"|"$/g, "");
    if (!process.env[key]) process.env[key] = value;
  }
}

loadEnv(path.join(repoRoot, `apps/mobile/.env.${target}`));
loadEnv(path.join(repoRoot, `services/backend/supabase/.env.${target}`));

const email = process.env.E2E_EMAIL || `snapgrub-e2e-${platform}@example.com`;
const passwordFromEnv = process.env.E2E_PASSWORD;
const password = passwordFromEnv || "SnapGrub-e2e-password-123";

if (!/^snapgrub-e2e-(android|ios)@example\.com$/i.test(email)) {
  throw new Error(
    `Refusing to reset non-dedicated E2E user: ${email}. Use snapgrub-e2e-android@example.com or snapgrub-e2e-ios@example.com.`,
  );
}

if (target === "developer") {
  if (process.env.SNAPGRUB_ALLOW_REMOTE_E2E_SEED !== "1") {
    throw new Error(
      "Developer Supabase E2E seeding requires SNAPGRUB_ALLOW_REMOTE_E2E_SEED=1.",
    );
  }
  if (!passwordFromEnv) {
    throw new Error("Developer Supabase E2E seeding requires E2E_PASSWORD.");
  }
}

const url = process.env.SUPABASE_URL;
const serviceRole = process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.SERVICE_ROLE_KEY;

if (!url || !serviceRole) {
  throw new Error(
    `SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required for ${target} Supabase E2E seeding.`,
  );
}

const localhost = /^http:\/\/(127\.0\.0\.1|localhost|0\.0\.0\.0)(:|\/|$)/.test(
  url,
);
if (target === "developer" && localhost) {
  throw new Error(
    "Developer Supabase E2E cannot use a localhost SUPABASE_URL.",
  );
}
if (target === "local" && !localhost) {
  throw new Error("Local Supabase E2E must use a localhost SUPABASE_URL.");
}

const admin = createClient(url, serviceRole, {
  auth: { autoRefreshToken: false, persistSession: false },
  realtime: { transport: ws },
});

await assertRequiredBuckets();

const existing = await findUserByEmail(email);
if (existing) {
  await removeUserStorage(existing.id);
  const { error } = await admin.auth.admin.deleteUser(existing.id);
  if (error) throw error;
  console.log(`deleted E2E auth user: ${email}`);
}

const { data: created, error: createError } = await admin.auth.admin.createUser(
  {
    email,
    password,
    email_confirm: true,
    user_metadata: {
      purpose: "snapgrub-e2e",
      platform,
      target,
    },
  },
);

if (createError) throw createError;
console.log(`seeded E2E auth user: ${email} (${created.user.id})`);

async function findUserByEmail(userEmail) {
  const perPage = 100;
  for (let page = 1; page < 100; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({
      page,
      perPage,
    });
    if (error) throw error;
    const match = data.users.find(
      (user) => user.email?.toLowerCase() === userEmail.toLowerCase(),
    );
    if (match) return match;
    if (data.users.length < perPage) return null;
  }
  throw new Error("Could not find E2E user after scanning auth user pages.");
}

async function assertRequiredBuckets() {
  const required = new Set([
    "meal-originals-private",
    "meal-thumbnails-private",
    "exports-private",
  ]);
  const { data, error } = await admin.storage.listBuckets();
  if (error) throw error;
  for (const bucket of data ?? []) required.delete(bucket.name);
  if (required.size > 0) {
    throw new Error(
      `Missing required Supabase storage bucket(s): ${
        [...required].join(", ")
      }`,
    );
  }
}

async function removeUserStorage(userId) {
  for (
    const bucket of [
      "meal-originals-private",
      "meal-thumbnails-private",
      "exports-private",
    ]
  ) {
    const paths = await listStoragePaths(bucket, userId);
    if (paths.length === 0) continue;
    const { error } = await admin.storage.from(bucket).remove(paths);
    if (error) throw error;
    console.log(`removed ${paths.length} ${bucket} object(s) for ${email}`);
  }
}

async function listStoragePaths(bucket, prefix) {
  const paths = [];
  await collectStoragePaths(bucket, prefix, paths);
  return paths;
}

async function collectStoragePaths(bucket, prefix, paths) {
  const limit = 100;
  for (let offset = 0;; offset += limit) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, {
      limit,
      offset,
      sortBy: { column: "name", order: "asc" },
    });
    if (error) throw error;
    for (const item of data ?? []) {
      const itemPath = `${prefix}/${item.name}`;
      if (item.id || item.metadata) {
        paths.push(itemPath);
      } else {
        await collectStoragePaths(bucket, itemPath, paths);
      }
    }
    if (!data || data.length < limit) break;
  }
}
