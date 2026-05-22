# Supabase Tests

Backend test coverage is grouped by feature and scope, including SQL smoke tests, RLS isolation, meal-core RPC checks, multimodal smoke checks, and sync-readiness checks.

Run locally after installing the Supabase CLI:

```sh
supabase start
supabase db reset
npm run backend:test:rls
npm run backend:test:meal-core
npm run backend:test:auth-profile
npm run backend:test:photo-analysis
npm run backend:test:multimodal
npm run backend:test:offline-sync
npm run backend:test:insights
npm run backend:test:privacy
```
