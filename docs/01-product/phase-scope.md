# Phase Scope

## Implemented Phase Status

| Phase | Status | Implemented capability |
| --- | --- | --- |
| Phase 0 | Implemented foundation | Monorepo docs, contract package, Supabase CLI structure, base migrations, storage buckets, generated clients |
| Phase 1 | Implemented foundation | Auth, onboarding, profile, goals, settings patch RPC, feature flags, analytics ingest, local-first settings outbox |
| Phase 2 | Implemented shell | Home, SnapStrip UI states, camera shell, action analytics, per-action feature flag gates |
| Phase 3 | Implemented source-of-truth meal ledger | Manual/duplicate meals, Meal Editor, Journal, Progress, templates, custom foods, daily rollups, correction events, meal outbox |
| Phase 4 | Implemented source-level AI loop | Photo capture assets, backend-only provider orchestration, analysis jobs/revisions, confidence/provenance draft handoff |
| Phase 5 | Implemented multimodal source level | Barcode, OCR assist, text parser, voice transcript parser, catalog seeds, unified Meal Editor draft mapping |
| Phase 6 | Implemented source-level sync hardening | Idempotent mutation outbox, deterministic drain order, pull-after-push, conflict recovery surface, upload de-duplication |
| Phase 7 | Implemented source-level retention loop | Weekly insight snapshots, learned food defaults, feature flag gating, Progress insight/frequent-food widgets |

## Explicitly Deferred To Phase 4+

Deferred until later phases:

- Photo AI analysis and model provider integration.
- Barcode resolution, nutrition-label OCR assist, and voice parsing.
- Catalog ingestion beyond user-owned custom foods.
- Export creation and account deletion flows.
- Real Android/iOS platform flavor projects if they are still not committed.

Current acceptance status lives in [../14-project-management/phase-status.md](../14-project-management/phase-status.md).
