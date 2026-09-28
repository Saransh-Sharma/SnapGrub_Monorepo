# ADR-0011: Conversational persistence, proposals, and provider boundaries

- Status: accepted
- Date: 2026-07-14

## Context

The journal needs durable daily conversation, streaming agent runs, offline meal
logging, and generated private artwork without letting probabilistic model output
become an unreviewed nutrition mutation.

## Decision

1. The existing meal ledger remains the sole nutrition source of truth.
2. Daily threads, messages, runs, proposals, and visual jobs are additive remote
   records mirrored in Drift. Existing meals render as synthetic thread events.
3. Agent tools are typed reads and proposal staging only. They never receive SQL
   access and never write a meal directly.
4. Confirmation first mutates the local ledger through the established
   repository/outbox path, then acknowledges the proposal idempotently.
5. Conversation runs use ordered SSE envelopes with stable run, message, and
   request identifiers. Queued messages replay after reconnect.
6. Model keys, system prompts, nutrition context assembly, and image generation
   stay in Edge Functions. Client telemetry excludes raw chat and image content.
7. Generated assets use a private bucket, one-hour signed URLs, local cache, and
   user-prefix deletion. Gemini Flash Image is primary and GPT Image 2 is the
   configured fallback.

## Consequences

Users can inspect every proposed change and keep logging offline. Remote thread
state can be rebuilt without rewriting historical meals. Provider replacement is
server-side. The system accepts eventual consistency between proposal status,
conversation delivery, artwork, and the meal ledger; UI must display those states
honestly.

