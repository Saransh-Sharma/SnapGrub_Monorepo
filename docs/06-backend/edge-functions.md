# Edge Functions

Edge Functions are the current callable backend API surface.

## Functions

- `profile-bootstrap`: authenticated app-start bootstrap, profile creation, device upsert, feature flag resolution.
- `settings-patch`: authenticated profile/goal/measurement update through an atomic RPC.
- `events-ingest`: append-only analytics ingest with optional authenticated idempotency.
- `meals`: authenticated meal list/detail/create/update/delete API. This is the deployed function for the handoff's `meal-upsert` transactional write responsibility.
- `custom-foods`: authenticated idempotent custom-food upsert/tombstone API for Phase 6 outbox replay.
- `meal-templates`: authenticated idempotent meal-template upsert/tombstone API for Phase 6 outbox replay.
- `body-measurements`: authenticated idempotent body-measurement create API.
- `exports-create`: authenticated idempotent export request enqueue API.
- `analysis-photo-create`: authenticated photo analysis API. It validates storage ownership, creates or replays analysis jobs, runs backend AI provider orchestration, persists revisions/invocations, and returns an editable meal draft.
- `analysis-get`: authenticated analysis lookup API for polling or recovering one user's analysis job/result.
- `foods-search`: authenticated Phase 5 search across catalog, branded products, custom foods, and recent meal items.
- `barcode-resolve`: authenticated Phase 5 barcode resolver with local cache and Open Food Facts fallback.
- `analysis-text-create`: authenticated Phase 5 typed meal parser.
- `analysis-label-create`: authenticated Phase 5 nutrition-label OCR text parser.
- `analysis-voice-create`: authenticated Phase 5 edited voice-transcript parser.

## Photo Analysis Provider Env

Backend-only AI/provider configuration lives in Supabase/Vercel runtime secrets, never in mobile:

```sh
AI_PROVIDER=mock
GEMINI_API_KEY=
GEMINI_PRIMARY_MODEL=gemini-3.1-flash-lite
OPENAI_API_KEY=
OPENAI_FALLBACK_MODEL=gpt-4.1-mini
AI_INPUT_PRICE_PER_1M=0.25
AI_OUTPUT_PRICE_PER_1M=1.50
```

Use `AI_PROVIDER=mock` for local development without external provider keys. Real Gemini/OpenAI runs require provider keys configured outside the repository.

## Rules

- Keep deploy names aligned with OpenAPI paths.
- Validate JWT before user-specific behavior.
- Use shared error envelopes.
- Use `Idempotency-Key` plus request-body hash for mutation replay.
- Keep service-role credentials inside backend runtime only.
- Update OpenAPI and generated clients before changing request or response shapes.
