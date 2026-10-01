import { ApiError } from "./errors.ts";

/// Schema in the Gemini `responseSchema` dialect (OpenAPI subset, upper-case
/// types). Gemini enforces it; OpenAI runs in JSON mode with the prompt
/// describing the same shape.
export type ModelSchema = {
  type: "OBJECT" | "ARRAY" | "STRING" | "NUMBER" | "INTEGER" | "BOOLEAN";
  description?: string;
  nullable?: boolean;
  enum?: string[];
  properties?: Record<string, ModelSchema>;
  required?: string[];
  items?: ModelSchema;
};

export type ModelProvider = "gemini" | "openai";

export type JsonModelRequest = {
  provider: ModelProvider;
  model: string;
  /// Short noun phrase used in error messages, e.g. "Photo analysis".
  purpose: string;
  prompt: string;
  schema: ModelSchema;
  image?: { bytes: Uint8Array; mimeType: string };
  temperature?: number;
  timeoutMs?: number;
};

export type JsonModelResult = {
  provider: ModelProvider;
  model: string;
  json: Record<string, unknown>;
  raw: Record<string, unknown>;
  inputTokens: number | null;
  outputTokens: number | null;
};

export type ModelDeps = { fetch?: typeof fetch };

const REPAIR_NOTE =
  "Your previous reply was not valid JSON. Reply again with one complete JSON object and nothing else.";

/// Calls the provider and returns a parsed JSON object. Retries once when the
/// reply is not parseable JSON; provider and transport failures are thrown.
export async function callJsonModel(
  request: JsonModelRequest,
  deps: ModelDeps = {},
): Promise<JsonModelResult> {
  let inputTokens: number | null = null;
  let outputTokens: number | null = null;
  for (let attempt = 0; attempt < 2; attempt++) {
    const prompt = attempt === 0
      ? request.prompt
      : `${request.prompt}\n\n${REPAIR_NOTE}`;
    const reply = request.provider === "gemini"
      ? await callGemini({ ...request, prompt }, deps)
      : await callOpenAI({ ...request, prompt }, deps);
    inputTokens = addTokens(inputTokens, reply.inputTokens);
    outputTokens = addTokens(outputTokens, reply.outputTokens);
    const json = parseJsonObject(reply.text);
    if (json) {
      return {
        provider: request.provider,
        model: request.model,
        json,
        raw: reply.raw,
        inputTokens,
        outputTokens,
      };
    }
  }
  throw new ApiError(
    "INVALID_INPUT",
    "Model returned invalid JSON",
    502,
    true,
  );
}

/// Provider for text, voice and conversation parsing. Null means no model is
/// configured (or AI_PROVIDER=mock) and callers use the rule parser instead.
/// MEAL_TEXT_MODEL=off is the kill switch: it returns these paths to the
/// rule parser without touching photo analysis and without a redeploy.
export function textModelConfig(): {
  provider: ModelProvider;
  model: string;
} | null {
  if (Deno.env.get("MEAL_TEXT_MODEL")?.trim().toLowerCase() === "off") {
    return null;
  }
  const provider = Deno.env.get("AI_PROVIDER")?.trim().toLowerCase();
  if (provider === "mock") return null;
  if (provider === "openai") {
    if (!Deno.env.get("OPENAI_API_KEY")) return null;
    return {
      provider: "openai",
      model: Deno.env.get("OPENAI_TEXT_MODEL") ??
        Deno.env.get("OPENAI_FALLBACK_MODEL") ?? "gpt-4.1-mini",
    };
  }
  if (!Deno.env.get("GEMINI_API_KEY")) return null;
  return {
    provider: "gemini",
    model: Deno.env.get("AGENT_MODEL") ??
      Deno.env.get("GEMINI_PRIMARY_MODEL") ?? "gemini-3.1-flash-lite",
  };
}

export function estimatedCost(
  inputTokens: number | null,
  outputTokens: number | null,
) {
  if (inputTokens == null && outputTokens == null) return null;
  const inputPrice = Number(Deno.env.get("AI_INPUT_PRICE_PER_1M") ?? "0.25");
  const outputPrice = Number(Deno.env.get("AI_OUTPUT_PRICE_PER_1M") ?? "1.50");
  return ((inputTokens ?? 0) * inputPrice + (outputTokens ?? 0) * outputPrice) /
    1_000_000;
}

type ProviderReply = {
  text: string;
  raw: Record<string, unknown>;
  inputTokens: number | null;
  outputTokens: number | null;
};

async function callGemini(
  request: JsonModelRequest,
  deps: ModelDeps,
): Promise<ProviderReply> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    throw new ApiError(
      "UNKNOWN",
      "Gemini API key is not configured",
      500,
      true,
    );
  }
  const parts: Record<string, unknown>[] = [{ text: request.prompt }];
  if (request.image) {
    parts.push({
      inlineData: {
        mimeType: request.image.mimeType,
        data: base64(request.image.bytes),
      },
    });
  }
  const response = await fetchWithTimeout(
    `https://generativelanguage.googleapis.com/v1beta/models/${request.model}:generateContent`,
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify({
        contents: [{ role: "user", parts }],
        generationConfig: {
          temperature: request.temperature ?? 0.2,
          responseMimeType: "application/json",
          responseSchema: request.schema,
        },
      }),
    },
    request,
    deps,
  );
  const raw = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new ApiError(
      "UNKNOWN",
      `Gemini ${request.purpose.toLowerCase()} failed`,
      response.status,
      response.status >= 500,
      raw,
    );
  }
  return {
    text: String(raw?.candidates?.[0]?.content?.parts?.[0]?.text ?? ""),
    raw,
    inputTokens: numberOrNull(raw?.usageMetadata?.promptTokenCount),
    outputTokens: numberOrNull(raw?.usageMetadata?.candidatesTokenCount),
  };
}

async function callOpenAI(
  request: JsonModelRequest,
  deps: ModelDeps,
): Promise<ProviderReply> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    throw new ApiError(
      "UNKNOWN",
      "OpenAI API key is not configured",
      500,
      true,
    );
  }
  const content: Record<string, unknown>[] = [{
    type: "input_text",
    text: `${request.prompt}\n\nThe JSON object must match this schema:\n${
      JSON.stringify(request.schema)
    }`,
  }];
  if (request.image) {
    content.push({
      type: "input_image",
      image_url: `data:${request.image.mimeType};base64,${
        base64(request.image.bytes)
      }`,
    });
  }
  const response = await fetchWithTimeout(
    "https://api.openai.com/v1/responses",
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: request.model,
        input: [{ role: "user", content }],
        text: { format: { type: "json_object" } },
      }),
    },
    request,
    deps,
  );
  const raw = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new ApiError(
      "UNKNOWN",
      `OpenAI ${request.purpose.toLowerCase()} failed`,
      response.status,
      response.status >= 500,
      raw,
    );
  }
  return {
    text: String(
      raw?.output_text ?? raw?.output?.[0]?.content?.[0]?.text ?? "",
    ),
    raw,
    inputTokens: numberOrNull(raw?.usage?.input_tokens),
    outputTokens: numberOrNull(raw?.usage?.output_tokens),
  };
}

async function fetchWithTimeout(
  url: string,
  init: RequestInit,
  request: JsonModelRequest,
  deps: ModelDeps,
) {
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    request.timeoutMs ?? 12_000,
  );
  try {
    return await (deps.fetch ?? fetch)(url, {
      ...init,
      signal: controller.signal,
    });
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new ApiError(
        "UNKNOWN",
        `${request.purpose} provider timed out`,
        504,
        true,
      );
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

function parseJsonObject(text: string): Record<string, unknown> | null {
  const stripped = text.trim().replace(/^```(?:json)?/i, "").replace(
    /```$/i,
    "",
  ).trim();
  try {
    const parsed = JSON.parse(stripped);
    return parsed != null && typeof parsed === "object" &&
        !Array.isArray(parsed)
      ? parsed as Record<string, unknown>
      : null;
  } catch (_) {
    return null;
  }
}

function addTokens(total: number | null, next: number | null) {
  return next == null ? total : (total ?? 0) + next;
}

function base64(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}
