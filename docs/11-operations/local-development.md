# Local Development

## Required Toolchain

- Node 20
- Flutter stable
- Dart via Flutter
- Supabase CLI
- Deno

## Common Commands

```sh
npm ci
npm run check:contracts
npm run backend:lint:migrations
```

For Supabase:

```sh
cd services/backend/supabase
supabase start
supabase db reset
```

For Flutter:

```sh
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

Current blocker: native Android/iOS platform projects are not yet committed.
