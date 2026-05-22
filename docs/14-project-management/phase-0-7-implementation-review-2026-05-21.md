# Phase 0-7 Implementation Review - 2026-05-21

This is a historical Phase 0-7 implementation addendum for the unified handoff docs. The current implementation review is [phase-8-10-implementation-review-2026-05-21.md](phase-8-10-implementation-review-2026-05-21.md), which supersedes the Phase 8 deferred-scope notes below.

## Status Labels

- `implemented`: source exists and is wired into the app/backend.
- `verified locally`: automated local checks passed in this environment.
- `source-level only`: source exists but still needs emulator/device/manual acceptance.
- `blocked`: acceptance cannot complete until a local/CI dependency is available.
- `deferred`: intentionally outside Phase 0-7 scope.

## Verification Snapshot

Passed on 2026-05-21:

- `npm run check:contracts`
- `npm run backend:typecheck`
- `npm run backend:lint:migrations`
- `bash scripts/run-local-supabase.sh`
- `npm run backend:test:auth-profile`
- `npm run backend:test:photo-analysis`
- `npm run backend:test:rls`
- `npm run backend:test:meal-core`
- `npm run backend:test:multimodal`
- `npm run backend:test:offline-sync`
- `npm run backend:test:insights`
- `flutter analyze`
- `flutter test`

Blocked during this historical Phase 0-7 review:

- `flutter build apk --debug --flavor dev --dart-define=SNAPGRUB_ENV=dev` could not be treated as accepted until the Android Java toolchain was available in the verification environment.
- Full iOS and Android manual acceptance because it still needs at least one iOS simulator/device and one Android emulator/device.

## Phase Review

| Phase | Current state | Evidence | Remaining gap |
| --- | --- | --- | --- |
| Phase 0 | verified locally | Native Android/iOS platform files restored, Drift generated code committed, bootstrap script checks real project files, contracts/backend/mobile tests pass through available local gates | Android debug APK build is blocked by missing JDK; device acceptance still required |
| Phase 1 | verified locally for backend and mobile unit coverage | `profile-bootstrap`, `settings-patch`, and `events-ingest` Phase 1 smoke passes; onboarding/profile outbox tests exist | Manual sign-in/onboarding acceptance still required on iOS and Android |
| Phase 2 | source-level only | Home/SnapStrip shell exists, camera permission refresh and app lifecycle pause/resume are wired | Manual camera permission denied/granted/background/foreground acceptance remains |
| Phase 3 | verified locally for backend and mobile unit coverage | Meal core smoke passes; mobile meal save/delete outbox and draft tests pass | Offline meal save/reconnect sync must be confirmed on devices |
| Phase 4 | verified locally for backend; source-level mobile | Mock provider photo-analysis smoke passes with private storage upload, `analysis-photo-create`, `analysis-get`, model invocation, and path ownership rejection | Mobile upload retry/failure UX and real device camera flow require manual acceptance |
| Phase 5 | verified locally for backend; source-level mobile | Phase 5 backend smoke passes; barcode/OCR/text/voice draft mapping tests pass | Barcode scanner, OCR label assist, and voice permission denial need device validation |
| Phase 6 | verified locally for backend; source-level mobile | Phase 6 backend smoke passes; conflict state and outbox queries have unit coverage; CI uses `NODE_OPTIONS=--experimental-websocket` | Conflict recovery must be exercised from Home/Sync status during device QA |
| Phase 7 | verified locally for backend; source-level mobile | Phase 7 backend smoke passes; CI now runs Phase 7; weekly insights flag remains disabled by default | Scheduled/cron generation and weekly-insight flag behavior need staging ops validation |

## Implemented Gap Closures

- Restored Flutter Android/iOS native platform projects under `apps/mobile`.
- Added dev/staging/prod Android flavors and iOS bundle/display-name build settings.
- Generated `apps/mobile/lib/data/db/drift/app_database.g.dart`.
- Strengthened `scripts/bootstrap-mobile-platforms.sh` so it checks concrete Gradle/Xcode files rather than directories.
- Added backend smoke coverage for Phase 1 and Phase 4.
- Added mobile unit coverage for Drift open/migration, onboarding/profile outbox, meal save/delete outbox, photo/multimodal draft mapping, and sync conflict state.
- Added Home camera lifecycle initialization/pause/resume behavior.
- Added Home sync attention entry point for failed/conflict states.
- Added CI backend integration gates for Phase 1, Phase 4, and Phase 7, with `NODE_OPTIONS=--experimental-websocket`.

## Historical Deferred Scope Superseded By Phase 8

- In the Phase 6 boundary, `exports-create` created an export request row for outbox replay.
- Export artifacts, signed URL polling, account deletion, mobile privacy screens, and media cleanup are implemented in the later Phase 8 pass documented in [phase-8-10-implementation-review-2026-05-21.md](phase-8-10-implementation-review-2026-05-21.md).
- Weekly insight cron/scheduled generation is an operations/staging gate; Phase 7 currently verifies the backend generation path and feature-flagged UI source.

## Execution Plan For Remaining Gaps

1. Install a JDK locally and in CI, then rerun the Android dev APK build.
2. Run mobile manual acceptance on one Android emulator/device and one iOS simulator/device.
3. Exercise camera lifecycle, photo upload retry, barcode scan, OCR label assist, voice denial, offline meal save, reconnect sync, conflict recovery, and weekly insight flag behavior.
4. Configure staging Supabase secrets for mock and real AI-provider readiness checks.
5. Add scheduled weekly insight generation only after Phase 7 staging validation is complete.
