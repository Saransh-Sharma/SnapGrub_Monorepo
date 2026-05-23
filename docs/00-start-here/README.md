# Start Here

This is the preferred entrypoint for SnapGrub engineering docs.

SnapGrub has Phase 0-7 source implemented: contract-first API package, Supabase auth/profile/settings, Flutter onboarding, Home/SnapStrip, local-first meal logging, photo analysis, barcode/OCR/text/voice draft entry, offline sync hardening, export request enqueueing, and feature-flagged weekly insights.

The current canonical implementation addendum is [../14-project-management/phase-0-7-implementation-review-2026-05-21.md](../14-project-management/phase-0-7-implementation-review-2026-05-21.md). Backend smoke checks and Flutter analyze/tests pass locally; Android APK build and device acceptance are blocked until a JDK and device/simulator matrix are available.

## First Stops

- Product scope: [../01-product/README.md](../01-product/README.md)
- App feature walkthrough: [../01-product/feature-walkthrough.md](../01-product/feature-walkthrough.md)
- System architecture: [../02-architecture/README.md](../02-architecture/README.md)
- API contracts: [../03-api-contracts/README.md](../03-api-contracts/README.md)
- Database and RLS: [../04-database/README.md](../04-database/README.md)
- Flutter setup: [../05-frontend/README.md](../05-frontend/README.md)
- Supabase setup: [../06-backend/README.md](../06-backend/README.md)
- QA gates: [../10-quality/README.md](../10-quality/README.md)
- Current phase status: [../14-project-management/phase-status.md](../14-project-management/phase-status.md)

## Current Quick Path

- API: [../03-api-contracts/endpoints.md](../03-api-contracts/endpoints.md)
- Database: [../04-database/schema.md](../04-database/schema.md)
- Frontend: [../05-frontend/architecture.md](../05-frontend/architecture.md)
- Backend: [../06-backend/meal-core-rpcs.md](../06-backend/meal-core-rpcs.md)
- QA: [../10-quality/manual-test-plan.md](../10-quality/manual-test-plan.md)
- Phase 4 QA: [../10-quality/photo-analysis-acceptance.md](../10-quality/photo-analysis-acceptance.md)
- Phase 5 QA: [../10-quality/multimodal-entry-acceptance.md](../10-quality/multimodal-entry-acceptance.md)
- Phase 6 QA: [../10-quality/offline-sync-acceptance.md](../10-quality/offline-sync-acceptance.md)
- Phase 7 QA: [../10-quality/insights-acceptance.md](../10-quality/insights-acceptance.md)
- Photo AI contract: [../07-ai-ml/future-photo-analysis-contract.md](../07-ai-ml/future-photo-analysis-contract.md)
- ADRs: [../12-decisions/README.md](../12-decisions/README.md)
- Risks: [../13-risk-register/README.md](../13-risk-register/README.md)
- Release notes: [../14-project-management/release-notes.md](../14-project-management/release-notes.md)

## Local Baseline

Install the required toolchain before relying on CI parity:

- Node 20
- Flutter stable, including Dart
- JDK for Android Gradle builds
- Supabase CLI
- Deno

Run the current checks from [../10-quality/README.md](../10-quality/README.md) before relying on local parity.

## Documentation Rules

Use the numbered docs as the canonical navigation layer. Existing docs under `docs/api`, `docs/architecture`, `docs/qa`, and `docs/runbooks` remain for compatibility and are linked where useful. Do not duplicate long content; update the canonical page and link related references.
