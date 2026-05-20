import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { ApiError } from "./errors.ts";

export function serviceClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !key) {
    throw new ApiError("UNKNOWN", "Server is missing Supabase service configuration", 500, true);
  }

  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export function anonClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY");

  if (!url || !key) {
    throw new ApiError("UNKNOWN", "Server is missing Supabase anon configuration", 500, true);
  }

  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export async function requireUser(req: Request) {
  const auth = req.headers.get("authorization") ?? "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (!token) {
    throw new ApiError("AUTH_REQUIRED", "Authentication is required", 401, false);
  }

  const { data, error } = await anonClient().auth.getUser(token);
  if (error || !data.user) {
    throw new ApiError("AUTH_REQUIRED", "Authentication is required", 401, false);
  }

  return data.user;
}
