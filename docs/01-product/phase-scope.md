# Phase Scope

## Implemented Phase Status

| Phase | Status label | Implemented capability |
| --- | --- | --- |
| Phase 0 | implemented, partly verified locally | Monorepo docs, contract package, Supabase CLI structure, base migrations, storage buckets, generated clients, restored native Android/iOS projects, committed Drift generated code |
| Phase 1 | verified locally | Auth, onboarding, profile, goals, settings patch RPC, feature flags, analytics ingest, local-first settings outbox, backend Phase 1 smoke |
| Phase 2 | source-level only | Home, SnapStrip UI states, camera shell, action analytics, per-action feature flag gates, permission refresh, app lifecycle pause/resume |
| Phase 3 | verified locally | Manual/duplicate meals, Meal Editor, Journal, Progress, templates, custom foods, daily rollups, correction events, meal outbox, backend meal-core smoke, mobile outbox tests |
| Phase 4 | backend verified locally, mobile source-level only | Photo capture assets, backend-only provider orchestration, analysis jobs/revisions, confidence/provenance draft handoff, mock-provider backend smoke |
| Phase 5 | backend verified locally, mobile source-level only | Barcode, OCR assist, text parser, voice transcript parser, catalog seeds, unified Meal Editor draft mapping |
| Phase 6 | backend verified locally, mobile source-level only | Idempotent mutation outbox, deterministic drain order, pull-after-push, conflict recovery surface, upload de-duplication, export request enqueue |
| Phase 7 | backend verified locally, mobile source-level only | Weekly insight snapshots, learned food defaults, feature flag gating, Progress insight/frequent-food widgets |

## Blocked Or Deferred

Blocked until the local/CI environment supplies a JDK and device matrix:

- Android dev APK build.
- iOS simulator/device and Android emulator/device manual acceptance.
- Camera permission/lifecycle, barcode, OCR, voice, offline/reconnect sync, conflict recovery, and weekly insight flag manual validation.

Deferred until Phase 8+ unless explicitly pulled forward:

- Export artifact generation after `exports-create` enqueues a request.
- Full account deletion completion.
- Scheduled/cron weekly insight generation in staging/production.
- Real-provider Gemini/OpenAI staging readiness beyond the local mock provider.

Current acceptance status lives in [../14-project-management/phase-0-7-implementation-review-2026-05-21.md](../14-project-management/phase-0-7-implementation-review-2026-05-21.md).
