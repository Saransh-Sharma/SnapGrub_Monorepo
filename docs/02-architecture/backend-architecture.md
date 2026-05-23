# Backend Architecture

Supabase is the Phase 0-8 backend. It provides auth, Postgres, RLS, private storage, local migrations, seed data, Edge Functions, backend-only AI orchestration, idempotent sync replay, export artifact generation, destructive account deletion, cleanup jobs, and service-role RPCs for transactional settings, meal, rollup, insight, privacy, and retention paths. Backend hardening through migration `000018` tightens storage ownership, model invocation privacy, custom-food ownership, export cleanup safety, barcode miss caching, and scheduled-job setup.

## How It Works

- Migrations live in `services/backend/supabase/migrations`.
- Edge Functions live in `services/backend/supabase/functions`.
- RLS policies are applied with the table migrations.
- `profile-bootstrap` creates missing profile state, upserts devices, and resolves feature flags with rollout percentage and simple rule evaluation.
- `settings-patch` validates and applies profile/goal/measurement changes through a transactional RPC.
- `events-ingest` accepts append-only analytics events.
- `meals` lists, reads, creates, updates, and soft-deletes authenticated user meals.
- `upsert_user_meal`, `delete_user_meal`, and `refresh_daily_rollup` keep meal writes transactional and refresh rollups.
- `analysis-photo-create` validates private storage ownership for originals and thumbnails, rate-limits expensive analysis, runs the configured backend provider, records backend-only model invocations, and returns editable photo drafts.
- `analysis-get` recovers one user's analysis job/result.
- `foods-search`, `barcode-resolve`, `analysis-text-create`, `analysis-label-create`, and `analysis-voice-create` provide Phase 5 multimodal entry support.
- `custom-foods`, `meal-templates`, `body-measurements`, and `exports-create` provide idempotent outbox replay surfaces. `exports-create` now starts MVP export artifact generation after the request reaches the backend.
- Weekly insight and learned-default RPC paths are available behind Phase 7 feature flags; scheduled generation remains an ops/staging gate.
- `account-delete` performs confirmed destructive account removal through recursive service-role storage cleanup and auth operations.
- `media-retention-cleanup` performs service-role cleanup of expired export artifacts and retained meal media, and marks export rows expired only after storage cleanup succeeds.

## Safe Change Rules

- Add database changes through new migrations only.
- Keep service-role usage inside backend functions or server environments.
- Add or update RLS tests for every user-owned table.
- Keep Edge Function request/response shapes aligned with OpenAPI.
- Do not expose feature flag overrides directly to clients.
- Keep meal correction events append-only and return authoritative correction events from meal write responses.
- Keep export artifact bytes and signed URL creation inside backend-controlled code; mobile should never construct private storage paths or hold service-role credentials.
- Keep destructive account deletion online-only, explicitly confirmed, and audited through `account_deletion_requests`.
