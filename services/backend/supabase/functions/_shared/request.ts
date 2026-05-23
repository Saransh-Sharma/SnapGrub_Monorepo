import { ApiError } from "./errors.ts";

const DEFAULT_MAX_BODY_BYTES = 256 * 1024;

export function requireMethod(req: Request, allowed: string | string[]) {
  const methods = Array.isArray(allowed) ? allowed : [allowed];
  if (!methods.includes(req.method)) {
    throw new ApiError("INVALID_INPUT", "Method not allowed", 405, false);
  }
}

export async function parseJsonBody(
  req: Request,
  options: { maxBytes?: number; emptyObject?: boolean } = {},
): Promise<{ body: Record<string, unknown>; bodyText: string }> {
  const maxBytes = options.maxBytes ?? DEFAULT_MAX_BODY_BYTES;
  const bodyText = await req.text();
  if (new TextEncoder().encode(bodyText).byteLength > maxBytes) {
    throw new ApiError("INVALID_INPUT", "Request body is too large", 413, false);
  }
  if (!bodyText) {
    if (options.emptyObject ?? true) return { body: {}, bodyText };
    throw new ApiError("INVALID_INPUT", "Request body is required", 400, false);
  }
  try {
    const parsed = JSON.parse(bodyText);
    if (!isRecord(parsed)) {
      throw new ApiError("INVALID_INPUT", "Request body must be a JSON object", 400, false);
    }
    return { body: parsed, bodyText };
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
  }
}

export function requireServiceRole(req: Request) {
  const expected = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!expected) {
    throw new ApiError("UNKNOWN", "Server is missing service-role configuration", 500, true);
  }
  const token = bearerToken(req);
  if (token === expected) return;
  throw new ApiError("AUTH_REQUIRED", "Service role authorization is required", 401, false);
}

export function bearerToken(req: Request) {
  return (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
