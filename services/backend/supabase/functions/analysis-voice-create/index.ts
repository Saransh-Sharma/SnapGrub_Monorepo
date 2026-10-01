import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { analysisResponseForJob, persistRuleAnalysis, readExistingAnalysisJob } from "../_shared/analysis_repository.ts";
import { groundDraftSafely } from "../_shared/catalog_grounding.ts";
import { textModelConfig } from "../_shared/llm.ts";
import { parseMealText } from "../_shared/meal_llm.ts";
import { consumeDailyAiBudget, recordAnalysisModelUsage } from "../_shared/model_invocations.ts";
import { consumeRateLimit } from "../_shared/rate_limit.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { readUserFoodHints } from "../_shared/user_foods.ts";
import { optionalString, requireString } from "../_shared/validation.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    const user = await requireUser(req);
    const body = await req.json().catch(() => {
      throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
    }) as Record<string, unknown>;
    const clientRequestId = requireString(body.client_request_id, "client_request_id");
    const transcript = requireString(body.transcript, "transcript");
    const locale = requireString(body.locale, "locale");
    const timezone = requireString(body.timezone, "timezone");
    const client = serviceClient();
    const existing = await readExistingAnalysisJob(client, user.id, clientRequestId);
    if (existing) return jsonResponse(await analysisResponseForJob(client, existing, requestId));
    await consumeRateLimit(client, user.id, "analysis:voice", 60 * 60, 120);
    const modelConfigured = textModelConfig() != null;
    if (modelConfigured) await consumeDailyAiBudget(client, user.id);

    const startedAt = performance.now();
    const parsed = await parseMealText({
      text: transcript,
      source: "voice",
      timezone,
      locale,
      mealTypeHint: optionalString(body.meal_type_hint),
      cuisineHints: Array.isArray(body.cuisine_hints) ? body.cuisine_hints.map(String) : [],
      transcriptConfidence: typeof body.transcript_confidence === "number" ? body.transcript_confidence : null,
      userFoods: modelConfigured ? await readUserFoodHints(client, user.id) : [],
    });
    const result = await groundDraftSafely(client, user.id, parsed.draft, {
      preferCatalogPortions: true,
      onlyItems: parsed.freshItemIds,
    });
    const job = await persistRuleAnalysis(client, {
      userId: user.id,
      clientRequestId,
      mode: "voice",
      inputPayload: body,
      result,
      modelName: parsed.provider === "snapgrub" ? "phase5-voice-parser" : parsed.model,
      latencyMs: Math.round(performance.now() - startedAt),
    });
    await recordAnalysisModelUsage(client, String(job.id), parsed);
    return jsonResponse(await analysisResponseForJob(client, job, requestId));
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});
