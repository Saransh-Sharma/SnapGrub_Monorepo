# Phase 0-10 Deep Implementation Review - 2026-05-21

This standalone audit reviews the current SnapGrub MVP implementation against:

- [UNIFIED SnapGrub MVP Dev Handoff Execution Plan](../UNIFIED%20SnapGrub%20MVP%20Dev%20Handoff%20Execution%20Plan.md)
- [UNIFIED SnapGrub MVP Dev Handoff Report](../UNIFIED%20SnapGrub%20MVP%20Dev%20Handoff%20Report.md)
- [Phase scope](../01-product/phase-scope.md)
- [Phase status](phase-status.md)
- Existing Phase 0-7, Phase 8-10, QA, operations, and release-readiness docs.

## Status Labels

- `verified locally`: automated checks passed in this environment during this audit.
- `implemented/source-level`: source exists and appears wired, but local automated or device acceptance is incomplete.
- `documentation/gate only`: documented as a required gate, but no deployed/runtime evidence exists in repo.
- `staging required`: cannot be accepted without deployed staging secrets, schedules, dashboards, or synthetic traffic.
- `blocked`: required local tool/runtime is unavailable.

## Executive Summary

Overall verdict: Phase 0-8 backend/source implementation is in good shape for a pre-beta codebase, but the MVP is not release-candidate ready. The backend contract, migration, typecheck, and Phase 1/RLS/meal-core/Phase 4/5/6/7/8 smoke checks passed locally after a fresh Supabase database reset. Mobile remains blocked for local verification because `flutter` and `dart` are not on `PATH` in this shell. Phase 9 and Phase 10 remain operational gates, not implemented runtime capabilities.

Readiness by area:

| Area | Verdict |
| --- | --- |
| Backend schema/functions/contracts | `verified locally` through Phase 8 |
| Backend smoke coverage | `verified locally` for Phase 1, RLS, meal core, Phase 4, Phase 5, Phase 6, Phase 7, Phase 8 |
| Mobile source | `implemented/source-level` for Phase 1-8 surfaces |
| Mobile local verification | `blocked` because Flutter/Dart are unavailable in this shell |
| Real AI provider validation | `staging required` |
| Scheduled weekly insight/media cleanup jobs | `staging required` |
| Observability dashboards/alerts/crash reporting | `documentation/gate only` |
| Release candidate builds/distribution | `documentation/gate only` and `blocked` by mobile verification |

The most important blockers are:

1. Mobile analyze/test/build and device acceptance have not been rerun in this environment.
2. Photo-analysis validation is still mock-provider/local; real Gemini/OpenAI staging validation is outstanding.
3. Weekly insight and media cleanup scheduling is implemented as callable backend behavior, but not observed as staging schedules.
4. Phase 9 observability and Phase 10 release-candidate artifacts are documented requirements, not completed runtime gates.

## Verification Results

Commands run during this audit:

| Command | Result | Notes |
| --- | --- | --- |
| `npm run check:contracts` | pass | OpenAPI lint passed and generated clients were fresh. |
| `npm run backend:typecheck` | pass | Deno checked all Supabase Edge Function entrypoints. |
| `npm run backend:lint:migrations` | pass | Migration lint script completed without findings. |
| `command -v flutter; command -v dart` | blocked | Neither command was available on `PATH`; mobile checks were not run. |
| `supabase db reset` from `services/backend/supabase` | pass | Applied migrations `000001` through `000013`; reset completed on branch `phase8Bootstrap`. |
| Backend smoke wrapper from monorepo root | operator error, superseded | Initial wrapper attempted `supabase status` from the wrong project context and failed with missing container `supabase_db_SnapGrub_monorepo`. |
| Backend smoke wrapper with Supabase status resolved from `services/backend/supabase` | pass | All backend smoke scripts below passed with `NODE_OPTIONS=--experimental-websocket` and `AI_PROVIDER=mock`. |
| `npm run backend:test:auth-profile` | pass | Bootstrap/settings/events smoke passed. |
| `npm run backend:test:rls` | pass | RLS isolation checks passed. |
| `npm run backend:test:meal-core` | pass | Meal core smoke checks passed. |
| `npm run backend:test:photo-analysis` | pass | Photo analysis smoke passed with mock provider. |
| `npm run backend:test:multimodal` | pass | Multimodal smoke checks passed. |
| `npm run backend:test:offline-sync` | pass | Sync readiness smoke checks passed. |
| `npm run backend:test:insights` | pass | Insights/defaults smoke checks passed. |
| `npm run backend:test:privacy` | pass | Privacy/export/delete smoke checks passed. |

Supabase status reported stopped `imgproxy` and `pooler` containers. The smoke suite did not require those services, but staging/release acceptance should validate any production dependencies explicitly.

## Evidence Reviewed

Source evidence reviewed:

- Migrations: `services/backend/supabase/migrations/000001_extensions_and_helpers.sql` through `000013_phase8_privacy_export_delete.sql`.
- Edge Functions: profile bootstrap, settings patch, events ingest, meals, templates, custom foods, body measurements, photo analysis, analysis get, barcode, foods search, text/label/voice parsing, weekly insights, exports, account deletion, and media cleanup.
- Backend tests: Phase 1, RLS, meal core, Phase 4, Phase 5, Phase 6, Phase 7, Phase 8 smoke scripts.
- API contracts: `packages/api-contracts/openapi.yaml` includes Phase 0-8 endpoint coverage.
- CI: `.github/workflows/ci.yml` has contracts/backend and mobile jobs, including Phase 8 backend smoke and Flutter APK build gates.
- Mobile routes/features: `apps/mobile/lib/app/router/app_router.dart`, Home/SnapStrip, capture controller, meal editor, journal, progress, barcode, text, voice, photo analysis, privacy/export/delete, sync status.
- Operations/release docs: `docs/11-operations/beta-observability.md`, `docs/10-quality/release-checklist.md`, manual acceptance checklists, runbooks.

## Phase-by-Phase Review

| Phase | Current status | Evidence | Remaining gaps |
| --- | --- | --- | --- |
| Phase 0 - Repo, contracts, environments | `verified locally` for backend/contracts; mobile toolchain `blocked` | Contract check passed; migrations reset cleanly; native Android/iOS files and Drift generated source exist; CI defines backend and mobile jobs. | Flutter/Dart unavailable locally; Android/iOS builds and device acceptance still need a working mobile toolchain. |
| Phase 1 - Auth, onboarding, profile, goals | Backend `verified locally`; mobile `implemented/source-level` | Phase 1 smoke passed; profile bootstrap/settings/events functions exist; onboarding/profile repository tests exist; router gates auth/onboarding/home. | Manual sign-in and onboarding acceptance on iOS/Android remains required. |
| Phase 2 - Home + SnapStrip camera shell | `implemented/source-level` | Home screen wires SnapStrip, sync attention, progress, recent meals, lifecycle pause/resume; capture controller handles permission, preview, analytics, feature gates. | Camera permission, denied/granted, lifecycle, and capture behavior need device validation. |
| Phase 3 - Meal domain, local journal, editor | Backend `verified locally`; mobile `implemented/source-level` | Meal core smoke passed; routes and modules exist for Meal Editor, Journal, Progress, templates, custom foods; outbox tests cover meal save/delete. | Offline meal save/reconnect sync and editor UX need device/manual acceptance. |
| Phase 4 - Photo analysis MVP | Backend `verified locally`; mobile `implemented/source-level`; real provider `staging required` | Phase 4 smoke passed with mock provider; photo analysis functions, analysis tables, storage path ownership, mobile photo-analysis route/repository exist. | Real Gemini/OpenAI staging validation, mobile upload retry/failure UX, and device camera flow remain unaccepted. |
| Phase 5 - Barcode, OCR, text, voice | Backend `verified locally`; mobile `implemented/source-level` | Phase 5 smoke passed; barcode, foods search, label/text/voice functions exist; mobile barcode/text/voice routes and draft mapping exist. | Scanner/OCR/voice permission and real-device flows remain unvalidated. |
| Phase 6 - Offline sync/idempotency/conflict | Backend `verified locally`; mobile `implemented/source-level` | Phase 6 smoke passed; sync controller drains early commands, settings, custom foods, templates, meals, deferred commands, then pulls authoritative state; Home links conflict/failed states to Sync. | Conflict recovery and reconnect behavior need manual device testing; long-running outbox behavior is not proven by local mobile checks. |
| Phase 7 - Insights, retention, delight | Backend `verified locally`; mobile `implemented/source-level`; schedules `staging required` | Phase 7 smoke passed; weekly insights function supports single-user and batch generation; Progress has insight/frequent-food surfaces; feature flag gating is documented. | Scheduled weekly insight generation and feature flag behavior need staging observation and device acceptance. |
| Phase 8 - Privacy, export, delete | Backend `verified locally`; mobile `implemented/source-level` | Phase 8 smoke passed; export artifact generation, signed URL polling, account deletion, media cleanup, rate limit helper, privacy routes/screens, toggles, export and delete UI exist. | Mobile privacy/export/delete UX needs Flutter checks and device acceptance; production data-retention review and staging cleanup schedule remain open. |
| Phase 9 - Observability, QA, beta hardening | `documentation/gate only`; `staging required` | Beta observability doc lists metrics, dashboards, alerts, staging synthetic tests, schedules, and blockers. | No repo evidence of deployed dashboards, alert policies, crash reporting provider config, or completed synthetic staging tests. |
| Phase 10 - MVP release candidate | `documentation/gate only`; mobile `blocked` | Release checklist defines backend, mobile, privacy, observability, and release-candidate gates. | No signed Android/iOS release artifacts, TestFlight/Internal Testing distribution, production deploy evidence, staged rollout monitoring, or RC smoke evidence. |

## Findings by Severity

### Critical

1. Phase 9/10 are not complete implementation phases yet.
   - Impact: The app cannot be honestly called release-candidate ready because dashboards, alerts, crash reporting, staging synthetic tests, production rollout evidence, and signed mobile artifacts are not present.
   - Evidence: `docs/11-operations/beta-observability.md` and `docs/10-quality/release-checklist.md` define gates, but no deployed/runtime evidence is in repo.
   - Recommendation: Treat Phase 9/10 as entry criteria for beta/RC, not completed work. Require screenshots/links/config exports or CI artifacts for observability, crash reporting, and release builds.

2. Mobile acceptance is blocked in this environment.
   - Impact: Phase 2-8 mobile surfaces are source-level only; camera, barcode, OCR, voice, offline sync, privacy, export, delete, and clear-local-data cannot be accepted without Flutter checks and device testing.
   - Evidence: `flutter` and `dart` are not on `PATH`; mobile routes and source exist, but `flutter analyze`, `flutter test`, and mobile builds were not run.
   - Recommendation: Install/configure Flutter and Dart locally or rely on a green CI mobile job, then run the full mobile gate and manual iOS/Android acceptance.

3. Staging validation for real AI and scheduled jobs is missing.
   - Impact: Core MVP trust and retention paths are only locally/mock verified. Real provider latency, failure modes, costs, weekly insight schedules, and cleanup schedules remain unknown.
   - Evidence: Phase 4 smoke passed with `AI_PROVIDER=mock`; weekly insight and cleanup functions exist, but no staging schedule run evidence was found.
   - Recommendation: Deploy staging functions/migrations, configure server-side provider secrets, run real-provider and forced-failure tests, then observe scheduled weekly insight and cleanup runs before beta.

### High

1. Backend checks are strong but mostly smoke-level.
   - Impact: Happy paths are covered, but edge cases such as export idempotency replay, invalid delete confirmation, rate-limit exhaustion, malformed multimodal inputs, and provider fallback behavior should be tested before beta.
   - Evidence: Phase 8 smoke verifies export generation/polling/download, deletion, and cleanup, but does not cover every acceptance item listed in the Phase 8 QA doc.
   - Recommendation: Add targeted negative/invariant smoke tests for destructive and expensive paths.

2. Device-only UX remains the largest unverified surface.
   - Impact: Camera lifecycle, permission-denied paths, scanner hardware, microphone permission, OS download/link handling, and local cache clearing can fail even when source-level code looks correct.
   - Evidence: Home, capture, barcode, text, voice, privacy, and sync routes exist, but local Flutter/device checks were blocked.
   - Recommendation: Run the manual test plan on at least one iOS simulator/device and one Android emulator/device after mobile checks pass.

3. Export mobile UI exposes a signed URL but does not prove the complete download flow.
   - Impact: Users may receive a copyable URL without an in-app open/share/download path, and signed URL refresh behavior is not exercised by the visible UI path.
   - Evidence: `PrivacyRemoteService.getExport` exists, but `ExportDataScreen` stores the create response and `_ExportStatusCard` copies the signed URL.
   - Recommendation: Validate this UX on device and decide whether MVP requires open/share/download plus refresh polling before RC.

### Medium

1. CI contains the intended gates, but local mobile parity is absent.
   - Impact: Developers cannot reproduce the full mobile gate from this shell, increasing dependency on CI-only feedback.
   - Evidence: `.github/workflows/ci.yml` defines Flutter pub get, build runner, format, analyze, test, and debug APK build; local `flutter`/`dart` are unavailable.
   - Recommendation: Document local Flutter installation expectations or provide a bootstrap script that verifies and reports missing mobile prerequisites.

2. Operations docs are thorough but not connected to concrete artifacts.
   - Impact: The team can know what to monitor, but cannot prove the monitor exists or fired.
   - Evidence: Beta observability lists metric sources, dashboards, alerts, and synthetic tests; no dashboard-as-code or alert config was found.
   - Recommendation: Add dashboard/alert artifact links or checked-in configuration once the observability provider is chosen.

3. Mobile integration coverage is thin beyond Phase 1.
   - Impact: Feature modules can regress together across routing, repository, outbox, and Supabase wiring without an end-to-end mobile test catching it.
   - Evidence: `apps/mobile/integration_test/auth/onboarding_smoke_test.dart` exists; unit tests cover important isolated pieces, but later phase integration tests are not present.
   - Recommendation: Add a small set of integration tests for meal save, photo draft handoff, sync conflict display, and privacy/export navigation.

### Low

1. Supabase local status reported stopped optional services.
   - Impact: This did not block the audited smoke suite, but unexamined service dependencies can surprise staging/prod parity.
   - Evidence: `supabase status -o env` reported stopped `imgproxy` and `pooler`.
   - Recommendation: Explicitly mark which Supabase local services are required for MVP tests and which are optional.

2. Existing reports and handoff addenda overlap.
   - Impact: Multiple current-state documents can drift unless one remains canonical.
   - Evidence: Existing Phase 0-7 and Phase 8-10 review docs overlap with phase status and handoff addenda.
   - Recommendation: Keep this deep review as the dated audit artifact and continue using `phase-status.md` as the short current-state pointer.

## Positive Findings

- Backend migration chain is coherent through Phase 8 and resets cleanly.
- OpenAPI is valid and generated API clients are fresh.
- Edge Function typecheck passes across all current function entrypoints.
- Backend smoke coverage now spans identity/settings/events, RLS, meal core, photo analysis, multimodal entry, sync readiness, insights/defaults, privacy/export/delete.
- Privacy/export/delete implementation is materially beyond a placeholder: it creates private artifacts, returns signed URLs, supports polling, deletes user-owned storage/Auth rows, and exposes cleanup paths.
- Mobile source has coherent route coverage for the MVP surfaces, including Home/SnapStrip, meal editor, journal, progress, barcode, text, voice, photo analysis, sync, privacy, export, delete, and clear local data.
- CI has explicit backend and mobile jobs aligned with the release checklist.

## Release-Gate Recommendations

Immediate gates before Phase 9 beta hardening:

1. Put Flutter/Dart on `PATH`, run `flutter pub get`, build runner, format check, `flutter analyze`, `flutter test`, and Android dev APK build.
2. Run iOS/Android manual acceptance for auth, onboarding, capture, barcode, OCR, voice, meal save, offline reconnect, conflict recovery, insights flag behavior, privacy toggles, export, delete account, and clear local data.
3. Deploy staging Supabase migrations/functions and rerun backend smoke tests against staging.
4. Configure real AI provider secrets server-side only and run mock, real-provider, and forced-failure photo-analysis tests.
5. Configure and observe staging schedules for `weekly-insights-generate` and `media-retention-cleanup`.

Before Phase 10 release candidate:

1. Provide evidence for dashboards, alerts, crash reporting, and synthetic staging tests.
2. Validate export/delete/security flows in staging, including negative/destructive cases.
3. Produce Android Internal Testing and iOS TestFlight builds.
4. Run full end-to-end smoke against the release-candidate backend.
5. Confirm no P0/P1 issues remain and beta crash-free target is measurable.

## Final Verdict

Phase 0-8 backend/source work is substantially implemented, and the local backend evidence is strong enough to proceed toward Phase 9 hardening. The implementation is not beta-ready until mobile verification, device acceptance, real-provider staging validation, scheduled job observation, and observability gates are complete. Phase 9 and Phase 10 should remain open release gates, not marked complete, until runtime evidence exists outside the repository.
