import { ApiError } from "./errors.ts";

export function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new ApiError("INVALID_INPUT", `${field} is required`, 400, false, { field });
  }
  return value.trim();
}

export function optionalString(value: unknown): string | null {
  if (value === undefined || value === null || value === "") return null;
  return String(value);
}

export function assertPlatform(value: string) {
  if (value !== "ios" && value !== "android") {
    throw new ApiError("INVALID_INPUT", "platform must be ios or android", 400, false, { field: "platform" });
  }
}

export function assertEnum(value: unknown, field: string, allowed: string[]) {
  if (typeof value !== "string" || !allowed.includes(value)) {
    throw new ApiError("INVALID_INPUT", `${field} is invalid`, 400, false, { field, allowed });
  }
}

export function assertNumberRange(value: unknown, field: string, min: number, max: number, required = false) {
  if (value === undefined || value === null) {
    if (required) {
      throw new ApiError("INVALID_INPUT", `${field} is required`, 400, false, { field });
    }
    return;
  }

  if (typeof value !== "number" || Number.isNaN(value) || value < min || value > max) {
    throw new ApiError("INVALID_INPUT", `${field} is out of range`, 400, false, { field, min, max });
  }
}
