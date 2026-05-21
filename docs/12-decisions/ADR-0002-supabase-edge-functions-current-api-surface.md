# ADR-0002 Supabase Edge Functions Current API Surface

## Status

Accepted

## Context

SnapGrub uses Supabase Edge Functions directly for the implemented Phase 0-3 API surface. Introducing a public gateway now would add deployment complexity before core logging is stable.

## Decision

Use Edge Function deploy names as current callable API paths:

- `profile-bootstrap`
- `settings-patch`
- `events-ingest`
- `meals`

Future `/v1/...` REST paths may be added behind a gateway later.

## Consequences

OpenAPI paths must match current function names. Mobile calls Supabase Functions directly. A future gateway migration must preserve request/response compatibility or provide a versioned transition.
