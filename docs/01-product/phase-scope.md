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
| Phase 6 | backend verified locally, mobile source-level only | Idempotent mutation outbox, deterministic drain order, pull-after-push, conflict recovery surface, upload de-duplication, export create outbox command |
| Phase 7 | backend verified locally, mobile source-level only | Weekly insight snapshots, learned food defaults, feature flag gating, Progress insight/frequent-food widgets |
| Phase 8 | backend verified locally, mobile source-level only | Privacy settings surfaces, export artifact generation, signed export URL polling, account deletion, local cache clearing, media/export cleanup endpoint, rate-limit helper |
| Phase 9 | documentation/gate source only | Beta observability checklist, CI Phase 8 backend smoke, release-blocker definitions |
| Phase 10 | documented gate | Release-candidate checklist and acceptance criteria; production release not executed |

## Blocked Or External Gates

Blocked until the local/CI environment exposes Flutter/Dart and device matrix:

- `flutter analyze`
- `flutter test`
- Android dev APK build.
- iOS simulator/device and Android emulator/device manual acceptance.
- Camera permission/lifecycle, barcode, OCR, voice, offline/reconnect sync, conflict recovery, privacy/export/delete, and weekly insight flag manual validation.

Staging or production gates:

- Real-provider Gemini/OpenAI staging readiness beyond local mock provider.
- Scheduled weekly insight generation in staging/production.
- Scheduled media-retention cleanup in staging/production.
- Observability dashboards and alerts.
- Crash reporting and release symbol handling.
- TestFlight/Android internal testing release artifacts.

## Deferred Post-MVP Scope

- Full AI coach/chat.
- Wearable calorie adjustment engine.
- Restaurant/menu scanner.
- Meal planning and fasting programs.
- Social/community features.
- Rich micronutrient scoring.

Current acceptance status lives in:

- [Phase 0-7 implementation review](../14-project-management/phase-0-7-implementation-review-2026-05-21.md)
- [Phase 8-10 implementation review](../14-project-management/phase-8-10-implementation-review-2026-05-21.md)
