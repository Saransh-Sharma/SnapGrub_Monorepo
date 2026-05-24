import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { consumeRateLimit } from "../_shared/rate_limit.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { optionalString, requireString } from "../_shared/validation.ts";
import { analyzePhoto, estimatedCost } from "../_shared/photo_analysis.ts";

const PHOTO_BUCKET = "meal-originals-private";
const ALLOWED_IMAGE_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    }
    const user = await requireUser(req);
    const client = serviceClient();
    const body = await parseBody(req);
    const clientRequestId = requireString(
      body.client_request_id,
      "client_request_id",
    );
    const storageBucket = optionalString(body.storage_bucket) ??
      "meal-originals-private";
    const storagePath = requireString(body.storage_path, "storage_path");
    const thumbStoragePath = optionalString(body.thumb_storage_path);
    const mimeType = optionalString(body.mime_type) ?? "image/jpeg";

    assertAllowedStorageBucket(storageBucket);
    assertOwnStoragePath(user.id, storagePath);
    if (thumbStoragePath) {
      assertOwnStoragePath(user.id, thumbStoragePath, "thumb_storage_path");
    }
    const existing = await readExistingJob(client, user.id, clientRequestId);
    if (existing) {
      return jsonResponse(await responseForJob(client, existing, requestId));
    }
    await consumeRateLimit(client, user.id, "analysis:photo", 60 * 60, 30);

    const image = await downloadImage(
      client,
      storageBucket,
      storagePath,
      mimeType,
    );
    const profile = await readProfilePrivacy(client, user.id);
    const asset = await upsertAsset(client, {
      userId: user.id,
      storageBucket,
      storagePath,
      thumbStoragePath,
      sha256: optionalString(body.asset_sha256) ?? await sha256Hex(image.bytes),
      mimeType,
      width: numberOrNull(body.width),
      height: numberOrNull(body.height),
      sizeBytes: numberOrNull(body.size_bytes) ?? image.bytes.byteLength,
      retentionUntil: retentionUntilFor(profile),
    });

    const { data: job, error: jobError } = await client
      .from("analysis_jobs")
      .insert({
        user_id: user.id,
        client_request_id: clientRequestId,
        analysis_mode: "photo",
        status: "processing",
        asset_id: asset.id,
        input_payload: body,
      })
      .select("*")
      .single();
    if (jobError) throw jobError;

    const startedAt = performance.now();
    let invocationId: string | null = null;
    try {
      const providerResult = await analyzePhoto({
        imageBytes: image.bytes,
        mimeType,
        locale: requireString(body.locale, "locale"),
        timezone: requireString(body.timezone, "timezone"),
        mealTypeHint: optionalString(body.meal_type_hint),
        cuisineHints: Array.isArray(body.cuisine_hints)
          ? body.cuisine_hints.map(String)
          : [],
        userHintText: optionalString(body.user_hint_text),
      });
      const latencyMs = Math.round(performance.now() - startedAt);
      const cost = estimatedCost(
        providerResult.inputTokens,
        providerResult.outputTokens,
      );
      invocationId = await insertInvocation(client, {
        analysisJobId: job.id,
        userId: user.id,
        provider: providerResult.provider,
        modelName: providerResult.model,
        status: "completed",
        latencyMs,
        inputTokens: providerResult.inputTokens,
        outputTokens: providerResult.outputTokens,
        estimatedCostUsd: cost,
        requestPayload: {
          locale: body.locale,
          timezone: body.timezone,
          meal_type_hint: body.meal_type_hint,
        },
        responsePayload: providerResult.raw,
      });
      const resultPayload = {
        ...providerResult.result,
        provenance: {
          ...providerResult.result.provenance,
          invocation_id: invocationId,
          asset_id: asset.id,
          storage_bucket: storageBucket,
          storage_path: storagePath,
        },
      };

      const { data: revision, error: revisionError } = await client
        .from("analysis_revisions")
        .insert({
          analysis_job_id: job.id,
          user_id: user.id,
          revision_no: 1,
          title: providerResult.result.title,
          meal_type: providerResult.result.meal_type,
          calories_kcal: providerResult.result.total.calories_kcal,
          protein_g: providerResult.result.total.protein_g,
          carbs_g: providerResult.result.total.carbs_g,
          fat_g: providerResult.result.total.fat_g,
          confidence_overall: providerResult.result.confidence.overall,
          confidence_breakdown: providerResult.result.confidence,
          warnings: providerResult.result.confidence.warnings.map((warning) =>
            warning.message
          ),
          provenance: resultPayload.provenance,
          result_payload: resultPayload,
        })
        .select("*")
        .single();
      if (revisionError) throw revisionError;

      await insertCandidates(
        client,
        revision.id,
        providerResult.result.alternatives,
      );
      const { data: completedJob, error: updateError } = await client
        .from("analysis_jobs")
        .update({
          status: "completed",
          provider: providerResult.provider,
          model_name: providerResult.model,
          latency_ms: latencyMs,
          completed_at: new Date().toISOString(),
        })
        .eq("id", job.id)
        .select("*")
        .single();
      if (updateError) throw updateError;

      return jsonResponse(
        await responseForJob(client, completedJob, requestId),
      );
    } catch (error) {
      const latencyMs = Math.round(performance.now() - startedAt);
      const apiError = error instanceof ApiError ? error : null;
      if (!invocationId) {
        await insertInvocation(client, {
          analysisJobId: job.id,
          userId: user.id,
          provider: Deno.env.get("AI_PROVIDER") ?? "gemini",
          modelName: Deno.env.get("GEMINI_PRIMARY_MODEL") ??
            "gemini-3.1-flash-lite",
          status: "failed",
          latencyMs,
          inputTokens: null,
          outputTokens: null,
          estimatedCostUsd: null,
          errorCode: apiError?.code ?? "UNKNOWN",
          requestPayload: {
            locale: body.locale,
            timezone: body.timezone,
            meal_type_hint: body.meal_type_hint,
          },
          responsePayload: apiError?.details ?? {},
        });
      }
      const { data: failedJob } = await client
        .from("analysis_jobs")
        .update({
          status: "failed",
          latency_ms: latencyMs,
          error_code: apiError?.code ?? "UNKNOWN",
          completed_at: new Date().toISOString(),
        })
        .eq("id", job.id)
        .select("*")
        .single();
      if (apiError && apiError.status < 500) {
        return jsonResponse(
          await responseForJob(client, failedJob ?? job, requestId),
        );
      }
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
    throw new ApiError(
      "INVALID_INPUT",
      "Request body must be valid JSON",
      400,
      false,
    );
  }
}

function assertOwnStoragePath(
  userId: string,
  storagePath: string,
  field = "storage_path",
) {
  if (storagePath.split("/")[0] !== userId) {
    throw new ApiError(
      "INVALID_INPUT",
      `${field} must be under the authenticated user prefix`,
      400,
      false,
      { field },
    );
  }
}

function assertAllowedStorageBucket(storageBucket: string) {
  if (storageBucket !== PHOTO_BUCKET) {
    throw new ApiError(
      "INVALID_INPUT",
      "storage_bucket is not allowed for photo analysis",
      400,
      false,
      { field: "storage_bucket" },
    );
  }
}

async function readExistingJob(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  clientRequestId: string,
) {
  const { data, error } = await client
    .from("analysis_jobs")
    .select("*")
    .eq("user_id", userId)
    .eq("client_request_id", clientRequestId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function downloadImage(
  client: ReturnType<typeof serviceClient>,
  bucket: string,
  path: string,
  requestedMimeType: string,
) {
  const { data, error } = await client.storage.from(bucket).download(path);
  if (error || !data) {
    throw new ApiError("NOT_FOUND", "Uploaded image was not found", 404, false);
  }
  const actualMimeType = data.type || requestedMimeType;
  if (
    !ALLOWED_IMAGE_TYPES.has(actualMimeType) ||
    !ALLOWED_IMAGE_TYPES.has(requestedMimeType)
  ) {
    throw new ApiError(
      "INVALID_INPUT",
      "Uploaded image type is not supported",
      400,
      false,
      {
        mime_type: actualMimeType,
      },
    );
  }
  return { bytes: new Uint8Array(await data.arrayBuffer()) };
}

async function upsertAsset(
  client: ReturnType<typeof serviceClient>,
  asset: {
    userId: string;
    storageBucket: string;
    storagePath: string;
    thumbStoragePath: string | null;
    sha256: string;
    mimeType: string;
    width: number | null;
    height: number | null;
    sizeBytes: number | null;
    retentionUntil: string | null;
  },
) {
  const { data, error } = await client
    .from("meal_assets")
    .upsert({
      user_id: asset.userId,
      storage_bucket: asset.storageBucket,
      storage_path: asset.storagePath,
      thumb_storage_path: asset.thumbStoragePath,
      sha256: asset.sha256,
      mime_type: asset.mimeType,
      width: asset.width,
      height: asset.height,
      size_bytes: asset.sizeBytes,
      retention_until: asset.retentionUntil,
    }, { onConflict: "storage_bucket,storage_path" })
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

async function readProfilePrivacy(
  client: ReturnType<typeof serviceClient>,
  userId: string,
) {
  const { data, error } = await client
    .from("profiles")
    .select("cloud_media_storage, save_original_photos")
    .eq("id", userId)
    .maybeSingle();
  if (error) throw error;
  return {
    cloudMediaStorage: data?.cloud_media_storage === true,
    saveOriginalPhotos: data?.save_original_photos === true,
  };
}

function retentionUntilFor(
  profile: { cloudMediaStorage: boolean; saveOriginalPhotos: boolean },
) {
  if (profile.cloudMediaStorage && profile.saveOriginalPhotos) return null;
  return new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
}

async function responseForJob(
  client: ReturnType<typeof serviceClient>,
  job: Record<string, unknown>,
  requestId: string,
) {
  const { data: revision, error } = await client
    .from("analysis_revisions")
    .select("result_payload")
    .eq("analysis_job_id", job.id as string)
    .order("revision_no", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return {
    analysis_id: job.id,
    asset_id: job.asset_id ?? null,
    status: job.status,
    result: revision?.result_payload ?? null,
    error_code: job.error_code ?? null,
    retryable: job.status === "failed",
    server_time: new Date().toISOString(),
    request_id: requestId,
  };
}

async function insertInvocation(
  client: ReturnType<typeof serviceClient>,
  invocation: {
    analysisJobId: string;
    userId: string;
    provider: string;
    modelName: string;
    status: "completed" | "failed";
    latencyMs: number;
    inputTokens: number | null;
    outputTokens: number | null;
    estimatedCostUsd: number | null;
    errorCode?: string;
    requestPayload: Record<string, unknown>;
    responsePayload: Record<string, unknown> | null;
  },
) {
  const { data, error } = await client
    .from("model_invocations")
    .insert({
      analysis_job_id: invocation.analysisJobId,
      user_id: invocation.userId,
      provider: invocation.provider,
      model_name: invocation.modelName,
      status: invocation.status,
      latency_ms: invocation.latencyMs,
      input_tokens: invocation.inputTokens,
      output_tokens: invocation.outputTokens,
      estimated_cost_usd: invocation.estimatedCostUsd,
      error_code: invocation.errorCode ?? null,
      request_payload: invocation.requestPayload,
      response_payload: invocation.responsePayload,
    })
    .select("id")
    .single();
  if (error) throw error;
  return data.id as string;
}

async function insertCandidates(
  client: ReturnType<typeof serviceClient>,
  revisionId: string,
  alternatives: Record<string, unknown>[],
) {
  if (alternatives.length === 0) return;
  const { error } = await client.from("analysis_candidates").insert(
    alternatives.map((alternative, index) => ({
      analysis_revision_id: revisionId,
      rank: index + 1,
      candidate_title: typeof alternative.title === "string"
        ? alternative.title
        : null,
      confidence: typeof alternative.confidence === "number"
        ? alternative.confidence
        : null,
      payload: alternative,
    })),
  );
  if (error) throw error;
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

async function sha256Hex(bytes: Uint8Array) {
  const digest = await crypto.subtle.digest("SHA-256", bytes as BufferSource);
  return [...new Uint8Array(digest)].map((byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}
