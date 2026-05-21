# ADR-0007 RLS-Backed Template And Custom-Food Sync

## Status

Accepted

## Context

Phase 3 templates and custom foods are user-owned CRUD data. Adding Edge Functions for these narrow flows would increase backend surface area before catalog/AI workflows exist.

## Decision

Sync templates and custom foods directly to Supabase tables using authenticated RLS-backed writes keyed by `user_id` and `client_id`. Keep meal writes behind the `meals` Edge Function because they require transactionality, correction events, rollups, and idempotency.

## Consequences

Template/custom-food sync remains simple and local-first. RLS tests must cover these tables. If future behavior needs cross-table transactions, validation beyond table constraints, or richer conflict handling, introduce an Edge Function and update OpenAPI/docs.
