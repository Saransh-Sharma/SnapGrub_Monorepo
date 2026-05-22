# Quality

Quality docs define automated gates, manual smoke tests, and release readiness.

## Current Gates

- Contracts: OpenAPI validation and generated client freshness.
- Backend: migration lint, Deno typecheck, Supabase reset, auth/profile, photo-analysis, RLS isolation, meal-core, multimodal, offline-sync, insights, and privacy smoke tests.
- Mobile: pub get, build runner, format, analyze, tests, dev flavor build.
- Manual: auth, onboarding, offline submit, meal create/edit/delete, templates, custom foods, progress rollups, sync drain, relaunch, second-user isolation, privacy toggles, export, delete account, clear local data, scheduled-job staging checks, and beta observability synthetic failures.

Start with [manual-test-plan.md](manual-test-plan.md), [release-checklist.md](release-checklist.md), [meal-logging-acceptance.md](meal-logging-acceptance.md), [photo-analysis-acceptance.md](photo-analysis-acceptance.md), [multimodal-entry-acceptance.md](multimodal-entry-acceptance.md), [offline-sync-acceptance.md](offline-sync-acceptance.md), [insights-acceptance.md](insights-acceptance.md), and [privacy-export-delete-acceptance.md](privacy-export-delete-acceptance.md). Keep [foundation-gate.md](foundation-gate.md) for historical/foundation readiness.
