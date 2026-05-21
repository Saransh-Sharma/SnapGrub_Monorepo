# ADR-0005 Local-First Meal Logging And Outbox

## Status

Accepted

## Context

Phase 3 needs meal logging to work offline and show Journal/Progress updates immediately. Meal writes also need replay behavior, correction-event capture, and server-authoritative rollups.

## Decision

Save manual and duplicate meals locally first in Drift, enqueue `meal.create`, `meal.update`, or `meal.delete`, and sync through the `meals` Edge Function. Successful sync caches the authoritative meal, daily rollup, and correction events.

## Consequences

The app can log meals without network access. Sync conflicts must respect server revisions and idempotency. Future AI/photo/barcode/text/voice drafts should reuse the same Meal Editor and meal outbox path once their contracts exist.
