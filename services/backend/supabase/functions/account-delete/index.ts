import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { requireString } from "../_shared/validation.ts";

const STORAGE_BUCKETS = ["meal-originals-private", "meal-thumbnails-private", "exports-private"];

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") throw new ApiError("INVALID_INPUT", "Method not allowed", 405);

    const user = await requireUser(req);
    const body = await parseBody(req);
    const confirmation = requireString(body.confirmation, "confirmation");
    if (confirmation !== "DELETE") {
      throw new ApiError("INVALID_INPUT", "Type DELETE to confirm account deletion", 400, false, {
        field: "confirmation",
      });
    }

    const client = serviceClient();
    await consumeRateLimit(client, user.id, "account:delete", 24 * 60 * 60, 3);
    const { data: deletion, error: insertError } = await client
      .from("account_deletion_requests")
      .insert({
        user_id: user.id,
        requested_by: user.id,
        confirmation,
        status: "processing",
      })
      .select()
      .single();
    if (insertError) throw insertError;

    try {
      const deletedStorageObjects = await deleteUserStorage(client, user.id);
      await client.from("analytics_events").delete().eq("user_id", user.id);

      const { error: authDeleteError } = await client.auth.admin.deleteUser(user.id);
      if (authDeleteError) throw authDeleteError;

      const { data: completed, error: updateError } = await client
        .from("account_deletion_requests")
        .update({
          status: "completed",
          deleted_storage_objects: deletedStorageObjects,
          deleted_at: new Date().toISOString(),
        })
        .eq("id", deletion.id)
        .select()
        .single();
      if (updateError) throw updateError;

      return jsonResponse({
        account_deletion: completed,
        server_time: new Date().toISOString(),
        request_id: requestId,
      });
    } catch (error) {
      await client
        .from("account_deletion_requests")
        .update({
          status: "failed",
          error_code: error instanceof ApiError ? error.code : "UNKNOWN",
          error_message: error instanceof Error ? error.message : "Unknown error",
        })
        .eq("id", deletion.id);
      throw error;
    }
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

async function parseBody(req: Request): Promise<Record<string, unknown>> {
  try {
    return await req.json();
  } catch (_) {
    throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
  }
}

async function deleteUserStorage(client: ReturnType<typeof serviceClient>, userId: string) {
  let deleted = 0;
  const known = await knownStoragePaths(client, userId);

  for (const bucket of STORAGE_BUCKETS) {
    const paths = new Set<string>(known.get(bucket) ?? []);
    for (const listed of await listUserPrefix(client, bucket, userId)) paths.add(listed);
    if (paths.size === 0) continue;

    const { data, error } = await client.storage.from(bucket).remove([...paths]);
    if (error) throw error;
    deleted += data?.length ?? paths.size;
  }

  return deleted;
}

async function knownStoragePaths(client: ReturnType<typeof serviceClient>, userId: string) {
  const byBucket = new Map<string, string[]>();
  const push = (bucket: string | null | undefined, path: string | null | undefined) => {
    if (!bucket || !path) return;
    byBucket.set(bucket, [...(byBucket.get(bucket) ?? []), path]);
  };

  const { data: assets, error: assetError } = await client
    .from("meal_assets")
    .select("storage_bucket, storage_path, thumb_storage_path")
    .eq("user_id", userId);
  if (assetError) throw assetError;
  for (const asset of assets ?? []) {
    push(asset.storage_bucket, asset.storage_path);
    push("meal-thumbnails-private", asset.thumb_storage_path);
  }

  const { data: exports, error: exportError } = await client
    .from("export_requests")
    .select("result_storage_bucket, result_storage_path")
    .eq("user_id", userId);
  if (exportError) throw exportError;
  for (const exportRequest of exports ?? []) {
    push(exportRequest.result_storage_bucket ?? "exports-private", exportRequest.result_storage_path);
  }

  return byBucket;
}

async function listUserPrefix(client: ReturnType<typeof serviceClient>, bucket: string, userId: string) {
  const paths: string[] = [];
  const { data, error } = await client.storage.from(bucket).list(userId, { limit: 1000 });
  if (error) return paths;
  for (const item of data ?? []) {
    if (!item.name) continue;
    paths.push(`${userId}/${item.name}`);
  }
  return paths;
}

async function consumeRateLimit(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  action: string,
  windowSeconds: number,
  maxCount: number,
) {
  const { data, error } = await client.rpc("consume_api_rate_limit", {
    p_user_id: userId,
    p_action: action,
    p_window_seconds: windowSeconds,
    p_max_count: maxCount,
  });
  if (error) throw error;
  if (data !== true) {
    throw new ApiError("CONFLICT", "Too many requests. Please try again later.", 429, true);
  }
}
