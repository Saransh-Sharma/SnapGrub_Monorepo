# Release Checklist

The legacy compatibility checklist remains in [../qa/release-checklist.md](../qa/release-checklist.md). This numbered checklist is canonical for current Phase 8-10 readiness.

## Backend Gates

- `npm run check:contracts` passes.
- `npm run backend:typecheck` passes.
- `npm run backend:lint:migrations` passes.
- `supabase db reset` applies all migrations cleanly.
- Backend smokes pass through Phase 8:
  - `npm run backend:test:phase1`
  - `npm run backend:test:rls`
  - `npm run backend:test:meal-core`
  - `npm run backend:test:phase4`
  - `npm run backend:test:phase5`
  - `npm run backend:test:phase6`
  - `npm run backend:test:phase7`
  - `npm run backend:test:phase8`
- Staging Supabase migrations/functions are deployed.
- Real AI provider secrets are configured server-side only.
- Weekly insights and media cleanup schedules are active and observed in staging.
- Export/delete/security smoke passes in staging.

## Mobile Gates

- Flutter/Dart are available on `PATH`.
- `flutter pub get` passes.
- `dart run build_runner build --delete-conflicting-outputs` passes.
- `dart format --set-exit-if-changed lib test integration_test` passes.
- `flutter analyze` passes.
- `flutter test` passes.
- Android dev APK build passes.
- iOS simulator build passes where CI/local runner supports it.
- iOS/Android manual acceptance passes for auth, onboarding, capture, barcode, OCR, voice, meal save, offline sync, insights, privacy, export, delete, and clear local data.

## Privacy And Compliance Gates

- AI improvement consent is explicit and mutable.
- Cloud media storage and original-photo retention toggles persist and sync.
- JSON and CSV exports generate private artifacts in `exports-private`.
- Signed export URLs expire and can be refreshed by polling.
- Account deletion requires explicit `DELETE` confirmation and removes user-owned cloud data/storage.
- Clear local data does not delete cloud account data.
- No service-role keys, AI provider keys, or private secrets exist in mobile env files.

## Observability Gates

- Dashboards cover analysis success/latency, provider fallback, AI spend, storage/export failures, sync failures/conflicts, Edge Function 5xx, scheduled job success, meals saved/day, and low-confidence analysis rate.
- Alerts exist for analysis failure >5%, p95 analysis >12 seconds, Edge Function 5xx spikes, export/storage failures, AI spend threshold, provider outage, sync failure spike, and missed schedules.
- Crash reporting is enabled for beta/release builds.
- Synthetic staging tests in [../11-operations/beta-observability.md](../11-operations/beta-observability.md) pass.

## Release Candidate Gates

- Production Supabase project is configured.
- Production migrations are applied.
- Production functions are deployed.
- Storage buckets are private.
- Runbooks are current.
- App icons, launch screens, camera/microphone/privacy strings, and store privacy labels are complete.
- Android internal testing build and iOS TestFlight build are distributed.
- Full end-to-end smoke passes against release candidate backend.
- No known P0/P1 issues remain.
- Beta crash-free sessions target is at least 99%.
