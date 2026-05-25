import { ApiError } from "./errors.ts";
import type { serviceClient } from "./supabase.ts";

export async function consumeRateLimit(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  action: string,
  windowSeconds: number,
  maxCount: number,
) {
  const { data, error } = await client.rpc("consume_api_rate_limit", {
    p_user_id: userId,
    p_action: action,
    p_window_seconds: windowSeconds,
    p_max_count: maxCount,
  });
  if (error) throw error;
  if (data !== true) {
    throw new ApiError(
      "RATE_LIMITED",
      "Too many requests. Please try again later.",
      429,
      true,
    );
  }
}
