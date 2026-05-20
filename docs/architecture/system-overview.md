# SnapGrub System Overview

SnapGrub is built as a contract-first monorepo.

- Flutter mobile owns the local-first user experience.
- Supabase owns auth, Postgres, RLS, private storage, and Edge Functions.
- `packages/api-contracts/openapi.yaml` is the source of truth for app/backend integration.
- The mobile app only receives public Supabase anon configuration.
- Server-side functions handle protected writes and future AI orchestration.

Phase 0-1 covers repository foundation, contracts, auth bootstrap, onboarding, profile, goals, local cache, and minimal outbox behavior for settings sync.
