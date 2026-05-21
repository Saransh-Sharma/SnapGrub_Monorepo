# Backend Architecture

Supabase is the Phase 0-7 backend. It provides auth, Postgres, RLS, private storage, local migrations, seed data, Edge Functions, backend-only AI orchestration, idempotent sync replay, and service-role RPCs for transactional settings, meal, rollup, and insight paths.

## How It Works

- Migrations live in `services/backend/supabase/migrations`.
- Edge Functions live in `services/backend/supabase/functions`.
- RLS policies are applied with the table migrations.
- `profile-bootstrap` creates missing profile state, upserts devices, and resolves feature flags.
- `settings-patch` validates and applies profile/goal/measurement changes through a transactional RPC.
- `events-ingest` accepts append-only analytics events.
- `meals` lists, reads, creates, updates, and soft-deletes authenticated user meals.
- `upsert_user_meal`, `delete_user_meal`, and `refresh_daily_rollup` keep meal writes transactional and refresh rollups.
- `analysis-photo-create` validates private storage ownership, runs the configured backend provider, records model invocations, and returns editable photo drafts.
- `analysis-get` recovers one user's analysis job/result.
- `foods-search`, `barcode-resolve`, `analysis-text-create`, `analysis-label-create`, and `analysis-voice-create` provide Phase 5 multimodal entry support.
- `custom-foods`, `meal-templates`, `body-measurements`, and `exports-create` provide idempotent Phase 6 outbox replay surfaces.
- Weekly insight and learned-default RPC paths are available behind Phase 7 feature flags; scheduled generation remains an ops/staging gate.

## Safe Change Rules

- Add database changes through new migrations only.
- Keep service-role usage inside backend functions or server environments.
- Add or update RLS tests for every user-owned table.
- Keep Edge Function request/response shapes aligned with OpenAPI.
- Do not expose feature flag overrides directly to clients.
- Keep meal correction events append-only and return authoritative correction events from meal write responses.
- Keep `exports-create` scoped to request enqueueing until Phase 8 export artifact generation is explicitly implemented.
