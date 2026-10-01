import { estimatedCost } from "./llm.ts";
import { consumeRateLimit } from "./rate_limit.ts";
import type { serviceClient } from "./supabase.ts";

type Client = ReturnType<typeof serviceClient>;

/// Per-user ceiling on model calls per UTC day, across photo, text, voice and
/// conversation. Bounds provider spend until plans carry their own quotas.
export async function consumeDailyAiBudget(client: Client, userId: string) {
  const limit = Number(Deno.env.get("AI_DAILY_CALL_LIMIT") ?? "100");
  await consumeRateLimit(
    client,
    userId,
    "ai:daily",
    24 * 60 * 60,
    Number.isFinite(limit) && limit > 0 ? limit : 100,
  );
}

/// Per-user ceiling on generated images per UTC day. Kept apart from the
/// logging budget so artwork can never use up a user's meal logging.
export async function consumeDailyImageBudget(client: Client, userId: string) {
  const limit = Number(Deno.env.get("AI_DAILY_IMAGE_LIMIT") ?? "20");
  await consumeRateLimit(
    client,
    userId,
    "ai:image:daily",
    24 * 60 * 60,
    Number.isFinite(limit) && limit > 0 ? limit : 20,
  );
}

/// Configured price of one generated image, or null when it is not set.
export function imagePriceUsd() {
  const price = Number(Deno.env.get("AI_IMAGE_PRICE_USD"));
  return Number.isFinite(price) && price > 0 ? price : null;
}

export async function insertInvocation(
  client: Client,
  invocation: {
    analysisJobId: string | null;
    userId: string;
    provider: string;
    modelName: string;
    purpose?: string;
    status: "completed" | "failed";
    latencyMs: number;
    inputTokens: number | null;
    outputTokens: number | null;
    estimatedCostUsd?: number | null;
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
      ...(invocation.purpose ? { purpose: invocation.purpose } : {}),
      status: invocation.status,
      latency_ms: invocation.latencyMs,
      input_tokens: invocation.inputTokens,
      output_tokens: invocation.outputTokens,
      estimated_cost_usd: invocation.estimatedCostUsd !== undefined
        ? invocation.estimatedCostUsd
        : estimatedCost(invocation.inputTokens, invocation.outputTokens),
      error_code: invocation.errorCode ?? null,
      request_payload: invocation.requestPayload,
      response_payload: invocation.responsePayload,
    })
    .select("id")
    .single();
  if (error) throw error;
  return data.id as string;
}

/// Records which provider answered a text or voice analysis.
/// `persist_rule_analysis` writes the invocation row as the in-house parser,
/// so a model-backed run is corrected here.
export async function recordAnalysisModelUsage(
  client: Client,
  analysisJobId: string,
  usage: {
    provider: string;
    model: string;
    inputTokens: number | null;
    outputTokens: number | null;
  },
) {
  if (usage.provider === "snapgrub") return;
  const job = await client.from("analysis_jobs").update({
    provider: usage.provider,
  }).eq("id", analysisJobId);
  if (job.error) throw job.error;
  const invocation = await client.from("model_invocations").update({
    provider: usage.provider,
    model_name: usage.model,
    input_tokens: usage.inputTokens,
    output_tokens: usage.outputTokens,
    estimated_cost_usd: estimatedCost(usage.inputTokens, usage.outputTokens),
  }).eq("analysis_job_id", analysisJobId);
  if (invocation.error) throw invocation.error;
}
