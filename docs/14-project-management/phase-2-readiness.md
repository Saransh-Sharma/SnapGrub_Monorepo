# Phase 2 Readiness

This checklist is historical foundation readiness. Phase 2 SnapStrip shell work exists and the broader Phase 0-7 state is tracked in [phase-0-7-implementation-review-2026-05-21.md](phase-0-7-implementation-review-2026-05-21.md).

## Required

- Real `apps/mobile/android` and `apps/mobile/ios` platform projects are committed.
- Dev/staging/prod flavors are configured.
- `npm run check:contracts` passes.
- `npm run backend:lint:migrations` passes.
- `npm run backend:typecheck` passes.
- `supabase db reset` passes locally.
- `npm run backend:test:rls` passes.
- `flutter pub get` passes.
- `dart run build_runner build --delete-conflicting-outputs` passes.
- `dart format --set-exit-if-changed lib test integration_test` passes.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug --flavor dev --dart-define=SNAPGRUB_ENV=dev` passes.
- Manual Phase 0/1 smoke passes.

Current Phase 3 acceptance is tracked in [../10-quality/meal-logging-acceptance.md](../10-quality/meal-logging-acceptance.md).

## Manual Smoke

- Fresh install opens Auth.
- Signed-in user without profile enters Onboarding.
- Offline onboarding saves locally and queues one `settings.patch`.
- Bootstrap/refresh drains settings when online.
- Relaunch lands on Home.
- Second user cannot see first user's cached profile or goal.
- Settings goal edit persists through the same path.
