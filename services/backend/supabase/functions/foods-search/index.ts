import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { searchFoods } from "../_shared/food_lookup.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    const user = await requireUser(req);
    const body = await req.json().catch(() => {
      throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
    }) as Record<string, unknown>;
    const query = typeof body.query === "string" ? body.query.trim() : "";
    if (!query) throw new ApiError("INVALID_INPUT", "query is required", 400, false);
    const limit = Math.min(Math.max(Number(body.limit ?? 10), 1), 25);

    return jsonResponse({
      results: await searchFoods(serviceClient(), user.id, query, limit),
      server_time: new Date().toISOString(),
      request_id: requestId,
    });
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});
