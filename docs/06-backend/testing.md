# Backend Testing

## Required Checks

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
npm run backend:test:meal-core
```

## What These Cover

- Migration filename/order lint.
- Deno typechecking for Edge Functions.
- Clean local database reset.
- Cross-user RLS isolation.
- Global feature flag readability and override secrecy.
- Meal create/update/delete RPC behavior, rollup refresh, and correction-event return.

Add tests when adding tables, policies, or server-side write paths.

## Required Environment

Load values from `supabase status -o env` before running integration tests:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` for RLS isolation.
- `SUPABASE_SERVICE_ROLE_KEY` for RLS setup and meal-core RPC smoke.
