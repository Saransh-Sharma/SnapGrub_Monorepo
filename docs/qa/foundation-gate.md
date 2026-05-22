# Foundation Gate Before Camera Work

Run these checks before starting SnapStrip/camera work.

## Required Toolchain

- Node 20
- Flutter stable
- Dart via Flutter
- Supabase CLI
- Deno
- Java, if replacing the lightweight generator with OpenAPI Generator CLI

## Contract Checks

```sh
npm ci
npm run check:contracts
```

Expected: OpenAPI validates and generated Dart/TypeScript files are fresh.

## Backend Checks

```sh
npm run backend:lint:migrations
npm run backend:typecheck
cd services/backend/supabase
supabase start
supabase db reset
supabase status -o env > /tmp/snapgrub-supabase.env
cd ../../..
set -a
. /tmp/snapgrub-supabase.env
set +a
npm run backend:test:rls
```

Expected: migrations apply, Edge Functions typecheck, and user A cannot access user B data.

## Mobile Checks

Native platform folders must be committed before CI is authoritative.

```sh
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug --flavor dev --dart-define=SNAPGRUB_ENV=dev
```

Expected: dev flavor builds from committed Android/iOS projects.

## Manual Smoke

- Fresh install opens Auth.
- Authenticated user with no profile lands in Onboarding.
- Offline onboarding saves locally and queues one `settings.patch`.
- Bootstrap/drain syncs pending settings when online.
- Relaunch lands on Home.
- Second signed-in user does not see first user local profile or goal.
- Settings goal edit persists through the same settings path.
