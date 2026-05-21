# Supabase Tests

Phase 0-3 test coverage starts with SQL smoke tests, RLS isolation, and meal-core RPC smoke checks.

Run locally after installing the Supabase CLI:

```sh
supabase start
supabase db reset
npm run backend:test:rls
npm run backend:test:meal-core
npm run backend:test:phase5
```
