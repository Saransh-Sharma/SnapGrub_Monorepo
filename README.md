# SnapGrub Monorepo

SnapGrub is a camera-first calorie tracking product. This repository is the monorepo for the mobile app, backend services, and early product planning materials.

## Start Here

Use [docs/00-start-here/README.md](docs/00-start-here/README.md) as the canonical developer documentation entrypoint. The numbered docs under `docs/00-start-here` through `docs/14-project-management` are the preferred navigation layer for architecture, API contracts, database, frontend, backend, QA, operations, decisions, risks, and phase status.

Existing docs under `docs/api`, `docs/architecture`, `docs/qa`, and `docs/runbooks` remain available for compatibility and are linked from the numbered docs where useful.

## Structure

- `apps/mobile` - Flutter mobile app source for iOS and Android.
- `services/backend/supabase` - Supabase database migrations, RLS policies, storage setup, and Edge Functions.
- `packages/api-contracts` - OpenAPI and generated client/model packages. This is the integration boundary between frontend and backend.
- `packages/design-tokens` - Shared mobile design token values.
- `packages/shared-domain` - Shared domain notes and constants for nutrition, confidence, units, and IDs.
- `docs` - Canonical numbered developer docs plus compatibility architecture/API/QA/runbook notes.
- `scripts` - Local development and validation scripts.
- `infra` - Environment and deployment configuration notes.

## Development

Phase 0-7 source is now implemented. Backend Phase 1, Phase 4, RLS, meal-core, Phase 5, Phase 6, and Phase 7 smoke checks pass locally, and Flutter analyze/tests pass after Drift generation. The remaining acceptance blocker in this environment is Android APK build/device QA because no Java Runtime/JDK is installed.

Current status and remaining gaps are tracked in [docs/14-project-management/phase-0-7-implementation-review-2026-05-21.md](docs/14-project-management/phase-0-7-implementation-review-2026-05-21.md).

1. Copy `.env.example` files and fill local values.
2. Validate contracts with `npm run check:contracts`.
3. Run Supabase locally with the backend setup guide in [docs/06-backend/README.md](docs/06-backend/README.md).
4. Run the Flutter app from `apps/mobile` after installing Flutter and a JDK for Android builds.

No AI provider keys, Supabase service-role keys, or private secrets belong in mobile code.
