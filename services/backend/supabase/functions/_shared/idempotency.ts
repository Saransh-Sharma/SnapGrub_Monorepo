import { ApiError } from "./errors.ts";

type SupabaseClient = {
  from: (table: string) => {
    select: (columns: string) => unknown;
    insert: (values: Record<string, unknown>) => unknown;
  };
};

type QueryBuilder = {
  eq: (column: string, value: string) => QueryBuilder;
  maybeSingle: () => Promise<{ data: Record<string, unknown> | null; error: unknown }>;
};

type InsertBuilder = Promise<{ error: unknown }> | { then: Promise<{ error: unknown }>["then"] };

export type IdempotencyReplay = {
  request_hash: string;
  response_status: number | null;
  response_body: Record<string, unknown>;
};

export async function maybeReplayIdempotency(
  client: SupabaseClient,
  userId: string,
  endpoint: string,
  key: string,
  bodyText: string,
): Promise<IdempotencyReplay | null> {
  const requestHash = await sha256Hex(bodyText);
  const query = client
    .from("api_idempotency")
    .select("request_hash, response_status, response_body") as QueryBuilder;
  const { data: previous, error } = await query
    .eq("user_id", userId)
    .eq("endpoint", endpoint)
    .eq("key", key)
    .maybeSingle();
  if (error) throw error;
  if (!previous) return null;
  if (previous.request_hash !== requestHash) {
    throw new ApiError("IDEMPOTENCY_CONFLICT", "Idempotency key was reused with a different request body", 409, false);
  }
  return previous as IdempotencyReplay;
}

export async function storeIdempotency(
  client: SupabaseClient,
  userId: string,
  endpoint: string,
  key: string,
  bodyText: string,
  responseStatus: number,
  responseBody: Record<string, unknown>,
) {
  const insert = client.from("api_idempotency").insert({
    user_id: userId,
    endpoint,
    key,
    request_hash: await sha256Hex(bodyText),
    response_status: responseStatus,
    response_body: responseBody,
  }) as InsertBuilder;
  const { error } = await insert;
  if (error) throw error;
}

export async function sha256Hex(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

