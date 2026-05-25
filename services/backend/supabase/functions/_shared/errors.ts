export type ErrorCode =
  | "AUTH_REQUIRED"
  | "INVALID_INPUT"
  | "NOT_FOUND"
  | "IDEMPOTENCY_CONFLICT"
  | "CONFLICT"
  | "RATE_LIMITED"
  | "UNKNOWN";

export class ApiError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly status = 400,
    public readonly retryable = false,
    public readonly details: Record<string, unknown> = {},
  ) {
    super(message);
  }
}

export function errorBody(error: unknown, requestId: string) {
  if (error instanceof ApiError) {
    return {
      code: error.code,
      message: error.message,
      user_message: error.message,
      retryable: error.retryable,
      request_id: requestId,
      details: error.details,
    };
  }

  return {
    code: "UNKNOWN",
    message: "Unexpected server error",
    user_message: "Something went wrong. Please try again.",
    retryable: true,
    request_id: requestId,
    details: {},
  };
}

export function errorStatus(error: unknown) {
  return error instanceof ApiError ? error.status : 500;
}

export function logError(
  scope: string,
  requestId: string,
  error: unknown,
  details: Record<string, unknown> = {},
) {
  const message = error instanceof Error ? error.message : String(error);
  const stack = error instanceof Error ? error.stack : undefined;
  const code = error instanceof ApiError ? error.code : "UNKNOWN";
  const payload = {
    level: "error",
    scope,
    request_id: requestId,
    code,
    message,
    stack,
    details,
  };
  try {
    console.error(JSON.stringify(payload));
  } catch (_) {
    console.error(JSON.stringify({
      ...payload,
      details: { serialization_error: "Unable to serialize log details" },
    }));
  }
}
