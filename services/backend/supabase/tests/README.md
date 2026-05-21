# Supabase Tests

Phase 0-6 test coverage starts with SQL smoke tests, RLS isolation, meal-core RPC checks, multimodal smoke checks, and sync-readiness checks.

Run locally after installing the Supabase CLI:

```sh
supabase start
supabase db reset
npm run backend:test:rls
npm run backend:test:meal-core
npm run backend:test:phase5
npm run backend:test:phase6
npm run backend:test:phase7
```
