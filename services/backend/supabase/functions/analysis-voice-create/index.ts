import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { optionalString, requireString } from "../_shared/validation.ts";
import { buildDraftFromText } from "../_shared/multimodal.ts";
import type { EditableMealDraft } from "../_shared/multimodal.ts";

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
    const existing = await readExistingJob(client, user.id, clientRequestId);
    if (existing) return jsonResponse(await responseForJob(client, existing, requestId));

    const result = buildDraftFromText({
      text: transcript,
      source: "voice",
      timezone,
      locale,
      mealTypeHint: optionalString(body.meal_type_hint),
      cuisineHints: Array.isArray(body.cuisine_hints) ? body.cuisine_hints.map(String) : [],
      transcriptConfidence: typeof body.transcript_confidence === "number" ? body.transcript_confidence : null,
    });
    const job = await persistAnalysis(client, user.id, clientRequestId, "voice", body, result);
    return jsonResponse(await responseForJob(client, job, requestId));
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

async function readExistingJob(client: ReturnType<typeof serviceClient>, userId: string, clientRequestId: string) {
  const { data, error } = await client
    .from("analysis_jobs")
    .select("*")
    .eq("user_id", userId)
    .eq("client_request_id", clientRequestId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function persistAnalysis(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  clientRequestId: string,
  mode: string,
  inputPayload: Record<string, unknown>,
  result: EditableMealDraft,
) {
  const { data: job, error: jobError } = await client
    .from("analysis_jobs")
    .insert({
      user_id: userId,
      client_request_id: clientRequestId,
      analysis_mode: mode,
      status: "completed",
      input_payload: inputPayload,
      provider: "snapgrub",
      model_name: "phase5-voice-parser",
      completed_at: new Date().toISOString(),
    })
    .select("*")
    .single();
  if (jobError) throw jobError;
  const resultPayload = { ...result, provenance: { ...result.provenance, analysis_id: job.id } };
  const { error: revisionError } = await client.from("analysis_revisions").insert({
    analysis_job_id: job.id,
    user_id: userId,
    revision_no: 1,
    title: result.title,
    meal_type: result.meal_type,
    calories_kcal: result.total.calories_kcal,
    protein_g: result.total.protein_g,
    carbs_g: result.total.carbs_g,
    fat_g: result.total.fat_g,
    confidence_overall: result.confidence.overall,
    confidence_breakdown: result.confidence,
    warnings: result.confidence.warnings.map((warning) => warning.message),
    provenance: resultPayload.provenance,
    result_payload: resultPayload,
  });
  if (revisionError) throw revisionError;
  return job;
}

async function responseForJob(client: ReturnType<typeof serviceClient>, job: Record<string, unknown>, requestId: string) {
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
    status: job.status,
    result: revision?.result_payload ?? null,
    error_code: job.error_code ?? null,
    retryable: false,
    server_time: new Date().toISOString(),
    request_id: requestId,
  };
}
