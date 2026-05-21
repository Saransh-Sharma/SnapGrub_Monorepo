# Quality

Quality docs define automated gates, manual smoke tests, and release readiness.

## Current Gates

- Contracts: OpenAPI validation and generated client freshness.
- Backend: migration lint, Deno typecheck, Supabase reset, Phase 1/4 smoke tests, RLS isolation tests, meal-core smoke tests, Phase 5/6/7 smoke tests.
- Mobile: pub get, build runner, format, analyze, tests, dev flavor build.
- Manual: auth, onboarding, offline submit, meal create/edit/delete, templates, custom foods, progress rollups, sync drain, relaunch, second-user isolation.

Start with [manual-test-plan.md](manual-test-plan.md), [phase-3-acceptance.md](phase-3-acceptance.md), [phase-4-photo-analysis-acceptance.md](phase-4-photo-analysis-acceptance.md), [phase-5-multimodal-acceptance.md](phase-5-multimodal-acceptance.md), [phase-6-sync-acceptance.md](phase-6-sync-acceptance.md), and [phase-7-insights-acceptance.md](phase-7-insights-acceptance.md). Keep [phase-0-1-gate.md](phase-0-1-gate.md) for historical/foundation readiness.
