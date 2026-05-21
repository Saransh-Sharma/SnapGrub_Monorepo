# ADR-0001 Contract-First API

## Status

Accepted

## Context

Flutter and backend work need a stable integration boundary so teams can build in parallel without hand-maintained DTO drift.

## Decision

`packages/api-contracts/openapi.yaml` is the source of truth for frontend/backend API shapes. Dart and TypeScript clients are generated and committed. CI fails when OpenAPI is invalid or generated output is stale.

## Consequences

API changes start in OpenAPI. Mobile and backend code should import generated contract types where practical. Examples support testing and review but do not replace schemas.
