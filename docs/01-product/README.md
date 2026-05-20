# Product

SnapGrub MVP is a premium calorie tracking and weight-loss app with Flutter mobile clients and Supabase/Vercel-backed orchestration. The current implementation focus is Phase 0/1 foundation, auth, onboarding, profile, goals, local cache, and settings sync.

This folder captures product boundaries that affect engineering. It does not replace the large handoff documents; those are linked in [reference.md](reference.md).

## Current MVP Boundaries

- Build mobile-first auth, onboarding, profile, goals, and local-first persistence.
- Keep AI meal analysis as an editable draft in later phases, not source of truth.
- Keep confidence, provenance, and correction events as required future data concepts.
- Do not ship backend secrets, AI provider keys, or service-role credentials in mobile.
- Do not start SnapStrip/camera work until Phase 0/1 readiness passes.

Related docs:

- [Phase scope](phase-scope.md)
- [Project phase status](../14-project-management/phase-status.md)
- [Phase 2 readiness](../14-project-management/phase-2-readiness.md)
