# Edge Functions

Edge Functions are the current callable backend API surface. Deploy names intentionally match OpenAPI paths.

## Function Catalog

- `profile-bootstrap`: authenticated app-start bootstrap, profile creation, device upsert, feature flag resolution.
- `settings-patch`: authenticated profile/goal/measurement update through `patch_user_settings`.
- `events-ingest`: append-only analytics ingest with optional authenticated idempotency.
- `meals`: authenticated meal list/detail/create/update/delete API. This is the deployed function for the handoff's `meal-upsert` responsibility.
- `custom-foods`: authenticated idempotent custom-food upsert/tombstone API for outbox replay.
- `meal-templates`: authenticated idempotent meal-template upsert/tombstone API for outbox replay.
- `body-measurements`: authenticated idempotent body-measurement create API.
- `analysis-photo-create`: authenticated photo analysis API with storage ownership validation and backend-only model orchestration.
- `analysis-get`: authenticated analysis lookup API for polling or recovering one user's analysis job/result.
- `foods-search`: authenticated search across catalog, branded products, custom foods, and recent meal items. Catalog foods are ranked in the database by `search_canonical_foods` (exact, prefix, whole word, then similarity); the user's own foods lead on a tie.
- `barcode-resolve`: authenticated barcode resolver with local cache and Open Food Facts fallback.
- `analysis-text-create`: authenticated typed meal parser. Model-first; also applies a plain-language correction to an editor draft when `base_draft` is sent.
- `analysis-label-create`: authenticated nutrition-label OCR text parser (rule-based).
- `analysis-voice-create`: authenticated edited voice-transcript parser. Model-first.
- `agent-runs`: authenticated conversational run. Streams server-sent events and stages a meal change proposal, or replies with a question when the request is unclear. Replays by `client_request_id`.
- `agent-proposals`: authenticated acknowledgement of a proposal after the app has applied it locally.
- `meal-visuals`: authenticated meal artwork generation and lookup. Each generation is logged in `model_invocations` and capped per user per day.
- `weekly-insights-generate`: service-role insight generation for one user or a batch of due users.
- `exports-create`: authenticated idempotent export artifact creation and export status polling.
- `account-delete`: authenticated destructive account deletion with explicit confirmation.
- `media-retention-cleanup`: service-role cleanup for expired exports and retained meal media.

## Privacy Functions

### `exports-create`

`POST /exports-create` now creates an MVP export artifact synchronously after inserting an `export_requests` row. It is no longer enqueue-only.

Responsibilities:

- Validate JWT.
- Use `client_request_id` and `Idempotency-Key` for replay.
- Rate-limit export creation through `consume_api_rate_limit`.
- Support `nutrition_json` and `journal_csv`.
- Read the authenticated user's profile, goals, body measurements, meals, meal items, custom foods, templates, correction events, and weekly insights.
- Upload the artifact to `exports-private` under `{user_id}/{export_request_id}/...`.
- Store artifact bucket/path, content type, byte size, row counts, artifact expiry, signed URL, and signed URL expiry.
- Return `202` with the completed or failed `export_request` snapshot.

`GET /exports-create/{export_request_id}`:

- Validates JWT and ownership.
- Returns `404` for missing or cross-user export IDs.
- Refreshes signed URLs for owned completed exports when the current URL is missing or near expiry.

Current TTLs:

- Export artifact expiry: 7 days.
- Signed URL expiry: 1 hour.

### `account-delete`

`POST /account-delete` deletes the authenticated user's cloud account and user-owned data.

Responsibilities:

- Validate JWT.
- Require body `{ "confirmation": "DELETE" }`.
- Rate-limit destructive requests through `consume_api_rate_limit`.
- Insert an `account_deletion_requests` audit row with `processing` status.
- Delete known user-owned storage objects from `meal-originals-private`, `meal-thumbnails-private`, and `exports-private`.
- Delete analytics rows that are not covered by profile cascade semantics.
- Delete the Supabase Auth user through service-role admin API, which cascades user-owned rows where foreign keys are configured with `on delete cascade`.
- Mark the deletion request `completed` or `failed`.

Client behavior after success:

- Clear local data.
- Sign out locally.
- Route to Auth.

### `media-retention-cleanup`

`POST /media-retention-cleanup` is service-role only.

Responsibilities:

- Mark expired completed export requests as failed/expired.
- Remove expired export artifacts from `exports-private`.
- Find meal assets whose `retention_until` is in the past.
- Remove originals and thumbnails from private storage.
- Mark cleaned meal assets deleted.
- Return cleanup counts for observability.

This function is intended for staging/prod scheduling. Local smoke only verifies callable behavior; schedule success must be observed in staging.

### `weekly-insights-generate`

`POST /weekly-insights-generate` remains service-role only. It now supports two modes:

- Single-user mode: pass `user_id` and optional `week_start`.
- Batch mode: omit `user_id`, pass optional `week_start` and `limit`; the function calls `users_due_for_weekly_insights`.

Batch mode is the intended scheduled-job path after staging validation.

Generated rows keep the existing six `insight_type` values and enrich `payload` for the V1.5 mobile check-in:

- `logging_streak`: logged days, meal count, longest streak, and missing weekdays.
- `average_intake_vs_target`: average calories, target calories, calorie delta, and target band.
- `protein_target_hit_rate`: hit rate, logged-day count, and target grams.
- `most_repeated_meal`: repeated title, count, and inferred meal type.
- `highest_variance_meal_slot`: meal type, variance, and sample count.
- `next_week_suggestion`: deterministic action id, action title/body, and `based_on` context.

## Model-Backed Parsing

Text, voice, conversation and corrections share one path (see [ADR-0012](../12-decisions/adr-0012-model-first-parsing-and-catalog-grounding.md)):

1. `_shared/llm.ts` calls the configured provider with an enforced reply schema and retries once if the reply is not parseable JSON.
2. `_shared/meal_llm.ts` turns the reply into an editable draft. In a correction or a chat update, items the model marks as kept or rescaled are rebuilt from the original item.
3. `_shared/catalog_grounding.ts` replaces the estimate with catalog values for items whose name exactly matches a catalog food, an alias, or one of the user's own foods, and sets `food_ref_kind`. Items carried over from the user's meal are never re-grounded.
4. Words that could not be turned into a food come back as an `unmatched_words` warning.

The rule parser in `_shared/multimodal.ts` answers when `AI_PROVIDER=mock`, when `MEAL_TEXT_MODEL=off`, or when the provider fails and the parser understood every word. Otherwise a provider failure returns `503 PROVIDER_UNAVAILABLE`.

Limits: the existing hourly rate limits, plus `AI_DAILY_CALL_LIMIT` model calls and `AI_DAILY_IMAGE_LIMIT` generated images per user per UTC day.

## Photo Analysis Provider Env

Backend-only AI/provider configuration lives in Supabase/Vercel runtime secrets, never in mobile:

For local Supabase runs, copy `services/backend/supabase/functions/.env.example` to `services/backend/supabase/functions/.env`.

```sh
CORS_ALLOW_ORIGIN=http://localhost:3000
AI_PROVIDER=mock
GEMINI_API_KEY=
GEMINI_PRIMARY_MODEL=gemini-3.1-flash-lite
OPENAI_API_KEY=
OPENAI_FALLBACK_MODEL=gpt-4.1-mini
AI_INPUT_PRICE_PER_1M=0.25
AI_OUTPUT_PRICE_PER_1M=1.50
AGENT_MODEL=gemini-3.1-flash-lite
AI_DAILY_CALL_LIMIT=100
AI_DAILY_IMAGE_LIMIT=20
AI_IMAGE_PRICE_USD=
MEAL_TEXT_MODEL=
```

`AGENT_MODEL` is the model for text, voice and conversation. `MEAL_TEXT_MODEL=off` is the kill switch for those three paths; it takes effect on the next request and leaves photo analysis alone.

`CORS_ALLOW_ORIGIN` and `AI_PROVIDER` are required runtime settings. Use `AI_PROVIDER=mock` for local development without external provider keys. Real Gemini/OpenAI runs require provider keys configured outside the repository.

## Operational Rules

- Keep service-role credentials inside backend runtime only.
- Keep deploy names aligned with OpenAPI paths.
- Validate JWT before user-specific behavior.
- Use shared error envelopes with request IDs.
- Use `Idempotency-Key` plus request-body hash for mutation replay.
- Rate-limit expensive or destructive user paths.
- Update OpenAPI and generated clients before changing request or response shapes.
- Add smoke coverage for new user-owned tables, storage behavior, or destructive paths.
