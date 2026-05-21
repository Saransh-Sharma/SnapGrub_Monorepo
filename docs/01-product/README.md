# Product

SnapGrub MVP is a premium calorie tracking and weight-loss app with Flutter mobile clients and Supabase-backed orchestration. The current source implementation covers Phase 0-7: auth/onboarding/profile, SnapStrip, local-first meal logging, photo analysis, barcode/OCR/text/voice draft entry, offline sync hardening, and feature-flagged weekly insights.

This folder captures product boundaries that affect engineering. It does not replace the large handoff documents; those are linked in [reference.md](reference.md).

## Current MVP Boundaries

- Build mobile-first auth, onboarding, profile, goals, and local-first persistence.
- Keep Home/SnapStrip camera-first while respecting permission and app lifecycle state.
- Treat the Meal Editor as the source-of-truth confirmation surface for manual, duplicate, photo, barcode, OCR, text, and voice drafts.
- Preserve confidence, provenance, correction events, and user edits so AI output remains draft data until confirmed.
- Keep offline saves visible immediately and replay mutations through the outbox.
- Keep weekly insights behind `weekly_insights.enabled` until staging/manual acceptance is complete.
- Do not ship backend secrets, AI provider keys, or service-role credentials in mobile.
- Keep `exports-create` as export request enqueue only; export artifact generation and account deletion completion are deferred.

Related docs:

- [Phase scope](phase-scope.md)
- [Project phase status](../14-project-management/phase-status.md)
- [Current implementation review](../14-project-management/phase-0-7-implementation-review-2026-05-21.md)
- [Phase 2 readiness](../14-project-management/phase-2-readiness.md)
