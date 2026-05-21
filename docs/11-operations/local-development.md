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
npm run backend:typecheck
```

## Phase 4 Photo Analysis Env

Copy `services/backend/supabase/.env.example` and set backend-only AI values in the Supabase runtime environment:

```sh
AI_PROVIDER=mock
GEMINI_API_KEY=
GEMINI_PRIMARY_MODEL=gemini-3.1-flash-lite
OPENAI_API_KEY=
OPENAI_FALLBACK_MODEL=gpt-4.1-mini
AI_INPUT_PRICE_PER_1M=0.25
AI_OUTPUT_PRICE_PER_1M=1.50
```

Use `AI_PROVIDER=mock` for local analysis without external provider keys. Gemini/OpenAI keys must never be added to mobile env files or committed.

For Supabase:

```sh
cd services/backend/supabase
supabase start
supabase db reset
supabase status -o env > /tmp/snapgrub-supabase.env
```

Load Supabase env before backend integration tests:

```sh
set -a
. /tmp/snapgrub-supabase.env
set +a
npm run backend:test:rls
npm run backend:test:meal-core
```

For Flutter:

```sh
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Current blockers in this execution environment: Deno, Flutter/Dart, and Supabase CLI are unavailable, so authoritative Edge Function typecheck, mobile checks, Supabase reset, RLS tests, and meal-core smoke tests cannot be run here. Native Android/iOS platform projects are not yet committed.
