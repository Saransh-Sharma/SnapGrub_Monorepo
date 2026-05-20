# Phase 2 Readiness

Phase 2 SnapStrip/camera work must not begin until all items below pass.

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

## Manual Smoke

- Fresh install opens Auth.
- Signed-in user without profile enters Onboarding.
- Offline onboarding saves locally and queues one `settings.patch`.
- Bootstrap/refresh drains settings when online.
- Relaunch lands on Home.
- Second user cannot see first user's cached profile or goal.
- Settings goal edit persists through the same path.
