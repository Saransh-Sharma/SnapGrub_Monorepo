import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    requireServiceRole(req);

    const body = await parseBody(req);
    const limit = boundedLimit(body.limit);
    const client = serviceClient();

    const exportCleanup = await cleanupExpiredExports(client, limit);
    const mediaCleanup = await cleanupExpiredMealAssets(client, limit);

    return jsonResponse({
      export_cleanup: exportCleanup,
      media_cleanup: mediaCleanup,
      server_time: new Date().toISOString(),
      request_id: requestId,
    });
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function requireServiceRole(req: Request) {
  const expected = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const auth = req.headers.get("authorization") ?? "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (expected && token === expected) return;
  if (jwtRole(token) === "service_role") return;

  throw new ApiError("AUTH_REQUIRED", "Service role authorization is required", 401, false);
}

function jwtRole(token: string) {
  try {
    const payload = token.split(".")[1];
    if (!payload) return null;
    const base64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, "=");
    const json = JSON.parse(atob(padded));
    return typeof json.role === "string" ? json.role : null;
  } catch (_) {
    return null;
  }
}

async function parseBody(req: Request): Promise<Record<string, unknown>> {
  try {
    return await req.json();
  } catch (_) {
    return {};
  }
}

function boundedLimit(value: unknown) {
  const n = Number(value ?? 500);
  if (!Number.isFinite(n)) return 500;
  return Math.max(1, Math.min(Math.trunc(n), 5000));
}

async function cleanupExpiredExports(client: ReturnType<typeof serviceClient>, limit: number) {
  const { data, error } = await client.rpc("mark_expired_exports_failed", { p_limit: limit });
  if (error) throw error;

  let removed = 0;
  for (const row of data ?? []) {
    const bucket = row.result_storage_bucket ?? "exports-private";
    const path = row.result_storage_path;
    if (!path) continue;
    const { data: deleted, error: removeError } = await client.storage.from(bucket).remove([path]);
    if (removeError) throw removeError;
    removed += deleted?.length ?? 1;
  }

  return {
    expired_requests: data?.length ?? 0,
    removed_objects: removed,
  };
}

async function cleanupExpiredMealAssets(client: ReturnType<typeof serviceClient>, limit: number) {
  const { data, error } = await client.rpc("expired_meal_assets", { p_limit: limit });
  if (error) throw error;

  const markedIds: string[] = [];
  let removed = 0;
  for (const asset of data ?? []) {
    const pathsByBucket = new Map<string, string[]>();
    if (asset.storage_bucket && asset.storage_path) {
      pathsByBucket.set(asset.storage_bucket, [asset.storage_path]);
    }
    if (asset.thumb_storage_path) {
      pathsByBucket.set("meal-thumbnails-private", [asset.thumb_storage_path]);
    }

    for (const [bucket, paths] of pathsByBucket) {
      const { data: deleted, error: removeError } = await client.storage.from(bucket).remove(paths);
      if (removeError) throw removeError;
      removed += deleted?.length ?? paths.length;
    }
    markedIds.push(asset.id);
  }

  if (markedIds.length > 0) {
    const { error: markError } = await client.rpc("mark_meal_assets_deleted", { p_asset_ids: markedIds });
    if (markError) throw markError;
  }

  return {
    expired_assets: data?.length ?? 0,
    removed_objects: removed,
  };
}
