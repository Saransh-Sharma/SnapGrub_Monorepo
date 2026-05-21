# Backend

The backend lives in `services/backend/supabase`.

## Setup

Install the local backend toolchain:

```sh
brew install supabase/tap/supabase deno
```

Docker Desktop must be running before starting Supabase. From the repo root, use the project script so the local stack starts and the database is reset from checked-in migrations:

```sh
npm ci
bash scripts/run-local-supabase.sh
cd services/backend/supabase
supabase status -o env > /tmp/snapgrub-supabase.env
```

Local service URLs:

- API: `http://127.0.0.1:54321`
- DB: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`
- Studio: `http://127.0.0.1:54323`
- Inbucket/Mailpit: `http://127.0.0.1:54324`

Supabase local keys are development-only. Service-role keys, AI provider keys, and other private secrets must never be added to mobile config or committed; Flutter receives only `SUPABASE_URL` and the public anon/publishable key.

## Checks

```sh
npm run backend:lint:migrations
npm run backend:typecheck
set -a
. /tmp/snapgrub-supabase.env
set +a
export NODE_OPTIONS=--experimental-websocket
npm run backend:test:phase1
npm run backend:test:phase4
npm run backend:test:rls
npm run backend:test:meal-core
npm run backend:test:phase5
npm run backend:test:phase6
npm run backend:test:phase7
```

`NODE_OPTIONS=--experimental-websocket` is required for the current Node 20 local test runtime because Supabase JS needs a WebSocket constructor. Recheck this when the repo moves to Node 22 or newer.

More detail:

- [edge-functions.md](edge-functions.md)
- [meal-core-rpcs.md](meal-core-rpcs.md)
- [settings-patch-rpc.md](settings-patch-rpc.md)
- [testing.md](testing.md)
