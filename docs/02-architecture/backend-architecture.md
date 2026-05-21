# Backend Architecture

Supabase is the Phase 0-3 backend. It provides auth, Postgres, RLS, private storage, local migrations, seed data, Edge Functions, and service-role RPCs for transactional meal writes.

## How It Works

- Migrations live in `services/backend/supabase/migrations`.
- Edge Functions live in `services/backend/supabase/functions`.
- RLS policies are applied with the table migrations.
- `profile-bootstrap` creates missing profile state, upserts devices, and resolves feature flags.
- `settings-patch` validates and applies profile/goal/measurement changes through a transactional RPC.
- `events-ingest` accepts append-only analytics events.
- `meals` lists, reads, creates, updates, and soft-deletes authenticated user meals.
- `upsert_user_meal`, `delete_user_meal`, and `refresh_daily_rollup` keep meal writes transactional and refresh rollups.
- Templates and custom foods sync through RLS-backed table writes rather than separate Edge Functions in Phase 3.

## Safe Change Rules

- Add database changes through new migrations only.
- Keep service-role usage inside backend functions or server environments.
- Add or update RLS tests for every user-owned table.
- Keep Edge Function request/response shapes aligned with OpenAPI.
- Do not expose feature flag overrides directly to clients.
- Keep meal correction events append-only and return authoritative correction events from meal write responses.
