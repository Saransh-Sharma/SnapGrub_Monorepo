# Architecture Decisions

Use ADRs for decisions that affect architecture, security, data ownership, contracts, migrations, or rollout.

## ADR Template

```md
# ADR-0000 Title

## Status

Accepted | Proposed | Superseded

## Context

What forced the decision.

## Decision

The chosen approach.

## Consequences

Benefits, tradeoffs, and follow-up obligations.
```

Current ADRs:

- [ADR-0001-contract-first-api.md](ADR-0001-contract-first-api.md): OpenAPI and generated clients are the integration source of truth.
- [ADR-0002-supabase-edge-functions-current-api-surface.md](ADR-0002-supabase-edge-functions-current-api-surface.md): current callable API uses Supabase function paths.
- [ADR-0003-local-first-profile-settings-outbox.md](ADR-0003-local-first-profile-settings-outbox.md): settings save locally before remote sync.
- [ADR-0004-service-role-and-ai-keys-backend-only.md](ADR-0004-service-role-and-ai-keys-backend-only.md): privileged keys stay out of mobile.
- [ADR-0005-local-first-meal-logging-and-outbox.md](ADR-0005-local-first-meal-logging-and-outbox.md): Phase 3 meal writes save locally and sync through outbox.
- [ADR-0006-meals-edge-function-as-phase-3-api-surface.md](ADR-0006-meals-edge-function-as-phase-3-api-surface.md): deployed meal API is `meals`; `meal-upsert` is a responsibility name.
- [ADR-0007-rls-backed-template-and-custom-food-sync.md](ADR-0007-rls-backed-template-and-custom-food-sync.md): templates/custom foods sync through RLS-backed table writes.
