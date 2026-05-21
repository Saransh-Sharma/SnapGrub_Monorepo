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

Verified locally on 2026-05-21:

- Contracts, backend typecheck, migration lint, local Supabase reset, Phase 1, Phase 4, RLS, meal-core, Phase 5, Phase 6, and Phase 7 backend smokes.
- Flutter analyze and Flutter tests after build runner generation.

Known blockers before Phase 8:

- Android dev APK build is blocked in the current environment by a missing Java Runtime/JDK.
- iOS and Android manual acceptance is still required for camera lifecycle, photo retry/upload, barcode, OCR, voice permissions, offline/reconnect sync, conflict recovery, and weekly insight flag behavior.
- `exports-create` remains request enqueue only; export artifact generation and account deletion completion are deferred.
- Weekly insight cron/scheduled generation remains a staging operations gap.
