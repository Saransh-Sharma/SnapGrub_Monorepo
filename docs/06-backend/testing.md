# Backend Testing

## Required Checks

```sh
npm run backend:lint:migrations
npm run backend:typecheck
bash scripts/run-local-supabase.sh
cd services/backend/supabase
supabase status -o env > /tmp/snapgrub-supabase.env
cd ../../..
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

`NODE_OPTIONS=--experimental-websocket` is required for Node 20 local integration tests because Supabase JS expects WebSocket support. Revalidate this flag when using Node 22 or newer.

## What These Cover

- Migration filename/order lint.
- Deno typechecking for Edge Functions.
- Clean local database reset.
- Phase 1 bootstrap/settings/events smoke coverage.
- Phase 4 mock photo-analysis smoke coverage, including private storage upload, `analysis-photo-create`, `analysis-get`, model invocation persistence, and storage path ownership rejection.
- Cross-user RLS isolation.
- Global feature flag readability and override secrecy.
- Meal create/update/delete RPC behavior, rollup refresh, and correction-event return.
- Phase 5 multimodal server write paths.
- Phase 6 sync readiness and idempotency smoke coverage.
- Phase 7 insights/defaults smoke coverage.

Add tests when adding tables, policies, or server-side write paths.

## Required Environment

Load values from `supabase status -o env` before running integration tests:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` for RLS isolation.
- `SUPABASE_SERVICE_ROLE_KEY` for RLS setup and meal-core RPC smoke.

These values are local-only or server-side test values. Do not commit them, and do not use service-role values in Flutter.
