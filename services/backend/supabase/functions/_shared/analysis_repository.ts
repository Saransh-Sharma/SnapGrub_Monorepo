import type { EditableMealDraft } from "./multimodal.ts";

export async function readExistingAnalysisJob(
  client: any,
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

export async function persistRuleAnalysis(
  client: any,
  input: {
    userId: string;
    clientRequestId: string;
    mode: "text" | "label" | "voice";
    inputPayload: Record<string, unknown>;
    result: EditableMealDraft;
    modelName: string;
    latencyMs: number;
  },
) {
  const { data: job, error: jobError } = await client
    .from("analysis_jobs")
    .insert({
      user_id: input.userId,
      client_request_id: input.clientRequestId,
      analysis_mode: input.mode,
      status: "completed",
      input_payload: input.inputPayload,
      provider: "snapgrub",
      model_name: input.modelName,
      latency_ms: input.latencyMs,
      completed_at: new Date().toISOString(),
    })
    .select("*")
    .single();
  if (jobError) throw jobError;

  const resultPayload = {
    ...input.result,
    provenance: { ...input.result.provenance, analysis_id: job.id },
  };

  const { error: revisionError } = await client.from("analysis_revisions").insert({
    analysis_job_id: job.id,
    user_id: input.userId,
    revision_no: 1,
    title: input.result.title,
    meal_type: input.result.meal_type,
    calories_kcal: input.result.total.calories_kcal,
    protein_g: input.result.total.protein_g,
    carbs_g: input.result.total.carbs_g,
    fat_g: input.result.total.fat_g,
    confidence_overall: input.result.confidence.overall,
    confidence_breakdown: input.result.confidence,
    warnings: input.result.confidence.warnings.map((warning) => warning.message),
    provenance: resultPayload.provenance,
    result_payload: resultPayload,
  });
  if (revisionError) throw revisionError;

  const { error: invocationError } = await client.from("model_invocations").insert({
    analysis_job_id: job.id,
    user_id: input.userId,
    provider: "snapgrub",
    model_name: input.modelName,
    purpose: `${input.mode}_analysis`,
    status: "completed",
    latency_ms: input.latencyMs,
    request_payload: safeRuleRequestPayload(input.inputPayload),
    response_payload: {
      title: input.result.title,
      confidence: input.result.confidence,
      component_count: input.result.components.length,
    },
  });
  if (invocationError) throw invocationError;

  return job;
}

export async function analysisResponseForJob(client: any, job: Record<string, unknown>, requestId: string) {
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

function safeRuleRequestPayload(inputPayload: Record<string, unknown>) {
  const copy = { ...inputPayload };
  delete copy.ocr_text;
  delete copy.text;
  delete copy.transcript;
  return copy;
}
