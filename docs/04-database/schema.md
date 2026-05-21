# Database Schema

Migration SQL is the final source of truth. This page summarizes the current Phase 0-4 schema so developers can understand ownership, access patterns, and safe changes.

## Identity And Settings

- `profiles`: one row per auth user with locale, timezone, unit system, privacy preferences, and onboarding completion.
- `nutrition_goals`: active calorie and macro goals; a partial unique index enforces one active goal per user.
- `devices`: stable install ID, platform, app/build versions, push token, and sync cursor.
- `body_measurements`: weight/body-fat measurements from onboarding or manual entry.

## Flags, Analytics, And Idempotency

- `feature_flags`: authenticated users can read global flags.
- `feature_flag_overrides`: service-side override rules, not client-readable.
- `analytics_events`: append-only client inserts; no client reads.
- `api_idempotency`: stores endpoint/key/hash/response snapshots for idempotent replay.

## Meal Ledger

- `meals`: user-owned source-of-truth meal rows with `client_id`, meal type, source, logged time, timezone, totals, revision, and soft-delete timestamp.
- `meal_items`: item rows for each meal with quantity, unit, estimated grams, macros, confidence, provenance fields, and optional custom/catalog references.
- `meal_templates`: user-owned reusable meal snapshots; soft-deleted with `deleted_at`.
- `custom_foods`: user-owned foods/products; soft-deleted with `deleted_at`.
- `daily_rollups`: derived per-user/per-day calorie and macro totals, refreshed by service-role RPCs.
- `correction_events`: append-only records for meal create/update/delete and future AI correction tracking.

## Photo Analysis

- `meal_assets`: user-owned private image references with storage bucket/path, optional thumbnail path, SHA-256, MIME type, dimensions, size, retention timestamp, and soft-delete timestamp.
- `analysis_jobs`: user-owned photo/text/barcode analysis jobs keyed by `(user_id, client_request_id)` for idempotent replay.
- `analysis_revisions`: immutable normalized analysis results with totals, confidence breakdown, warnings, provenance, and the full editable draft payload.
- `analysis_candidates`: optional alternate interpretations linked to an analysis revision.
- `model_invocations`: backend-only provider invocation records with provider/model, status, latency, token counts, estimated cost, error code, and request/response payload snapshots.

## Storage

Private buckets exist for meal originals, thumbnails, and exports. Phase 4 mobile uploads originals and thumbnails under the authenticated user's storage prefix, then backend Edge Functions validate path ownership before creating analysis rows.

## Indexes And Constraints

- `one_active_goal_per_user` enforces one active nutrition goal.
- User/time indexes support profile, meal, template, custom-food, and correction-event reads.
- Meal/item constraints reject invalid meal types, sources, negative macros, and non-positive quantities.
- `daily_rollups` primary key is `(user_id, day)`.
- `meals` and Phase 3 reusable entities use `(user_id, client_id)` uniqueness for local-first replay.
- `analysis_jobs` uses `(user_id, client_request_id)` uniqueness for analysis replay.
- `meals.source = photo` requires a completed owned `analysis_job_id` and owned `photo_asset_id` through the service-role meal RPC.

## Safe Change Rules

- Add schema changes through a new numbered migration.
- Update [rls.md](rls.md) when table ownership or client access changes.
- Update OpenAPI and generated clients before changing Edge Function response shape.
- Add tests for every new user-owned table, RLS policy, or service-role RPC path.
