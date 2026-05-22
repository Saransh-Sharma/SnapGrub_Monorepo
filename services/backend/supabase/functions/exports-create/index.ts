import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { maybeReplayIdempotency, storeIdempotency } from "../_shared/idempotency.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { requireString } from "../_shared/validation.ts";

const EXPORT_BUCKET = "exports-private";
const EXPORT_TTL_SECONDS = 7 * 24 * 60 * 60;
const SIGNED_URL_TTL_SECONDS = 60 * 60;

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    const user = await requireUser(req);
    const client = serviceClient();

    if (req.method === "GET") {
      const exportId = exportIdFromUrl(req.url);
      const exportRequest = await readOwnedExport(client, user.id, exportId);
      return jsonResponse({
        export_request: await withFreshSignedUrl(client, exportRequest),
        server_time: new Date().toISOString(),
        request_id: requestId,
      });
    }

    if (req.method !== "POST") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    }

    const bodyText = await req.text();
    const body = parseJsonBody(bodyText);
    const clientRequestId = requireString(body.client_request_id, "client_request_id");
    const idempotencyKey = req.headers.get("idempotency-key") ?? clientRequestId;
    const endpoint = "exports:create";
    const replay = await maybeReplayIdempotency(client, user.id, endpoint, idempotencyKey, bodyText);
    if (replay) return jsonResponse(replay.response_body, replay.response_status ?? 202);
    await consumeRateLimit(client, user.id, "exports:create", 60 * 60, 5);

    const exportType = normalizeExportType(body.export_type);
    const exportRequest = await createQueuedRequest(client, user.id, clientRequestId, exportType, body.filters);

    try {
      const artifact = await buildArtifact(client, user.id, exportType);
      const storagePath = `${user.id}/${exportRequest.id}/${artifact.fileName}`;
      const { error: uploadError } = await client.storage
        .from(EXPORT_BUCKET)
        .upload(storagePath, new Blob([artifact.body], { type: artifact.contentType }), {
          contentType: artifact.contentType,
          upsert: true,
        });
      if (uploadError) throw uploadError;

      const signed = await signedUrl(client, storagePath);
      const completed = await updateExport(client, String(exportRequest.id), {
        status: "completed",
        result_storage_bucket: EXPORT_BUCKET,
        result_storage_path: storagePath,
        signed_url: signed.signedUrl,
        signed_url_expires_at: signed.expiresAt,
        expires_at: new Date(Date.now() + EXPORT_TTL_SECONDS * 1000).toISOString(),
        size_bytes: new TextEncoder().encode(artifact.body).length,
        content_type: artifact.contentType,
        row_counts: artifact.rowCounts,
        completed_at: new Date().toISOString(),
      });

      const responseBody = {
        export_request: completed,
        server_time: new Date().toISOString(),
        request_id: requestId,
      };
      await storeIdempotency(client, user.id, endpoint, idempotencyKey, bodyText, 202, responseBody);
      return jsonResponse(responseBody, 202);
    } catch (error) {
      const failed = await updateExport(client, String(exportRequest.id), {
        status: "failed",
        error_code: error instanceof ApiError ? error.code : "UNKNOWN",
      });
      return jsonResponse({
        export_request: failed,
        server_time: new Date().toISOString(),
        request_id: requestId,
      }, 500);
    }
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function parseJsonBody(bodyText: string): Record<string, unknown> {
  if (!bodyText) return {};
  try {
    return JSON.parse(bodyText);
  } catch (_) {
    throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function normalizeExportType(value: unknown) {
  const type = value == null ? "journal_csv" : String(value);
  if (!["journal_csv", "nutrition_json"].includes(type)) {
    throw new ApiError("INVALID_INPUT", "export_type is invalid", 400, false, { field: "export_type" });
  }
  return type;
}

function exportIdFromUrl(url: string) {
  const pathname = new URL(url).pathname;
  const parts = pathname.split("/").filter(Boolean);
  const id = parts[parts.length - 1];
  if (!id || id === "exports-create") {
    throw new ApiError("INVALID_INPUT", "export_request_id is required", 400, false);
  }
  return id;
}

async function createQueuedRequest(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  clientRequestId: string,
  exportType: string,
  filters: unknown,
) {
  const { data, error } = await client
    .from("export_requests")
    .insert({
      user_id: userId,
      client_request_id: clientRequestId,
      export_type: exportType,
      status: "processing",
      filters: isRecord(filters) ? filters : {},
    })
    .select()
    .single();
  if (error) throw mapPostgresError(error);
  return data as Record<string, unknown>;
}

async function readOwnedExport(client: ReturnType<typeof serviceClient>, userId: string, exportId: string) {
  const { data, error } = await client
    .from("export_requests")
    .select("*")
    .eq("id", exportId)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;
  if (!data) throw new ApiError("NOT_FOUND", "Export request not found", 404, false);
  return data as Record<string, unknown>;
}

async function withFreshSignedUrl(client: ReturnType<typeof serviceClient>, exportRequest: Record<string, unknown>) {
  if (exportRequest.status !== "completed" || !exportRequest.result_storage_path) return exportRequest;
  const expiresAt = exportRequest.signed_url_expires_at == null
    ? 0
    : Date.parse(String(exportRequest.signed_url_expires_at));
  if (Number.isFinite(expiresAt) && expiresAt > Date.now() + 60_000 && exportRequest.signed_url) {
    return exportRequest;
  }
  const signed = await signedUrl(client, String(exportRequest.result_storage_path));
  return await updateExport(client, String(exportRequest.id), {
    signed_url: signed.signedUrl,
    signed_url_expires_at: signed.expiresAt,
  });
}

async function updateExport(
  client: ReturnType<typeof serviceClient>,
  id: string,
  values: Record<string, unknown>,
) {
  const { data, error } = await client
    .from("export_requests")
    .update(values)
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return data as Record<string, unknown>;
}

async function signedUrl(client: ReturnType<typeof serviceClient>, storagePath: string) {
  const { data, error } = await client.storage
    .from(EXPORT_BUCKET)
    .createSignedUrl(storagePath, SIGNED_URL_TTL_SECONDS);
  if (error || !data?.signedUrl) throw error ?? new ApiError("UNKNOWN", "Could not create export download link", 500, true);
  return {
    signedUrl: data.signedUrl,
    expiresAt: new Date(Date.now() + SIGNED_URL_TTL_SECONDS * 1000).toISOString(),
  };
}

async function buildArtifact(client: ReturnType<typeof serviceClient>, userId: string, exportType: string) {
  const data = await readExportData(client, userId);
  if (exportType === "journal_csv") {
    return {
      fileName: "journal.csv",
      contentType: "text/csv",
      body: journalCsv(data.meals, data.meal_items),
      rowCounts: rowCounts(data),
    };
  }
  return {
    fileName: "nutrition.json",
    contentType: "application/json",
    body: JSON.stringify({
      exported_at: new Date().toISOString(),
      profile: data.profile,
      active_goals: data.nutrition_goals,
      body_measurements: data.body_measurements,
      meals: data.meals,
      meal_items: data.meal_items,
      custom_foods: data.custom_foods,
      meal_templates: data.meal_templates,
      correction_events: data.correction_events,
      weekly_insights: data.weekly_insights,
    }, null, 2),
    rowCounts: rowCounts(data),
  };
}

async function readExportData(client: ReturnType<typeof serviceClient>, userId: string) {
  const [
    profile,
    nutritionGoals,
    bodyMeasurements,
    meals,
    mealItems,
    customFoods,
    mealTemplates,
    correctionEvents,
    weeklyInsights,
  ] = await Promise.all([
    selectMaybeSingle(client, "profiles", userId),
    selectRows(client, "nutrition_goals", userId),
    selectRows(client, "body_measurements", userId),
    selectRows(client, "meals", userId),
    selectRows(client, "meal_items", userId),
    selectRows(client, "custom_foods", userId),
    selectRows(client, "meal_templates", userId),
    selectRows(client, "correction_events", userId),
    selectRows(client, "weekly_insights", userId),
  ]);

  return {
    profile,
    nutrition_goals: nutritionGoals,
    body_measurements: bodyMeasurements,
    meals,
    meal_items: mealItems,
    custom_foods: customFoods,
    meal_templates: mealTemplates,
    correction_events: correctionEvents,
    weekly_insights: weeklyInsights,
  };
}

async function selectMaybeSingle(client: ReturnType<typeof serviceClient>, table: string, userId: string) {
  const column = table === "profiles" ? "id" : "user_id";
  const { data, error } = await client.from(table).select("*").eq(column, userId).maybeSingle();
  if (error) throw error;
  return data;
}

async function selectRows(client: ReturnType<typeof serviceClient>, table: string, userId: string) {
  const { data, error } = await client.from(table).select("*").eq("user_id", userId);
  if (error) throw error;
  return data ?? [];
}

function rowCounts(data: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, Array.isArray(value) ? value.length : value == null ? 0 : 1]),
  );
}

function journalCsv(meals: Array<Record<string, unknown>>, items: Array<Record<string, unknown>>) {
  const itemMap = new Map<string, Array<Record<string, unknown>>>();
  for (const item of items) {
    const mealId = String(item.meal_id ?? "");
    itemMap.set(mealId, [...(itemMap.get(mealId) ?? []), item]);
  }
  const rows = [
    ["logged_at", "meal_title", "meal_type", "source", "item_name", "quantity", "unit", "calories_kcal", "protein_g", "carbs_g", "fat_g"],
  ];
  for (const meal of meals) {
    const mealItems = itemMap.get(String(meal.id)) ?? [];
    if (mealItems.length === 0) {
      rows.push([
        meal.logged_at, meal.title, meal.meal_type, meal.source, "", "", "",
        meal.calories_kcal, meal.protein_g, meal.carbs_g, meal.fat_g,
      ].map(csvValue));
      continue;
    }
    for (const item of mealItems) {
      rows.push([
        meal.logged_at, meal.title, meal.meal_type, meal.source,
        item.name, item.quantity, item.unit, item.calories_kcal, item.protein_g, item.carbs_g, item.fat_g,
      ].map(csvValue));
    }
  }
  return rows.map((row) => row.join(",")).join("\n") + "\n";
}

function csvValue(value: unknown) {
  const text = value == null ? "" : String(value);
  return `"${text.replaceAll('"', '""')}"`;
}

function mapPostgresError(error: { message?: string; code?: string }) {
  if (error.code === "23505") {
    return new ApiError("IDEMPOTENCY_CONFLICT", error.message ?? "Export request already exists", 409, false);
  }
  if (error.code === "23514" || error.code === "22P02") {
    return new ApiError("INVALID_INPUT", error.message ?? "Invalid export request", 400, false);
  }
  return error;
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
