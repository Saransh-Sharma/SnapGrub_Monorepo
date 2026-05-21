# ADR-0006 Meals Edge Function As Phase 3 API Surface

## Status

Accepted

## Context

The handoff used `meal-upsert` as a responsibility name, while the implementation exposes a Supabase Edge Function named `meals` for list/detail/create/update/delete.

## Decision

Use `meals` as the deployed Phase 3 API surface and keep `meal-upsert` as documentation shorthand for the transactional write responsibility. OpenAPI paths remain `/meals` and `/meals/{meal_id}`.

## Consequences

Mobile has one meal function to call. Docs must avoid implying a separate deployed `meal-upsert` function. A future gateway can expose `/v1/meals` without changing the current function contract.
