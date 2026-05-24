# Database Schema

Migration SQL is the final source of truth. This page summarizes the current Phase 0-8 schema plus backend hardening migrations through `000019` so developers can understand ownership, access patterns, and safe changes.

## Identity And Settings

- `profiles`: one row per auth user with locale, timezone, unit system, privacy preferences, and onboarding completion. Privacy booleans include `cloud_media_storage`, `save_original_photos`, and `ai_improvement_consent`.
- `nutrition_goals`: active calorie and macro goals; a partial unique index enforces one active goal per user.
- `devices`: stable install ID, platform, app/build versions, push token, and sync cursor.
- `body_measurements`: weight/body-fat measurements from onboarding or manual entry.

## Flags, Analytics, Idempotency, And Rate Limits

- `feature_flags`: authenticated users can read global flags.
- `feature_flag_overrides`: service-side override rules, not client-readable.
- `analytics_events`: append-only client inserts; no client reads.
- `api_idempotency`: stores endpoint/key/hash/response snapshots for idempotent replay.
- `api_rate_limits`: service-owned counters for expensive/destructive paths such as export creation and account deletion.
- `barcode_lookup_misses`: service-owned short-lived negative cache for external barcode provider misses/outages.

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
- `model_invocations`: backend-only provider invocation records with provider/model, status, latency, token counts, estimated cost, error code, and request/response payload snapshots. Clients must use analysis responses rather than reading this table directly.

## Catalog And Multimodal

- `canonical_foods`, `food_aliases`, `food_nutrients`, and `food_portions`: searchable canonical catalog rows and serving metadata.
- `branded_products` and `product_barcodes`: packaged food lookup data for barcode resolution.
- `catalog_food_mappings` and `catalog_ingest_runs`: source mapping and ingest bookkeeping.
- `foods-search`, `barcode-resolve`, `analysis-text-create`, `analysis-label-create`, and `analysis-voice-create` read/write through these tables and analysis job/revision records where applicable.

## Sync, Exports, Privacy, And Insights

- `pending_uploads`: server-visible upload replay state for durable asset workflows.
- `export_requests`: user-owned export state rows. Phase 8 adds artifact metadata:
  - `result_storage_bucket`
  - `result_storage_path`
  - `signed_url`
  - `signed_url_expires_at`
  - `expires_at`
  - `size_bytes`
  - `content_type`
  - `row_counts`
  - `completed_at`
- `account_deletion_requests`: audit rows for destructive account deletion, including requester, status, confirmation, deleted storage object count, error fields, and deletion timestamp.
- `weekly_insights`: feature-flagged user insight snapshots.
- `user_food_defaults`: learned quantity/unit defaults refreshed from saved meals.

## Service-Role Helper RPCs

- `patch_user_settings`: atomic profile/goal/body-measurement settings patch.
- `upsert_user_meal` and `delete_user_meal`: transactional meal writes and soft deletes.
- `refresh_daily_rollup`: derived daily nutrition totals.
- `refresh_user_food_defaults_for_meal`: learned default refresh after saved meals.
- `purge_expired_api_idempotency`: replay-table cleanup.
- `consume_api_rate_limit`: increments and enforces per-user/action rate limits.
- `expired_export_artifacts`: lists expired completed export artifacts due for cleanup.
- `mark_exports_expired`: marks export rows expired after storage cleanup succeeds.
- `expired_meal_assets`: returns retained meal media due for cleanup.
- `mark_meal_assets_deleted`: marks cleaned assets as deleted.
- `users_due_for_weekly_insights`: finds users eligible for scheduled weekly insight generation.

## Storage

Private buckets exist for meal originals, thumbnails, and exports.

- Mobile uploads meal originals and thumbnails under the authenticated user's storage prefix.
- Backend Edge Functions validate path ownership before creating analysis rows.
- Export artifacts are generated server-side and written to `exports-private` under `{user_id}/{export_request_id}/...`.
- Authenticated users do not upload export artifacts directly.
- Export downloads use short-lived signed URLs returned by `exports-create`.
- Expired export artifacts and retained meal media are removed by `media-retention-cleanup`.

## Indexes And Constraints

- `one_active_goal_per_user` enforces one active nutrition goal.
- User/time indexes support profile, meal, template, custom-food, correction-event, export, deletion audit, and insight reads.
- Meal/item constraints reject invalid meal types, sources, negative macros, and non-positive quantities.
- `daily_rollups` primary key is `(user_id, day)`.
- `meals` and reusable entities use `(user_id, client_id)` uniqueness for local-first replay.
- `analysis_jobs` uses `(user_id, client_request_id)` uniqueness for analysis replay.
- `export_requests` uses `(user_id, client_request_id)` uniqueness plus idempotency keys to avoid duplicate server work.
- `weekly_insights` is unique by `(user_id, week_start, insight_type)`.
- `user_food_defaults` is unique by `(user_id, food_ref_kind, food_ref_id)`.
- `meals.source = photo` requires a completed owned `analysis_job_id` and owned `photo_asset_id` through the service-role meal RPC.

## Safe Change Rules

- Add schema changes through a new numbered migration.
- Update [rls.md](rls.md) when table ownership or client access changes.
- Update OpenAPI and generated clients before changing Edge Function response shape.
- Add tests for every new user-owned table, RLS policy, service-role RPC path, storage behavior, or destructive account path.
