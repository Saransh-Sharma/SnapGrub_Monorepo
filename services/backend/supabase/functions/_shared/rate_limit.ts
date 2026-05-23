import { ApiError } from "./errors.ts";

export async function consumeRateLimit(
  client: any,
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
    throw new ApiError("CONFLICT", "Too many requests. Please try again later.", 429, true);
  }
}
