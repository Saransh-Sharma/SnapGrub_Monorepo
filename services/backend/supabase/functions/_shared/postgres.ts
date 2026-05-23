import { ApiError } from "./errors.ts";

type PostgresLikeError = {
  code?: string;
  message?: string;
};

export function mapPostgresError(
  error: PostgresLikeError,
  fallbackMessage = "Database request failed",
) {
  if (error.code === "23505") {
    return new ApiError("CONFLICT", error.message ?? "Resource already exists", 409, false);
  }
  if (
    error.code === "22023" ||
    error.code === "22007" ||
    error.code === "22P02" ||
    error.code === "23514"
  ) {
    return new ApiError("INVALID_INPUT", error.message ?? "Invalid input", 400, false);
  }
  if (error.code === "40001" || error.code === "P0001") {
    return new ApiError("CONFLICT", error.message ?? "Revision conflict", 409, false);
  }
  if (error.code === "02000" || error.code === "PGRST116") {
    return new ApiError("NOT_FOUND", error.message ?? "Resource not found", 404, false);
  }
  return new ApiError("UNKNOWN", fallbackMessage, 500, true);
}
