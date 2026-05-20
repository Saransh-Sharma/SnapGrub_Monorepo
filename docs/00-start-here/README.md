# Start Here

This is the preferred entrypoint for SnapGrub engineering docs.

SnapGrub is currently in Phase 0/1 stabilization: repository foundation, API contracts, Supabase auth/profile/settings, Flutter onboarding, local-first profile storage, and minimal `settings.patch` outbox sync. Phase 2 SnapStrip/camera work should not start until the Phase 0/1 gate passes.

## First Stops

- Product scope: [../01-product/README.md](../01-product/README.md)
- System architecture: [../02-architecture/README.md](../02-architecture/README.md)
- API contracts: [../03-api-contracts/README.md](../03-api-contracts/README.md)
- Database and RLS: [../04-database/README.md](../04-database/README.md)
- Flutter setup: [../05-frontend/README.md](../05-frontend/README.md)
- Supabase setup: [../06-backend/README.md](../06-backend/README.md)
- QA gates: [../10-quality/README.md](../10-quality/README.md)
- Current phase status: [../14-project-management/phase-status.md](../14-project-management/phase-status.md)

## Local Baseline

Install the required toolchain before relying on CI parity:

- Node 20
- Flutter stable, including Dart
- Supabase CLI
- Deno

Run the Phase 0/1 gate from [../10-quality/phase-0-1-gate.md](../10-quality/phase-0-1-gate.md) before starting Phase 2.

## Documentation Rules

Use the numbered docs as the navigation layer. Existing docs under `docs/api`, `docs/architecture`, `docs/qa`, and `docs/runbooks` remain for compatibility and are linked where useful. Do not duplicate long content; update the canonical page and link related references.
