# Local Development

## Required Toolchain

- Node 20
- Flutter stable
- Dart via Flutter
- JDK for Android Gradle builds
- Docker Desktop
- Supabase CLI
- Deno

On macOS, install the backend tools with Homebrew:

```sh
brew install supabase/tap/supabase deno
```

## Common Commands

```sh
npm ci
npm run check:contracts
npm run backend:lint:migrations
npm run backend:typecheck
```

## Photo Analysis Env

Copy `services/backend/supabase/functions/.env.example` to `services/backend/supabase/functions/.env` and set backend-only AI values in the Supabase Edge Function runtime environment:

```sh
CORS_ALLOW_ORIGIN=http://localhost:3000
AI_PROVIDER=mock
GEMINI_API_KEY=
GEMINI_PRIMARY_MODEL=gemini-3.1-flash-lite
OPENAI_API_KEY=
OPENAI_FALLBACK_MODEL=gpt-4.1-mini
AI_INPUT_PRICE_PER_1M=0.25
AI_OUTPUT_PRICE_PER_1M=1.50
```

`CORS_ALLOW_ORIGIN` and `AI_PROVIDER` are required by the Edge Functions runtime. Use `AI_PROVIDER=mock` for local analysis without external provider keys. Gemini/OpenAI keys must never be added to mobile env files or committed.

## Local Supabase

Start Docker Desktop first. From the repo root, start Supabase and reset the database from the checked-in migrations:

```sh
bash scripts/run-local-supabase.sh
```

The local stack exposes:

- API: `http://127.0.0.1:54321`
- DB: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`
- Studio: `http://127.0.0.1:54323`
- Inbucket/Mailpit: `http://127.0.0.1:54324`

Capture local Supabase values before running integration tests:

```sh
cd services/backend/supabase
supabase status -o env > /tmp/snapgrub-supabase.env
```

The generated local keys are for local development only. Do not commit them, and do not pass service-role keys or AI provider keys to Flutter. Mobile builds receive only `SUPABASE_URL` and the public anon/publishable key.

The Supabase CLI creates local runtime state under `services/backend/supabase/.branches/` and `services/backend/supabase/.temp/`; these directories are ignored by git.

Load Supabase env before backend integration tests:

```sh
set -a
. /tmp/snapgrub-supabase.env
set +a
export NODE_OPTIONS=--experimental-websocket
npm run backend:test:auth-profile
npm run backend:test:photo-analysis
npm run backend:test:rls
npm run backend:test:meal-core
npm run backend:test:multimodal
npm run backend:test:offline-sync
npm run backend:test:insights
npm run backend:test:privacy
```

`NODE_OPTIONS=--experimental-websocket` is needed on Node 20 because Supabase JS initializes realtime support with a WebSocket dependency. Remove it only after verifying the tests on Node 22 or newer.

The hosted `snapgrub-dev` Supabase project is the next deployment target after local validation. Link and deploy it only after creating the cloud project; keep production as a separate Supabase project.

For Flutter:

```sh
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug --flavor dev --dart-define=SNAPGRUB_ENV=dev
```

If the Android build reports that no Java Runtime is available, install a JDK and rerun the APK build before treating mobile acceptance as complete.
