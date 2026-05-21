# Frontend

The mobile app lives in `apps/mobile` and uses Flutter, Riverpod, GoRouter, Drift, Supabase Flutter, and generated API contracts.

## Setup

```sh
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Generated API models are consumed from `packages/api-contracts/generated/dart`. Run `npm run check:contracts` from the repo root after API contract changes.

Native Android/iOS platform projects are present with dev/staging/prod Android flavors and iOS bundle/display-name settings. Android APK builds require a local JDK, and the latest local verification shell still needs `flutter`/`dart` on `PATH`. Track current readiness in [../14-project-management/phase-status.md](../14-project-management/phase-status.md) and [../14-project-management/phase-8-10-implementation-review-2026-05-21.md](../14-project-management/phase-8-10-implementation-review-2026-05-21.md).

## Local Env

Use Dart defines for:

- `SNAPGRUB_ENV`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Do not add private keys to mobile env files.

More detail:

- [architecture.md](architecture.md)
- [auth-onboarding-profile.md](auth-onboarding-profile.md)
- [offline-outbox.md](offline-outbox.md)
- [privacy-export-delete.md](privacy-export-delete.md)

## Key Routes

- `/home`: SnapStrip shell, progress summary, quick actions.
- `/meal-editor`: manual/duplicate meal create and edit.
- `/journal`: today’s saved meals.
- `/progress`: local daily rollup view.
- `/templates`: reusable meal snapshots.
- `/custom-foods`: user-owned custom foods.
- `/sync`: outbox status and conflict/failure recovery.
- `/settings/privacy`: privacy controls, export, delete account, and clear local data.
