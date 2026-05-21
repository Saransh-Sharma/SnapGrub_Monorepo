# ADR-0003 Local-First Profile Settings Outbox

## Status

Accepted

## Context

Onboarding must not trap users when the network is unavailable, but Phase 1 should avoid building a broad sync system before meal/photo workflows exist.

## Decision

Save profile, active goal, and optional body measurement locally before remote sync. Support a minimal outbox with only `settings.patch` commands. Drain pending settings commands after bootstrap or manual refresh.

## Consequences

The outbox is intentionally narrow. New command types require documented contracts, idempotency, failure behavior, and tests. Local reads must be scoped by signed-in user ID.
