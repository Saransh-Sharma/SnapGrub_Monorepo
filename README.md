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

Phase 0-1 is scaffolded for contract-first development:

1. Copy `.env.example` files and fill local values.
2. Validate contracts with `npm run validate:openapi`.
3. Run Supabase locally from `services/backend/supabase` after installing the Supabase CLI.
4. Run the Flutter app from `apps/mobile` after installing Flutter.

No AI provider keys, Supabase service-role keys, or private secrets belong in mobile code.
