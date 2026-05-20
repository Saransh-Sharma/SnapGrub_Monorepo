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
```

## What These Cover

- Migration filename/order lint.
- Deno typechecking for Edge Functions.
- Clean local database reset.
- Cross-user RLS isolation.
- Global feature flag readability and override secrecy.

Add tests when adding tables, policies, or server-side write paths.
