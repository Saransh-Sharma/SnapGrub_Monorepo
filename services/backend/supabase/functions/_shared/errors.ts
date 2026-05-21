export type ErrorCode =
  | "AUTH_REQUIRED"
  | "INVALID_INPUT"
  | "NOT_FOUND"
  | "IDEMPOTENCY_CONFLICT"
  | "CONFLICT"
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

  const message = error instanceof Error ? error.message : "Unknown error";
  return {
    code: "UNKNOWN",
    message,
    user_message: "Something went wrong. Please try again.",
    retryable: true,
    request_id: requestId,
    details: {},
  };
}
