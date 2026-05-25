import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { errorBody, errorStatus, logError } from "../_shared/errors.ts";
import { requireMethod, requireServiceRole } from "../_shared/request.ts";
import { serviceClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    requireMethod(req, "POST");
    requireServiceRole(req);

    const body = await parseBody(req);
    const limit = boundedLimit(body.limit);
    const client = serviceClient();
    const jobRun = await startJobRun(
      client,
      "media-retention-cleanup",
      requestId,
    );

    try {
      const exportCleanup = await cleanupExpiredExports(client, limit);
      const mediaCleanup = await cleanupExpiredMealAssets(client, limit);
      await completeJobRun(client, jobRun.id, "completed", {
        export_cleanup: exportCleanup,
        media_cleanup: mediaCleanup,
      });

      return jsonResponse({
        export_cleanup: exportCleanup,
        media_cleanup: mediaCleanup,
        server_time: new Date().toISOString(),
        request_id: requestId,
      });
    } catch (error) {
      try {
        await completeJobRun(
          client,
          jobRun.id,
          "failed",
          {},
          errorSummary(error),
        );
      } catch (completeError) {
        logError(
          "media-retention-cleanup.complete-failed",
          requestId,
          completeError,
        );
      }
      throw error;
    }
  } catch (error) {
    logError("media-retention-cleanup", requestId, error);
    return jsonResponse(errorBody(error, requestId), errorStatus(error));
  }
});

async function parseBody(req: Request): Promise<Record<string, unknown>> {
  try {
    return await req.json();
  } catch (_) {
    return {};
  }
}

async function startJobRun(
  client: ReturnType<typeof serviceClient>,
  jobName: string,
  requestId: string,
) {
  const { data, error } = await client
    .from("job_runs")
    .insert({ job_name: jobName, request_id: requestId, status: "running" })
    .select("id")
    .single();
  if (error) throw error;
  return data;
}

async function completeJobRun(
  client: ReturnType<typeof serviceClient>,
  id: string,
  status: "completed" | "failed",
  counts: Record<string, unknown>,
  errorSummaryPayload: Record<string, unknown> = {},
) {
  const { error } = await client
    .from("job_runs")
    .update({
      status,
      completed_at: new Date().toISOString(),
      counts,
      error_summary: errorSummaryPayload,
    })
    .eq("id", id);
  if (error) throw error;
}

function errorSummary(error: unknown) {
  return {
    message: error instanceof Error ? error.message : "Unknown error",
  };
}

function boundedLimit(value: unknown) {
  const n = Number(value ?? 500);
  if (!Number.isFinite(n)) return 500;
  return Math.max(1, Math.min(Math.trunc(n), 5000));
}

async function cleanupExpiredExports(
  client: ReturnType<typeof serviceClient>,
  limit: number,
) {
  const { data, error } = await client.rpc("expired_export_artifacts", {
    p_limit: limit,
  });
  if (error) throw error;

  let removed = 0;
  const expiredIds: string[] = [];
  for (const row of data ?? []) {
    const bucket = row.result_storage_bucket ?? "exports-private";
    const path = row.result_storage_path;
    expiredIds.push(row.id);
    if (!path) continue;
    const { data: deleted, error: removeError } = await client.storage.from(
      bucket,
    ).remove([path]);
    if (removeError) throw removeError;
    removed += deleted?.length ?? 1;
  }

  if (expiredIds.length > 0) {
    const { error: markError } = await client.rpc("mark_exports_expired", {
      p_export_ids: expiredIds,
    });
    if (markError) throw markError;
  }

  return {
    expired_requests: data?.length ?? 0,
    removed_objects: removed,
  };
}

async function cleanupExpiredMealAssets(
  client: ReturnType<typeof serviceClient>,
  limit: number,
) {
  const { data, error } = await client.rpc("expired_meal_assets", {
    p_limit: limit,
  });
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
      const { data: deleted, error: removeError } = await client.storage.from(
        bucket,
      ).remove(paths);
      if (removeError) throw removeError;
      removed += deleted?.length ?? paths.length;
    }
    markedIds.push(asset.id);
  }

  if (markedIds.length > 0) {
    const { error: markError } = await client.rpc("mark_meal_assets_deleted", {
      p_asset_ids: markedIds,
    });
    if (markError) throw markError;
  }

  return {
    expired_assets: data?.length ?? 0,
    removed_objects: removed,
  };
}
