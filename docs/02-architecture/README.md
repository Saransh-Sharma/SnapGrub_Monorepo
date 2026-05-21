# Architecture

SnapGrub is a contract-first monorepo. Flutter owns the local-first user experience; Supabase owns auth, Postgres, RLS, storage, and Edge Functions. `packages/api-contracts/openapi.yaml` is the frontend/backend integration boundary.

```mermaid
flowchart LR
  Mobile["Flutter mobile app"]
  Drift["Drift local DB"]
  Outbox["Outbox commands"]
  Contracts["OpenAPI contracts\npackages/api-contracts"]
  Functions["Supabase Edge Functions\nprofile/settings/events/meals/analysis/multimodal/sync"]
  RPC["Service-role RPCs\nsettings/meals/rollups/insights"]
  Direct["RLS table reads\ntemplates/custom foods/rollups/insights"]
  Postgres["Supabase Postgres + RLS"]
  Storage["Private Supabase Storage"]
  AI["Backend-only AI provider\nmock/Gemini/OpenAI"]

  Mobile <--> Drift
  Drift <--> Outbox
  Mobile -. generated DTOs .-> Contracts
  Mobile --> Functions
  Mobile --> Direct
  Functions --> Contracts
  Functions --> RPC
  RPC --> Postgres
  Direct --> Postgres
  Functions --> Postgres
  Functions --> Storage
  Functions --> AI
```

## Current Architecture Rules

- Mobile initializes Supabase with anon config only.
- Mobile calls Edge Functions for protected settings, meal writes, photo analysis, multimodal parser requests, sync replay, and export request enqueueing.
- Mobile uses RLS-backed reads/direct access only where documented for user-owned local sync surfaces.
- Backend protects user data with RLS and service-side validation.
- API contract changes start in OpenAPI and regenerate committed clients.
- Local data must be scoped by authenticated user ID.
- AI provider calls and service-role credentials remain backend-only.

More detail:

- [Mobile architecture](mobile-architecture.md)
- [Backend architecture](backend-architecture.md)
- [Offline sync](offline-sync.md)
- [Security boundaries](security-boundaries.md)

Legacy references:

- [../architecture/system-overview.md](../architecture/system-overview.md)
- [../architecture/mobile-architecture.md](../architecture/mobile-architecture.md)
- [../architecture/backend-architecture.md](../architecture/backend-architecture.md)
