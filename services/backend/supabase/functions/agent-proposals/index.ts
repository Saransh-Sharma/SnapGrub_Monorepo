import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { assertEnum } from "../_shared/validation.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();
  try {
    if (req.method !== "POST") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405, false);
    }
    const user = await requireUser(req);
    const proposalId = idFromPath(new URL(req.url).pathname);
    if (!proposalId) {
      throw new ApiError(
        "INVALID_INPUT",
        "proposal_id is required",
        400,
        false,
      );
    }
    const body = await req.json() as Record<string, unknown>;
    const requested = body.status ?? body.action;
    assertEnum(requested, "action", [
      "confirm",
      "edit",
      "reject",
      "undo",
      "confirmed",
      "edited",
      "rejected",
      "undone",
    ]);
    const status = ({
      confirm: "confirmed",
      edit: "edited",
      reject: "rejected",
      undo: "undone",
    } as Record<string, string>)[String(requested)] ?? String(requested);
    const client = serviceClient();
    const result = await client.from("meal_change_proposals")
      .update({ status })
      .eq("id", proposalId)
      .eq("user_id", user.id)
      .select()
      .maybeSingle();
    if (result.error) throw result.error;
    if (!result.data) {
      throw new ApiError("NOT_FOUND", "Proposal not found", 404, false);
    }
    return jsonResponse({
      proposal: result.data,
      request_id: requestId,
      server_time: new Date().toISOString(),
    });
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function idFromPath(pathname: string) {
  const parts = pathname.split("/").filter(Boolean);
  const index = parts.lastIndexOf("agent-proposals");
  return index >= 0 && parts.length > index + 1 ? parts[index + 1] : null;
}
