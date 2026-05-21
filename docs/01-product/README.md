# Product

SnapGrub MVP is a premium calorie tracking and weight-loss app with Flutter mobile clients and Supabase-backed orchestration. The current implementation covers Phase 0-3 foundations: auth/onboarding/profile, SnapStrip shell, local-first manual meal logging, journal, progress, templates, custom foods, rollups, correction events, and sync outbox.

This folder captures product boundaries that affect engineering. It does not replace the large handoff documents; those are linked in [reference.md](reference.md).

## Current MVP Boundaries

- Build mobile-first auth, onboarding, profile, goals, and local-first persistence.
- Keep the Phase 2 SnapStrip shell visible but gate unimplemented multimodal actions behind feature flags.
- Treat Phase 3 manual/duplicate meals as the source-of-truth meal ledger.
- Preserve confidence, provenance, and correction events so Phase 4 AI output remains editable draft data.
- Do not ship backend secrets, AI provider keys, or service-role credentials in mobile.
- Defer photo AI, barcode resolve, OCR assist, voice parsing, exports, account deletion, and weekly insights to Phase 4+.

Related docs:

- [Phase scope](phase-scope.md)
- [Project phase status](../14-project-management/phase-status.md)
- [Phase 2 readiness](../14-project-management/phase-2-readiness.md)
