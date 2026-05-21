# Supabase Incident Runbook

Phase 0-1 checks:

1. Confirm Supabase project health.
2. Check Edge Function logs for `request_id`.
3. Verify Auth JWT validation.
4. Verify RLS policy changes in latest migration.
5. Roll back recent function deployment if bootstrap/settings are failing globally.
