import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "GET") throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    const user = await requireUser(req);
    const client = serviceClient();
    const analysisId = analysisIdFromPath(new URL(req.url).pathname);
    if (!analysisId) throw new ApiError("INVALID_INPUT", "analysis_id is required", 400, false);

    const { data: job, error } = await client
      .from("analysis_jobs")
      .select("*")
      .eq("id", analysisId)
      .eq("user_id", user.id)
      .maybeSingle();
    if (error) throw error;
    if (!job) throw new ApiError("NOT_FOUND", "Analysis not found", 404, false);

    const { data: revision, error: revisionError } = await client
      .from("analysis_revisions")
      .select("result_payload")
      .eq("analysis_job_id", analysisId)
      .order("revision_no", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (revisionError) throw revisionError;

    return jsonResponse({
      analysis_id: job.id,
      asset_id: job.asset_id ?? null,
      status: job.status,
      result: revision?.result_payload ?? null,
      error_code: job.error_code ?? null,
      retryable: job.status === "failed",
      server_time: new Date().toISOString(),
      request_id: requestId,
    });
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function analysisIdFromPath(pathname: string) {
  const parts = pathname.split("/").filter(Boolean);
  const index = parts.lastIndexOf("analysis-get");
  if (index < 0 || parts.length <= index + 1) return null;
  return parts[index + 1];
}
