import { ApiError } from "./errors.ts";
import type { serviceClient } from "./supabase.ts";

const IN_PROGRESS_TTL_MS = 2 * 60 * 1000;

export type IdempotencyReplay = {
  request_hash: string;
  response_status: number | null;
  response_body: Record<string, unknown> | null;
  created_at?: string;
};

export async function maybeReplayIdempotency(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  endpoint: string,
  key: string,
  bodyText: string,
): Promise<IdempotencyReplay | null> {
  const requestHash = await sha256Hex(bodyText);
  const { error: claimError } = await client.from("api_idempotency").insert({
    user_id: userId,
    endpoint,
    key,
    request_hash: requestHash,
  });
  if (!claimError) return null;
  if (claimError.code !== "23505") throw claimError;

  const { data: previous, error } = await client
    .from("api_idempotency")
    .select("request_hash, response_status, response_body, created_at")
    .eq("user_id", userId)
    .eq("endpoint", endpoint)
    .eq("key", key)
    .maybeSingle();
  if (error) throw error;
  if (!previous) return null;
  if (previous.request_hash !== requestHash) {
    throw new ApiError(
      "IDEMPOTENCY_CONFLICT",
      "Idempotency key was reused with a different request body",
      409,
      false,
    );
  }
  if (!previous.response_body) {
    if (isStaleInProgress(previous.created_at)) {
      const { error: deleteError } = await client
        .from("api_idempotency")
        .delete()
        .eq("user_id", userId)
        .eq("endpoint", endpoint)
        .eq("key", key)
        .eq("request_hash", requestHash)
        .is("response_body", null);
      if (deleteError) throw deleteError;

      const { error: reclaimError } = await client.from("api_idempotency")
        .insert({
          user_id: userId,
          endpoint,
          key,
          request_hash: requestHash,
        });
      if (!reclaimError) return null;
      if (reclaimError.code !== "23505") throw reclaimError;
    }

    throw new ApiError(
      "CONFLICT",
      "Idempotent request is already in progress",
      409,
      true,
    );
  }
  return previous as IdempotencyReplay;
}

function isStaleInProgress(createdAt: string | undefined) {
  if (!createdAt) return false;
  const createdAtMs = Date.parse(createdAt);
  return Number.isFinite(createdAtMs) &&
    Date.now() - createdAtMs > IN_PROGRESS_TTL_MS;
}

export async function storeIdempotency(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  endpoint: string,
  key: string,
  bodyText: string,
  responseStatus: number,
  responseBody: Record<string, unknown>,
) {
  const { data, error } = await client
    .from("api_idempotency")
    .update({
      response_status: responseStatus,
      response_body: responseBody,
    })
    .eq("user_id", userId)
    .eq("endpoint", endpoint)
    .eq("key", key)
    .eq("request_hash", await sha256Hex(bodyText))
    .select("id");
  if (error) throw error;
  if (!data || data.length === 0) {
    throw new ApiError(
      "CONFLICT",
      "Idempotency record could not be updated",
      409,
      true,
    );
  }
}

export async function failIdempotency(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  endpoint: string,
  key: string,
  bodyText: string,
  responseStatus: number,
  responseBody: Record<string, unknown>,
) {
  await storeIdempotency(
    client,
    userId,
    endpoint,
    key,
    bodyText,
    responseStatus,
    responseBody,
  );
}

export async function sha256Hex(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}
