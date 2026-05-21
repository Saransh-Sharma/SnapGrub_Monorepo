# Release Notes

## Phase 0/1 Stabilization

Developer-facing foundation work:

- Added contract-first OpenAPI validation and generated client freshness checks.
- Added Supabase identity/profile/goals/devices/feature flags/body measurements/idempotency foundations.
- Added backend settings patch RPC and RLS isolation harness.
- Added Flutter auth/onboarding/profile/local-first scaffolding and minimal settings outbox.
- Added Phase 0/1 QA gate and numbered documentation system.

Known blockers before Phase 2:

- Missing local toolchain in the current execution environment.
- Native Flutter platform projects are not yet committed.

## Phase 2/3 Meal Foundation

Developer-facing Phase 2/3 work:

- Added Home/SnapStrip shell with per-action feature flag gating.
- Added Phase 3 meal schema, `meals` Edge Function, meal RPCs, daily rollups, and correction-event return.
- Added local-first Meal Editor, Journal, Progress, Templates, Custom Foods, and expanded outbox sync.
- Added typed correction-event API generation and meal-core smoke test command.
- Updated numbered docs, ADRs, risk register, and Phase 3 acceptance checklist.

Known blockers before Phase 4:

- Flutter/Dart/Deno/Supabase CLI are not available in the current shell.
- Local Supabase env keys are required for RLS and meal-core smoke tests.
- Native Android/iOS platform projects still need to be generated and committed.

## Phase 4 Photo Analysis

Developer-facing Phase 4 work:

- Added `analysis-photo-create` and `analysis-get` API contracts plus generated Dart/TypeScript DTOs.
- Added Supabase tables for meal assets, analysis jobs, analysis revisions, analysis candidates, and model invocations.
- Added owner RLS and meal-write validation so `source=photo` requires a completed owned analysis job and owned photo asset.
- Added Supabase Edge Functions for photo analysis creation and analysis lookup.
- Added backend-only AI provider orchestration with `AI_PROVIDER=mock|gemini|openai`, Gemini/OpenAI model env vars, and no provider keys in mobile.
- Added Flutter camera permission/preview/capture flow, local compressed image assets, thumbnail creation, hashing, upload, analysis loading UX, and Meal Editor photo draft handoff.
- Added Phase 4 acceptance checklist and expanded RLS/meal-core smoke coverage for analysis ownership.

Known blockers before Phase 5:

- Flutter/Dart/Deno/Supabase CLI are not available in the current shell, so Edge Function typecheck, mobile analysis/tests, Supabase reset, RLS tests, and meal-core smoke tests remain unverified locally.
- Local Supabase env keys and backend AI provider secrets must be configured outside the repository for authoritative integration testing.
- Native Android/iOS platform projects still need to be generated and committed.
