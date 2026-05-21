# Phase Scope

## Implemented Phase Status

| Phase | Status | Implemented capability |
| --- | --- | --- |
| Phase 0 | Implemented foundation | Monorepo docs, contract package, Supabase CLI structure, base migrations, storage buckets, generated clients |
| Phase 1 | Implemented foundation | Auth, onboarding, profile, goals, settings patch RPC, feature flags, analytics ingest, local-first settings outbox |
| Phase 2 | Implemented shell | Home, SnapStrip UI states, camera shell, action analytics, per-action feature flag gates |
| Phase 3 | Implemented source-of-truth meal ledger | Manual/duplicate meals, Meal Editor, Journal, Progress, templates, custom foods, daily rollups, correction events, meal outbox |

## Explicitly Deferred To Phase 4+

Deferred until later phases:

- Photo AI analysis and model provider integration.
- Barcode resolution, nutrition-label OCR assist, and voice parsing.
- Catalog ingestion beyond user-owned custom foods.
- Export creation and account deletion flows.
- Weekly insights and adaptive coaching.
- Real Android/iOS platform flavor projects if they are still not committed.

Current acceptance status lives in [../14-project-management/phase-status.md](../14-project-management/phase-status.md).
