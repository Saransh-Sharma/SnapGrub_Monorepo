# Product

SnapGrub MVP is a premium calorie tracking and weight-loss app with Flutter mobile clients and Supabase-backed orchestration. The current source implementation covers Phase 0-8: auth/onboarding/profile, SnapStrip, local-first meal logging, photo analysis, barcode/OCR/text/voice draft entry, offline sync hardening, feature-flagged weekly insights, and privacy/export/delete.

This folder captures product boundaries that affect engineering. It does not replace the large handoff documents; those are linked in [reference.md](reference.md).

## Current MVP Boundaries

- Build mobile-first auth, onboarding, profile, goals, and local-first persistence.
- Keep Home/SnapStrip camera-first while respecting permission and app lifecycle state.
- Treat the Meal Editor as the source-of-truth confirmation surface for manual, duplicate, photo, barcode, OCR, text, and voice drafts.
- Preserve confidence, provenance, correction events, and user edits so AI output remains draft data until confirmed.
- Keep offline saves visible immediately and replay mutations through the outbox.
- Keep weekly insights behind `weekly_insights.enabled` until staging/manual acceptance is complete.
- Provide user-accessible privacy controls for AI improvement consent, media retention, data export, account deletion, and local cache clearing.
- Generate private user export artifacts for MVP in JSON or CSV, with short-lived signed download URLs.
- Treat account deletion as destructive cloud deletion, separate from local cache clearing.
- Do not ship backend secrets, AI provider keys, or service-role credentials in mobile.

## Not Yet Release-Complete

- Phase 8 source exists, but mobile device acceptance is still required.
- Phase 9 observability requires real staging dashboards, alerts, crash reporting, and synthetic tests.
- Phase 10 release requires signed iOS/Android builds, store/internal-test distribution, staging-to-prod deployment, and rollout monitoring.

Related docs:

- [Phase scope](phase-scope.md)
- [Project phase status](../14-project-management/phase-status.md)
- [Phase 0-7 implementation review](../14-project-management/phase-0-7-implementation-review-2026-05-21.md)
- [Phase 8-10 implementation review](../14-project-management/phase-8-10-implementation-review-2026-05-21.md)
- [Phase 2 readiness](../14-project-management/phase-2-readiness.md)
