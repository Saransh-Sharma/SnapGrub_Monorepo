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
npm run backend:test:auth-profile
npm run backend:test:photo-analysis
npm run backend:test:rls
npm run backend:test:meal-core
npm run backend:test:multimodal
npm run backend:test:offline-sync
npm run backend:test:insights
npm run backend:test:privacy
```

`NODE_OPTIONS=--experimental-websocket` is required for Node 20 local integration tests because Supabase JS expects WebSocket support. Revalidate this flag when using Node 22 or newer.

## What These Cover

- Migration filename/order lint.
- Deno typechecking for Edge Functions.
- Clean local database reset.
- Auth/profile/settings/events smoke coverage.
- Mock photo-analysis smoke coverage, including private storage upload, `analysis-photo-create`, `analysis-get`, model invocation persistence, and storage path ownership rejection.
- Cross-user RLS isolation.
- Global feature flag readability and override secrecy.
- Meal create/update/delete RPC behavior, rollup refresh, and correction-event return.
- Multimodal server write paths.
- Offline sync readiness and idempotency smoke coverage.
- Insights/defaults smoke coverage.
- Privacy/export/delete smoke coverage, including export artifact generation, signed URL polling, storage download, account deletion cascade, and cleanup endpoint counts.

Add tests when adding tables, policies, or server-side write paths.

## Required Environment

Load values from `supabase status -o env` before running integration tests:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` for RLS isolation.
- `SUPABASE_SERVICE_ROLE_KEY` for RLS setup and meal-core RPC smoke.

These values are local-only or server-side test values. Do not commit them, and do not use service-role values in Flutter.
