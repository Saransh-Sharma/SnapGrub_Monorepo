import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import {
  failIdempotency,
  maybeReplayIdempotency,
  storeIdempotency,
} from "../_shared/idempotency.ts";
import { consumeRateLimit } from "../_shared/rate_limit.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { isRecord, parseJsonBody } from "../_shared/request.ts";
import { requireString } from "../_shared/validation.ts";

const EXPORT_BUCKET = "exports-private";
const EXPORT_TTL_SECONDS = 7 * 24 * 60 * 60;
const SIGNED_URL_TTL_SECONDS = 60 * 60;
const EXPORT_PAGE_SIZE = 1000;
const MAX_EXPORT_ROWS_PER_TABLE = 100_000;

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

    const { body, bodyText } = await parseJsonBody(req);
    const clientRequestId = requireString(
      body.client_request_id,
      "client_request_id",
    );
    const idempotencyKey = idempotencyKeyFor(req, clientRequestId);
    const endpoint = "exports:create";
    const exportType = normalizeExportType(body.export_type);
    const replay = await maybeReplayIdempotency(
      client,
      user.id,
      endpoint,
      idempotencyKey,
      bodyText,
    );
    if (replay) {
      return jsonResponse(replay.response_body, replay.response_status ?? 202);
    }
    await consumeRateLimit(client, user.id, "exports:create", 60 * 60, 5);

    const exportRequest = await createQueuedRequest(
      client,
      user.id,
      clientRequestId,
      exportType,
      body.filters,
    );

    try {
      const artifact = await buildArtifact(
        client,
        user.id,
        exportType,
        body.filters,
      );
      const storagePath = `${user.id}/${exportRequest.id}/${artifact.fileName}`;
      const { error: uploadError } = await client.storage
        .from(EXPORT_BUCKET)
        .upload(
          storagePath,
          new Blob([artifact.body], { type: artifact.contentType }),
          {
            contentType: artifact.contentType,
            upsert: true,
          },
        );
      if (uploadError) throw uploadError;

      const signed = await signedUrl(client, storagePath);
      const completed = await updateExport(client, String(exportRequest.id), {
        status: "completed",
        result_storage_bucket: EXPORT_BUCKET,
        result_storage_path: storagePath,
        signed_url: signed.signedUrl,
        signed_url_expires_at: signed.expiresAt,
        expires_at: new Date(Date.now() + EXPORT_TTL_SECONDS * 1000)
          .toISOString(),
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
      await storeIdempotency(
        client,
        user.id,
        endpoint,
        idempotencyKey,
        bodyText,
        202,
        responseBody,
      );
      return jsonResponse(responseBody, 202);
    } catch (error) {
      const status = error instanceof ApiError ? error.status : 500;
      const failed = await updateExport(client, String(exportRequest.id), {
        status: "failed",
        error_code: error instanceof ApiError ? error.code : "UNKNOWN",
      });
      const responseBody = {
        export_request: failed,
        server_time: new Date().toISOString(),
        request_id: requestId,
      };
      await failIdempotency(
        client,
        user.id,
        endpoint,
        idempotencyKey,
        bodyText,
        status,
        responseBody,
      );
      return jsonResponse(responseBody, status);
    }
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function normalizeExportType(value: unknown) {
  const type = value == null ? "journal_csv" : String(value);
  if (!["journal_csv", "nutrition_json"].includes(type)) {
    throw new ApiError("INVALID_INPUT", "export_type is invalid", 400, false, {
      field: "export_type",
    });
  }
  return type;
}

function idempotencyKeyFor(req: Request, clientRequestId: string) {
  const header = req.headers.get("idempotency-key")?.trim();
  return header && header.length > 0 ? header : clientRequestId;
}

function exportIdFromUrl(url: string) {
  const pathname = new URL(url).pathname;
  const parts = pathname.split("/").filter(Boolean);
  const id = parts[parts.length - 1];
  if (!id || id === "exports-create") {
    throw new ApiError(
      "INVALID_INPUT",
      "export_request_id is required",
      400,
      false,
    );
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

async function readOwnedExport(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  exportId: string,
) {
  const { data, error } = await client
    .from("export_requests")
    .select("*")
    .eq("id", exportId)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;
  if (!data) {
    throw new ApiError("NOT_FOUND", "Export request not found", 404, false);
  }
  return data as Record<string, unknown>;
}

async function withFreshSignedUrl(
  client: ReturnType<typeof serviceClient>,
  exportRequest: Record<string, unknown>,
) {
  if (
    exportRequest.status !== "completed" || !exportRequest.result_storage_path
  ) return exportRequest;
  const expiresAt = exportRequest.signed_url_expires_at == null
    ? 0
    : Date.parse(String(exportRequest.signed_url_expires_at));
  if (
    Number.isFinite(expiresAt) && expiresAt > Date.now() + 60_000 &&
    exportRequest.signed_url
  ) {
    return exportRequest;
  }
  const signed = await signedUrl(
    client,
    String(exportRequest.result_storage_path),
  );
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

async function signedUrl(
  client: ReturnType<typeof serviceClient>,
  storagePath: string,
) {
  const { data, error } = await client.storage
    .from(EXPORT_BUCKET)
    .createSignedUrl(storagePath, SIGNED_URL_TTL_SECONDS);
  if (error || !data?.signedUrl) {
    throw error ??
      new ApiError(
        "UNKNOWN",
        "Could not create export download link",
        500,
        true,
      );
  }
  return {
    signedUrl: data.signedUrl,
    expiresAt: new Date(Date.now() + SIGNED_URL_TTL_SECONDS * 1000)
      .toISOString(),
  };
}

async function buildArtifact(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  exportType: string,
  filters: unknown,
) {
  const data = await readExportData(client, userId, exportFilters(filters));
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
    body: JSON.stringify(
      {
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
      },
      null,
      2,
    ),
    rowCounts: rowCounts(data),
  };
}

async function readExportData(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  filters: ExportFilters,
) {
  const [
    profile,
    nutritionGoals,
    bodyMeasurements,
    meals,
    customFoods,
    mealTemplates,
    correctionEvents,
    weeklyInsights,
  ] = await Promise.all([
    selectMaybeSingle(client, "profiles", userId),
    selectRows(client, "nutrition_goals", userId),
    selectRows(client, "body_measurements", userId, filters, "measured_at"),
    selectRows(client, "meals", userId, filters, "logged_at"),
    selectRows(client, "custom_foods", userId),
    selectRows(client, "meal_templates", userId),
    selectRows(client, "correction_events", userId),
    selectRows(client, "weekly_insights", userId),
  ]);
  const mealItems = await selectMealItemsForMeals(
    client,
    userId,
    meals.map((meal) => String(meal["id"])),
  );

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

async function selectMaybeSingle(
  client: ReturnType<typeof serviceClient>,
  table: string,
  userId: string,
) {
  const column = table === "profiles" ? "id" : "user_id";
  const { data, error } = await client.from(table).select("*").eq(
    column,
    userId,
  ).maybeSingle();
  if (error) throw error;
  return data;
}

type ExportFilters = {
  from: string | null;
  to: string | null;
};

function exportFilters(filters: unknown): ExportFilters {
  if (!isRecord(filters)) return { from: null, to: null };
  return {
    from: isoOrNull(filters.logged_at_from ?? filters.from),
    to: isoOrNull(filters.logged_at_to ?? filters.to),
  };
}

function isoOrNull(value: unknown) {
  if (typeof value !== "string" || Number.isNaN(Date.parse(value))) return null;
  return new Date(value).toISOString();
}

async function selectRows(
  client: ReturnType<typeof serviceClient>,
  table: string,
  userId: string,
  filters: ExportFilters = { from: null, to: null },
  timestampColumn: string | null = null,
) {
  const rows: Array<Record<string, unknown>> = [];
  for (let from = 0;; from += EXPORT_PAGE_SIZE) {
    let query = client
      .from(table)
      .select("*")
      .eq("user_id", userId)
      .order("id", { ascending: true })
      .range(from, from + EXPORT_PAGE_SIZE - 1);
    if (timestampColumn && filters.from) {
      query = query.gte(timestampColumn, filters.from);
    }
    if (timestampColumn && filters.to) {
      query = query.lt(timestampColumn, filters.to);
    }
    const { data, error } = await query;
    if (error) throw error;
    const page = data ?? [];
    rows.push(...page);
    if (rows.length > MAX_EXPORT_ROWS_PER_TABLE) {
      throw new ApiError(
        "CONFLICT",
        `${table} export is too large for synchronous generation`,
        413,
        false,
        {
          table,
          max_rows: MAX_EXPORT_ROWS_PER_TABLE,
        },
      );
    }
    if (page.length < EXPORT_PAGE_SIZE) return rows;
  }
}

async function selectMealItemsForMeals(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  mealIds: string[],
) {
  if (mealIds.length === 0) return [];
  const rows: Array<Record<string, unknown>> = [];
  for (let index = 0; index < mealIds.length; index += EXPORT_PAGE_SIZE) {
    const batch = mealIds.slice(index, index + EXPORT_PAGE_SIZE);
    const { data, error } = await client
      .from("meal_items")
      .select("*")
      .eq("user_id", userId)
      .in("meal_id", batch)
      .order("meal_id", { ascending: true })
      .order("position", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    rows.push(...(data ?? []));
    if (rows.length > MAX_EXPORT_ROWS_PER_TABLE) {
      throw new ApiError(
        "CONFLICT",
        "meal_items export is too large for synchronous generation",
        413,
        false,
        {
          table: "meal_items",
          max_rows: MAX_EXPORT_ROWS_PER_TABLE,
        },
      );
    }
  }
  return rows;
}

function rowCounts(data: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(data).map((
      [key, value],
    ) => [key, Array.isArray(value) ? value.length : value == null ? 0 : 1]),
  );
}

function journalCsv(
  meals: Array<Record<string, unknown>>,
  items: Array<Record<string, unknown>>,
) {
  const itemMap = new Map<string, Array<Record<string, unknown>>>();
  for (const item of items) {
    const mealId = String(item.meal_id ?? "");
    itemMap.set(mealId, [...(itemMap.get(mealId) ?? []), item]);
  }
  const rows = [
    [
      "logged_at",
      "meal_title",
      "meal_type",
      "source",
      "item_name",
      "quantity",
      "unit",
      "calories_kcal",
      "protein_g",
      "carbs_g",
      "fat_g",
    ],
  ];
  for (const meal of meals) {
    const mealItems = itemMap.get(String(meal.id)) ?? [];
    if (mealItems.length === 0) {
      rows.push([
        meal.logged_at,
        meal.title,
        meal.meal_type,
        meal.source,
        "",
        "",
        "",
        meal.calories_kcal,
        meal.protein_g,
        meal.carbs_g,
        meal.fat_g,
      ].map(csvValue));
      continue;
    }
    for (const item of mealItems) {
      rows.push([
        meal.logged_at,
        meal.title,
        meal.meal_type,
        meal.source,
        item.name,
        item.quantity,
        item.unit,
        item.calories_kcal,
        item.protein_g,
        item.carbs_g,
        item.fat_g,
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
    return new ApiError(
      "IDEMPOTENCY_CONFLICT",
      error.message ?? "Export request already exists",
      409,
      false,
    );
  }
  if (error.code === "23514" || error.code === "22P02") {
    return new ApiError(
      "INVALID_INPUT",
      error.message ?? "Invalid export request",
      400,
      false,
    );
  }
  return error;
}
