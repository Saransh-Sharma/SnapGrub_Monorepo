# ADR-0012: Model-first meal parsing with catalog grounding

- Status: accepted
- Date: 2026-10-01

## Context

Typed, spoken and conversational meals were parsed by a keyword dictionary of
about 25 foods. Unknown foods were dropped without notice, and a model was
consulted only when no keyword matched. Photo analysis used a model, but its
nutrition numbers were never checked against the catalog. Neither path matched
the product promise of a trustworthy ledger.

## Decision

1. Text, voice, conversation and "fix with a sentence" call the configured
   model first, through one shared caller (`_shared/llm.ts`) with an enforced
   reply schema, the API key in a header, and one retry on unparseable output.
2. The rule parser remains for `AI_PROVIDER=mock` and as an outage fallback.
   As a fallback it answers only when it understood every word; otherwise the
   request fails as retryable. A partial meal is never returned as complete.
3. Words that could not be turned into a food are returned as an
   `unmatched_words` warning instead of being dropped.
4. After any model reply, items are grounded (`_shared/catalog_grounding.ts`):
   an exact name or alias match in the user's foods or the catalog replaces the
   model's nutrition with catalog values and sets `food_ref_kind`. Items
   without a match keep the estimate and stay `manual`. A match whose energy
   differs from the estimate by more than 2.5x is not applied.
5. Corrections send the current items as `base_draft`. The model marks each
   item keep, scale, replace or new. Kept and scaled items are rebuilt from the
   original on the server so their numbers and references do not drift.
6. The conversation agent may only target a meal that is on the requested day.
   When the target is unclear it replies with a question and stages nothing.
7. Model calls are capped per user per UTC day (`AI_DAILY_CALL_LIMIT`) and
   logged with token counts and estimated cost in `model_invocations`.

## Consequences

Any food can be logged by text, and the user sees which numbers come from the
catalog and which are estimates. Grounding is only as broad as the catalog:
with the curated seed most items remain estimates until ingestion runs
(`scripts/seed-catalog.sh`). Exact matching is deliberately conservative;
fuzzy or model-assisted matching can raise coverage later but needs the eval
set (`services/backend/evals`) to show it does not introduce wrong matches.
Text and voice now cost a provider call and depend on provider availability.
