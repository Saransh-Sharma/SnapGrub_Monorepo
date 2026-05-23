# Release Notes

## Phase 0/1 Stabilization

Developer-facing foundation work:

- Added contract-first OpenAPI validation and generated client freshness checks.
- Added Supabase identity/profile/goals/devices/feature flags/body measurements/idempotency foundations.
- Added backend settings patch RPC and RLS isolation harness.
- Added Flutter auth/onboarding/profile/local-first scaffolding and minimal settings outbox.
- Added Phase 0/1 QA gate and numbered documentation system.

Historical blockers before Phase 2, now superseded by the 2026-05-21 review:

- Local toolchain availability.
- Native Flutter platform project generation.

## Phase 2/3 Meal Foundation

Developer-facing Phase 2/3 work:

- Added Home/SnapStrip shell with per-action feature flag gating.
- Added Phase 3 meal schema, `meals` Edge Function, meal RPCs, daily rollups, and correction-event return.
- Added local-first Meal Editor, Journal, Progress, Templates, Custom Foods, and expanded outbox sync.
- Added typed correction-event API generation and meal-core smoke test command.
- Updated numbered docs, ADRs, risk register, and Phase 3 acceptance checklist.

Historical blockers before Phase 4, now superseded by the 2026-05-21 review:

- Local toolchain availability.
- Local Supabase env setup for RLS and meal-core smoke tests.
- Native Android/iOS platform project generation.

## Phase 4 Photo Analysis

Developer-facing Phase 4 work:

- Added `analysis-photo-create` and `analysis-get` API contracts plus generated Dart/TypeScript DTOs.
- Added Supabase tables for meal assets, analysis jobs, analysis revisions, analysis candidates, and model invocations.
- Added owner RLS and meal-write validation so `source=photo` requires a completed owned analysis job and owned photo asset.
- Added Supabase Edge Functions for photo analysis creation and analysis lookup.
- Added backend-only AI provider orchestration with `AI_PROVIDER=mock|gemini|openai`, Gemini/OpenAI model env vars, and no provider keys in mobile.
- Added Flutter camera permission/preview/capture flow, local compressed image assets, thumbnail creation, hashing, upload, analysis loading UX, and Meal Editor photo draft handoff.
- Added Phase 4 acceptance checklist and expanded RLS/meal-core smoke coverage for analysis ownership.

Historical blockers before Phase 5, now superseded by the 2026-05-21 review:

- Local toolchain availability.
- Local Supabase env keys and backend AI provider secrets.
- Native Android/iOS platform project generation.

## Phase 5-7 Source Completion And Gap Closure

Developer-facing Phase 5-7 work:

- Added Phase 5 barcode, OCR label assist, text entry, voice transcript parser, catalog/search resolver, and unified Meal Editor draft mapping.
- Added Phase 6 idempotent outbox replay surfaces, deterministic drain behavior, conflict/failure surfacing from Home, export request enqueueing, and durable asset/analytics/body-measurement command support.
- Added Phase 7 weekly insight snapshots, learned food defaults, feature flag gating, and local Progress/frequent-food UI surfaces.
- Restored native Flutter Android/iOS platform projects and generated committed Drift code.
- Added backend smoke coverage for Phase 1 and Phase 4 and wired Phase 1, Phase 4, and Phase 7 into CI.
- Added mobile tests for Drift schema open/migration, onboarding/profile outbox, meal save/delete outbox, draft mapping, and sync conflict state.
- Added Phase 5/6/7 QA acceptance checklists.

Verified locally during the Phase 0-7 closure audit on 2026-05-21:

- Contracts, backend typecheck, migration lint, local Supabase reset, Phase 1, Phase 4, RLS, meal-core, Phase 5, Phase 6, and Phase 7 backend smokes.

Historical blockers before Phase 8, now superseded by the Phase 8 implementation review:

- Mobile toolchain availability and device acceptance.
- Real-provider staging validation.
- Weekly insight scheduled invocation in staging.
- Export artifact generation, signed export polling, account deletion, and retention cleanup.

## Phase 8 Privacy, Export, Delete

Developer-facing Phase 8 work:

- Added Phase 8 OpenAPI coverage for export create/poll, account deletion, and service-role media retention cleanup.
- Added migration `000013_phase8_privacy_export_delete.sql` with export artifact metadata, account deletion audit state, API rate-limit rows, cleanup helper RPCs, and batch weekly-insight user selection.
- Changed `exports-create` from Phase 6 request-row creation to synchronous MVP artifact generation for `nutrition_json` and `journal_csv`.
- Export artifacts now write to the private `exports-private` bucket, include row counts and content metadata, and return short-lived signed URLs.
- Added `GET /exports-create/{export_request_id}` to poll owned export state and refresh signed download URLs.
- Added `account-delete` with explicit `DELETE` confirmation, service-role storage cleanup, auth-user deletion, and deletion audit rows.
- Added `media-retention-cleanup` for expired export artifacts and expired retained meal media.
- Extended `weekly-insights-generate` so service-role scheduled jobs can generate insights for due users without passing one `user_id`.
- Added mobile privacy surfaces for AI consent, media retention, export, delete account, and clear local data under Settings.
- Added `npm run backend:test:privacy` and wired it into CI.

Backend hardening follow-up:

- Added migrations `000014` through `000018` for runtime grants, media retention backfill, day-listing RPCs, remediation helpers, barcode miss caching, stricter model invocation privacy, custom-food ownership enforcement, and safer export cleanup marking.
- Added thumbnail path ownership validation, analysis rate limits, stale idempotency recovery, recursive account storage cleanup, feature flag rollout/rule evaluation, timezone-aware weekly insight windows, environment-configurable CORS, and paginated export reads.
- Added `infra/supabase/scheduled-jobs.example.sql` for staging/prod pg_cron + pg_net setup.
- Added `npm run backend:test:remediation` and `npm run backend:test:remediation-unit` to CI.

Verified locally on 2026-05-21:

- Contracts, backend typecheck, migration lint, local Supabase reset through `000018`, Phase 1, RLS, meal-core, Phase 4, Phase 5, Phase 6, Phase 7, Phase 8, and backend remediation smokes.

Known blockers before Phase 9 beta hardening:

- Flutter/Dart are available locally; mobile analyze and tests pass after cleaning ignored iOS ephemeral state. Mobile build artifacts still require CI/device evidence.
- iOS and Android manual acceptance is still required for existing capture/multimodal/sync flows and new privacy/export/delete flows.
- Real Gemini/OpenAI staging validation still requires server-side staging secrets.
- Scheduled weekly insight and media-retention cleanup jobs must be deployed and observed in staging.
- Dashboards, alerts, crash reporting, and release-candidate mobile distribution remain Phase 9/10 operational gates.

## Phase 9/10 Readiness Groundwork

- Added beta observability gates covering analysis latency/failure, storage/export failures, sync conflicts, scheduled job success, AI spend, and release blockers.
- Documented staging synthetic tests for provider failures, export/delete flows, cleanup jobs, and batch weekly insights.
- Phase 10 remains blocked until Phase 8 device QA, Phase 9 observability, staging schedules, and signed mobile release builds are complete.
