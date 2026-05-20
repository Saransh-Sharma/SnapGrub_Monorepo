# Phase Scope

## Phase 0/1 Current Scope

Phase 0/1 covers:

- Monorepo documentation, contracts, and CI gates.
- Flutter app foundation with Riverpod, GoRouter, Drift, Supabase Flutter, and generated API models.
- Supabase auth, profiles, nutrition goals, devices, feature flags, analytics events, body measurements, RLS, and storage buckets.
- Edge Functions for `profile-bootstrap`, `settings-patch`, and `events-ingest`.
- Local-first profile/settings flow with a minimal `settings.patch` outbox.
- Backend RLS isolation tests and API contract freshness checks.

## Explicitly Deferred

Deferred until later phases:

- Camera capture and SnapStrip behavior.
- Meal, AI, and food catalog production schema beyond guardrail documentation.
- Barcode scanning.
- Nutrition catalog ingestion.
- Push notification delivery.
- AI provider integration and prompt execution.

Phase 2 may begin only after [../14-project-management/phase-2-readiness.md](../14-project-management/phase-2-readiness.md) is satisfied.
