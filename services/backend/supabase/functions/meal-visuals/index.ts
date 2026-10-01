import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import {
  consumeDailyImageBudget,
  imagePriceUsd,
  insertInvocation,
} from "../_shared/model_invocations.ts";
import { consumeRateLimit } from "../_shared/rate_limit.ts";
import { isRecord, parseJsonBody } from "../_shared/request.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { requireString } from "../_shared/validation.ts";

const BUCKET = "meal-generated-private";
const SIGNED_URL_TTL_SECONDS = 60 * 60;
const STYLE_VERSION = "studio-v1";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    const user = await requireUser(req);
    const client = serviceClient();

    if (req.method === "GET") {
      const visualId = idFromPath(req.url);
      const visual = await ownedVisual(client, user.id, visualId);
      return jsonResponse({
        meal_visual: await withSignedUrls(client, visual),
        request_id: requestId,
      });
    }
    if (req.method !== "POST") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    }

    const { body } = await parseJsonBody(req);
    const mealId = requireString(body.meal_id, "meal_id");
    const signature = requireString(
      body.prompt_signature,
      "prompt_signature",
    );
    const visualId = typeof body.visual_id === "string"
      ? body.visual_id
      : crypto.randomUUID();
    await consumeRateLimit(client, user.id, "meal-visuals:create", 60 * 60, 20);

    const meal = await ownedMeal(client, user.id, mealId);
    const existing = await existingVisual(client, mealId, signature);
    if (existing?.status === "ready") {
      return jsonResponse({
        meal_visual: await withSignedUrls(client, existing),
        request_id: requestId,
      }, 200);
    }

    const visual = existing ?? await createQueuedVisual(client, {
      id: visualId,
      meal_id: mealId,
      user_id: user.id,
      prompt_signature: signature,
      style_version: typeof body.style_version === "string"
        ? body.style_version
        : STYLE_VERSION,
    });
    if (imageProviderConfigured()) {
      await consumeDailyImageBudget(client, user.id);
    }
    const claimed = await updateVisual(client, String(visual.id), {
      status: "generating",
      error_code: null,
    });

    const startedAt = performance.now();
    try {
      const items = await mealItems(client, user.id, mealId);
      const prompt = studioPrompt(meal, items);
      const generated = await generateArtwork(prompt);
      await logGeneration(client, {
        userId: user.id,
        provider: generated.provider,
        model: generated.model,
        status: "completed",
        latencyMs: Math.round(performance.now() - startedAt),
      });
      const extension = generated.mimeType.includes("png") ? "png" : "jpg";
      const storagePath = `${user.id}/${mealId}/${signature}.${extension}`;
      const thumbPath = `${user.id}/${mealId}/${signature}-thumb.${extension}`;
      await upload(client, storagePath, generated.bytes, generated.mimeType);
      await upload(client, thumbPath, generated.bytes, generated.mimeType);
      const completed = await updateVisual(client, String(claimed.id), {
        status: "ready",
        provider: generated.provider,
        model_name: generated.model,
        storage_bucket: BUCKET,
        storage_path: storagePath,
        thumb_storage_path: thumbPath,
        dominant_color: dominantColor(signature),
        error_code: null,
      });
      return jsonResponse({
        meal_visual: await withSignedUrls(client, completed),
        request_id: requestId,
      }, 202);
    } catch (error) {
      await updateVisual(client, String(claimed.id), {
        status: "failed",
        retry_count: Number(claimed.retry_count ?? 0) + 1,
        error_code: providerErrorCode(error),
      });
      if (imageProviderConfigured()) {
        await logGeneration(client, {
          userId: user.id,
          provider: "image",
          model: "unknown",
          status: "failed",
          latencyMs: Math.round(performance.now() - startedAt),
          errorCode: providerErrorCode(error),
        });
      }
      throw error;
    }
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

async function generateArtwork(prompt: string) {
  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  if (geminiKey) {
    try {
      const model = Deno.env.get("GEMINI_IMAGE_MODEL") ??
        "gemini-3.1-flash-image";
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "x-goog-api-key": geminiKey,
          },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              responseModalities: ["IMAGE"],
              imageConfig: { aspectRatio: "4:5" },
            },
          }),
          signal: AbortSignal.timeout(90_000),
        },
      );
      if (!response.ok) {
        throw new Error(`Gemini image error ${response.status}`);
      }
      const body = await response.json();
      const parts = body?.candidates?.[0]?.content?.parts ?? [];
      const image = parts.find((part: Record<string, unknown>) =>
        isRecord(part.inlineData) && typeof part.inlineData.data === "string"
      )?.inlineData;
      if (!image?.data) throw new Error("Gemini returned no image");
      return {
        bytes: decodeBase64(image.data),
        mimeType: image.mimeType ?? "image/jpeg",
        provider: "google",
        model,
      };
    } catch (error) {
      if (!Deno.env.get("OPENAI_API_KEY")) throw error;
    }
  }

  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  if (!openAiKey) {
    throw new ApiError(
      "PROVIDER_UNAVAILABLE",
      "Meal artwork will be retried later",
      503,
      true,
    );
  }
  const model = Deno.env.get("OPENAI_IMAGE_MODEL") ?? "gpt-image-2";
  const response = await fetch("https://api.openai.com/v1/images/generations", {
    method: "POST",
    headers: {
      authorization: `Bearer ${openAiKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model,
      prompt,
      size: "1024x1536",
      quality: "low",
      output_format: "jpeg",
    }),
    signal: AbortSignal.timeout(90_000),
  });
  if (!response.ok) throw new Error(`OpenAI image error ${response.status}`);
  const body = await response.json();
  const encoded = body?.data?.[0]?.b64_json;
  if (typeof encoded !== "string") throw new Error("OpenAI returned no image");
  return {
    bytes: decodeBase64(encoded),
    mimeType: "image/jpeg",
    provider: "openai",
    model,
  };
}

function imageProviderConfigured() {
  return Boolean(
    Deno.env.get("GEMINI_API_KEY") || Deno.env.get("OPENAI_API_KEY"),
  );
}

/// Cost visibility for artwork. Never fails the request.
async function logGeneration(
  client: ReturnType<typeof serviceClient>,
  input: {
    userId: string;
    provider: string;
    model: string;
    status: "completed" | "failed";
    latencyMs: number;
    errorCode?: string;
  },
) {
  try {
    await insertInvocation(client, {
      analysisJobId: null,
      userId: input.userId,
      provider: input.provider,
      modelName: input.model,
      purpose: "meal_visual",
      status: input.status,
      latencyMs: input.latencyMs,
      inputTokens: null,
      outputTokens: null,
      estimatedCostUsd: input.status === "completed" ? imagePriceUsd() : null,
      errorCode: input.errorCode,
      requestPayload: {},
      responsePayload: null,
    });
  } catch (error) {
    console.error(JSON.stringify({
      level: "error",
      scope: "meal-visuals.invocation",
      message: error instanceof Error ? error.message : String(error),
    }));
  }
}

function studioPrompt(
  meal: Record<string, unknown>,
  items: Array<Record<string, unknown>>,
) {
  const components = items.map((item) => ({
    name: item.name,
    quantity: item.quantity,
    unit: item.unit,
  }));
  return [
    "Create one polished 4:5 editorial studio food photograph.",
    `Meal: ${String(meal.title ?? "A plated meal")}.`,
    `Visible components: ${JSON.stringify(components)}.`,
    "Warm pale-stone surface, soft directional daylight, gentle natural shadow, elevated three-quarter view, refined but believable plating, quiet porcelain palette.",
    "Keep the food recognizable and portionally plausible. No people, hands, labels, logos, packages, watermarks, borders, captions, letters, or text.",
    `Art direction version: ${STYLE_VERSION}.`,
  ].join(" ");
}

async function ownedMeal(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  mealId: string,
) {
  const { data, error } = await client.from("meals").select("*")
    .eq("id", mealId).eq("user_id", userId).is("deleted_at", null)
    .maybeSingle();
  if (error) throw error;
  if (!data) throw new ApiError("NOT_FOUND", "Meal not found", 404, false);
  return data as Record<string, unknown>;
}

async function mealItems(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  mealId: string,
) {
  const { data, error } = await client.from("meal_items").select(
    "name,quantity,unit,position",
  ).eq("user_id", userId).eq("meal_id", mealId).order("position");
  if (error) throw error;
  return (data ?? []) as Array<Record<string, unknown>>;
}

async function existingVisual(
  client: ReturnType<typeof serviceClient>,
  mealId: string,
  signature: string,
) {
  const { data, error } = await client.from("meal_visuals").select("*")
    .eq("meal_id", mealId).eq("prompt_signature", signature).maybeSingle();
  if (error) throw error;
  return data as Record<string, unknown> | null;
}

async function ownedVisual(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  id: string,
) {
  const { data, error } = await client.from("meal_visuals").select("*")
    .eq("id", id).eq("user_id", userId).maybeSingle();
  if (error) throw error;
  if (!data) {
    throw new ApiError("NOT_FOUND", "Meal artwork not found", 404, false);
  }
  return data as Record<string, unknown>;
}

async function createQueuedVisual(
  client: ReturnType<typeof serviceClient>,
  values: Record<string, unknown>,
) {
  const { data, error } = await client.from("meal_visuals").insert(values)
    .select().single();
  if (error) throw error;
  return data as Record<string, unknown>;
}

async function updateVisual(
  client: ReturnType<typeof serviceClient>,
  id: string,
  values: Record<string, unknown>,
) {
  const { data, error } = await client.from("meal_visuals").update(values)
    .eq("id", id).select().single();
  if (error) throw error;
  return data as Record<string, unknown>;
}

async function upload(
  client: ReturnType<typeof serviceClient>,
  path: string,
  bytes: Uint8Array,
  contentType: string,
) {
  const { error } = await client.storage.from(BUCKET).upload(path, bytes, {
    contentType,
    upsert: true,
  });
  if (error) throw error;
}

async function withSignedUrls(
  client: ReturnType<typeof serviceClient>,
  visual: Record<string, unknown>,
) {
  if (visual.status !== "ready" || typeof visual.storage_path !== "string") {
    return visual;
  }
  const [{ data, error }, thumb] = await Promise.all([
    client.storage.from(BUCKET).createSignedUrl(
      visual.storage_path,
      SIGNED_URL_TTL_SECONDS,
    ),
    typeof visual.thumb_storage_path === "string"
      ? client.storage.from(BUCKET).createSignedUrl(
        visual.thumb_storage_path,
        SIGNED_URL_TTL_SECONDS,
      )
      : Promise.resolve({ data: null, error: null }),
  ]);
  if (error) throw error;
  return {
    ...visual,
    signed_url: data?.signedUrl ?? null,
    thumb_signed_url: thumb.data?.signedUrl ?? null,
    signed_url_expires_at: new Date(
      Date.now() + SIGNED_URL_TTL_SECONDS * 1000,
    ).toISOString(),
  };
}

function decodeBase64(value: string) {
  const decoded = atob(value);
  return Uint8Array.from(decoded, (character) => character.charCodeAt(0));
}

function dominantColor(signature: string) {
  const palettes = ["#D6B98C", "#A9B99B", "#D99268", "#B5A4C3"];
  const seed = [...signature].reduce(
    (value, character) => (value + character.charCodeAt(0)) % palettes.length,
    0,
  );
  return palettes[seed];
}

function providerErrorCode(error: unknown) {
  if (error instanceof ApiError) return error.code;
  return "IMAGE_GENERATION_FAILED";
}

function idFromPath(url: string) {
  const parts = new URL(url).pathname.split("/").filter(Boolean);
  const index = parts.lastIndexOf("meal-visuals");
  const id = index >= 0 ? parts[index + 1] : parts[parts.length - 1];
  if (!id || id === "meal-visuals") {
    throw new ApiError(
      "INVALID_INPUT",
      "meal_visual_id is required",
      400,
      false,
    );
  }
  return id;
}
