import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { ApiError } from "../../functions/_shared/errors.ts";
import { analyzePhoto } from "../../functions/_shared/photo_analysis.ts";
import { requireServiceRole } from "../../functions/_shared/request.ts";

Deno.test("photo analysis does not silently fall back to mock for real providers", async () => {
  const previousProvider = Deno.env.get("AI_PROVIDER");
  const previousGeminiKey = Deno.env.get("GEMINI_API_KEY");
  const previousOpenAIKey = Deno.env.get("OPENAI_API_KEY");
  try {
    Deno.env.set("AI_PROVIDER", "gemini");
    Deno.env.delete("GEMINI_API_KEY");
    Deno.env.delete("OPENAI_API_KEY");

    const error = await assertRejects(
      () =>
        analyzePhoto({
          imageBytes: new Uint8Array([1, 2, 3]),
          mimeType: "image/jpeg",
          locale: "en-US",
          timezone: "UTC",
          mealTypeHint: null,
          cuisineHints: [],
          userHintText: null,
        }),
      ApiError,
    );
    assertEquals(error.status, 500);
    assertEquals(error.retryable, true);
  } finally {
    restoreEnv("AI_PROVIDER", previousProvider);
    restoreEnv("GEMINI_API_KEY", previousGeminiKey);
    restoreEnv("OPENAI_API_KEY", previousOpenAIKey);
  }
});

Deno.test("service role auth rejects incorrect bearer token", () => {
  const previousServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  try {
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "real-service-key");
    const req = new Request(
      "http://localhost/functions/v1/media-retention-cleanup",
      {
        method: "POST",
        headers: { authorization: "Bearer invalid-service-key" },
      },
    );
    const error = assertRejectsSync(() => requireServiceRole(req), ApiError);
    assertEquals(error.status, 401);
  } finally {
    restoreEnv("SUPABASE_SERVICE_ROLE_KEY", previousServiceKey);
  }
});

function assertRejectsSync(fn: () => void, errorClass: typeof ApiError) {
  try {
    fn();
  } catch (error) {
    if (error instanceof errorClass) return error;
    throw error;
  }
  throw new Error("Expected function to throw");
}

function restoreEnv(key: string, value: string | undefined) {
  if (value == null) {
    Deno.env.delete(key);
  } else {
    Deno.env.set(key, value);
  }
}
