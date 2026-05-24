import type { EditableMealDraft } from "./multimodal.ts";
import type { serviceClient } from "./supabase.ts";

export async function readExistingAnalysisJob(
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

export async function persistRuleAnalysis(
  client: ReturnType<typeof serviceClient>,
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
  const { data: job, error } = await client
    .rpc("persist_rule_analysis", {
      p_user_id: input.userId,
      p_client_request_id: input.clientRequestId,
      p_mode: input.mode,
      p_input_payload: input.inputPayload,
      p_result_payload: input.result,
      p_model_name: input.modelName,
      p_latency_ms: input.latencyMs,
      p_request_payload: safeRuleRequestPayload(input.inputPayload),
      p_response_payload: {
        title: input.result.title,
        confidence: input.result.confidence,
        component_count: input.result.components.length,
      },
    })
    .single();
  if (error) throw error;

  return job as Record<string, unknown>;
}

export async function analysisResponseForJob(
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

function safeRuleRequestPayload(inputPayload: Record<string, unknown>) {
  const copy = { ...inputPayload };
  delete copy.ocr_text;
  delete copy.text;
  delete copy.transcript;
  return copy;
}
