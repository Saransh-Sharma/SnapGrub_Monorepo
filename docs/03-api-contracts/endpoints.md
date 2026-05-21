# Endpoints

OpenAPI remains canonical. This page explains current responsibilities so developers know where to make safe changes.

## `POST /profile-bootstrap`

Used after auth/session availability.

Responsibilities:

- Validate JWT.
- Create a missing profile row.
- Upsert device by stable install ID.
- Return profile, active goal if present, device, feature flags, server time, and request ID.
- Hide service-only feature flag override details.

## `PATCH /settings-patch`

Used for onboarding submit and settings/goal edits.

Responsibilities:

- Validate JWT and request shape.
- Use `client_request_id` or `Idempotency-Key` for idempotency.
- Apply profile, active goal, and optional body measurement through `patch_user_settings`.
- Return updated profile, active goal, optional measurement snapshot, server time, and request ID.

## `POST /events-ingest`

Used for append-only analytics events.

Responsibilities:

- Accept authenticated analytics event payloads.
- Apply server-side validation.
- Avoid exposing analytics reads to clients.

## `GET /meals`

Used by the local-first journal and progress surfaces to reconcile server-authoritative meal rows.

Responsibilities:

- Validate JWT.
- Return only the authenticated user's active meals.
- Support optional `day=YYYY-MM-DD` filtering using each meal's stored timezone.
- Return matching daily rollups with server time and request ID.

## `GET /meals/{meal_id}`

Used to fetch one authoritative meal, its current rollup, and its correction history.

Responsibilities:

- Validate JWT and ownership.
- Return `404` for missing or cross-user meals.
- Include typed `correction_events` in the response.

## `POST /meals`, `PATCH /meals/{meal_id}`, `DELETE /meals/{meal_id}`

These are the public meal write endpoints exposed by the `meals` Edge Function.
The handoff's `meal-upsert` name refers to this transactional write responsibility, not a separate deployed function.

Responsibilities:

- Validate JWT, ownership, request shape, and idempotency key.
- Persist `manual`, `duplicate`, and validated `photo` meals transactionally with their item set.
- Accept `source=photo` only when `analysis_job_id` and `photo_asset_id` belong to the authenticated user and the analysis job is completed.
- Append authoritative correction events.
- Refresh daily rollups using meal timezone/day semantics.
- Return typed `meal`, `daily_rollup`, and `correction_events` payloads.

## `POST /analysis-photo-create`

Used after mobile uploads a captured image to private Supabase Storage.

Responsibilities:

- Validate JWT and require `storage_path` under the authenticated user's storage prefix.
- Upsert the `meal_assets` row for the uploaded original and optional thumbnail.
- Create or replay an idempotent `analysis_jobs` row using `client_request_id`.
- Fetch the private image server-side and call the configured backend AI provider.
- Validate/normalize the provider result into an editable meal draft with components, confidence, warnings, and provenance.
- Persist `analysis_revisions`, `analysis_candidates`, and `model_invocations`.
- Return `analysis_id`, `asset_id`, `status`, nullable `result`, nullable `error_code`, `retryable`, server time, and request ID.

## `GET /analysis-get/{analysis_id}`

Used to read one authenticated user's analysis job.

Responsibilities:

- Validate JWT and ownership.
- Return `404` for missing or cross-user analysis IDs.
- Return the latest analysis revision result when available.
- Preserve the same response envelope as `analysis-photo-create`.

Change endpoint shapes in `packages/api-contracts/openapi.yaml`, regenerate clients, then update this page.
