# ADR-0004 Service Role And AI Keys Backend Only

## Status

Accepted

## Context

Mobile clients cannot safely hold privileged Supabase or AI provider credentials.

## Decision

The mobile app may include only public Supabase anon configuration. Service-role keys, AI provider keys, billing credentials, and private secrets belong only in backend/server environments.

## Consequences

AI orchestration and protected writes must go through backend APIs. Security reviews must check that mobile code, env examples, logs, and generated clients do not expose privileged secrets.
