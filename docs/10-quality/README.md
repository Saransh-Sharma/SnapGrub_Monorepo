# Quality

Quality docs define automated gates, manual smoke tests, and release readiness.

## Current Gates

- Contracts: OpenAPI validation and generated client freshness.
- Backend: migration lint, Deno typecheck, Supabase reset, RLS isolation tests.
- Mobile: pub get, build runner, format, analyze, tests, dev flavor build.
- Manual: auth, onboarding, offline submit, sync drain, relaunch, second-user isolation.

Start with [phase-0-1-gate.md](phase-0-1-gate.md).
