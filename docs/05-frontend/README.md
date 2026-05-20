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

Native Android/iOS platform projects are still a Phase 0/1 blocker until generated and committed. Track readiness in [../14-project-management/phase-2-readiness.md](../14-project-management/phase-2-readiness.md).

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
