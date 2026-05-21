# Endpoints

OpenAPI remains canonical. This page explains current responsibilities so developers know where to make safe changes.

## Identity, Settings, And Analytics

### `POST /profile-bootstrap`

- Validate JWT.
- Create a missing profile row.
- Upsert device by stable install ID.
- Return profile, active goal if present, device, feature flags, server time, and request ID.
- Hide service-only feature flag override details.

### `PATCH /settings-patch`

- Validate JWT and request shape.
- Use `client_request_id` or `Idempotency-Key` for idempotency.
- Apply profile, active goal, and optional body measurement through `patch_user_settings`.
- Supports privacy toggles: `cloud_media_storage`, `save_original_photos`, and `ai_improvement_consent`.
- Return updated profile, active goal, optional measurement snapshot, server time, and request ID.

### `POST /events-ingest`

- Accept authenticated analytics event payloads.
- Apply server-side validation.
- Avoid exposing analytics reads to clients.

## Meal Ledger

### `GET /meals`

- Validate JWT.
- Return only the authenticated user's active meals.
- Support optional `day=YYYY-MM-DD` filtering using each meal's stored timezone.
- Return matching daily rollups with server time and request ID.

### `GET /meals/{meal_id}`

- Validate JWT and ownership.
- Return `404` for missing or cross-user meals.
- Include typed `correction_events` in the response.

### `POST /meals`, `PATCH /meals/{meal_id}`, `DELETE /meals/{meal_id}`

These are the public meal write endpoints exposed by the `meals` Edge Function. The handoff's `meal-upsert` name refers to this transactional write responsibility, not a separate deployed function.

- Validate JWT, ownership, request shape, and idempotency key.
- Persist `manual`, `duplicate`, and validated `photo` meals transactionally with their item set.
- Accept `source=photo` only when `analysis_job_id` and `photo_asset_id` belong to the authenticated user and the analysis job is completed.
- Append authoritative correction events.
- Refresh daily rollups using meal timezone/day semantics.
- Return typed `meal`, `daily_rollup`, and `correction_events` payloads.

## Photo And Multimodal Analysis

### `POST /analysis-photo-create`

- Validate JWT and require `storage_path` under the authenticated user's storage prefix.
- Upsert the `meal_assets` row for the uploaded original and optional thumbnail.
- Create or replay an idempotent `analysis_jobs` row using `client_request_id`.
- Fetch the private image server-side and call the configured backend AI provider.
- Validate/normalize the provider result into an editable meal draft with components, confidence, warnings, and provenance.
- Persist `analysis_revisions`, `analysis_candidates`, and `model_invocations`.
- Return `analysis_id`, `asset_id`, `status`, nullable `result`, nullable `error_code`, `retryable`, server time, and request ID.

### `GET /analysis-get/{analysis_id}`

- Validate JWT and ownership.
- Return `404` for missing or cross-user analysis IDs.
- Return the latest analysis revision result when available.
- Preserve the same response envelope as `analysis-photo-create`.

### Phase 5 parser/search endpoints

- `POST /barcode-resolve`: local cache, Open Food Facts fallback, and custom-product fallback.
- `POST /foods-search`: catalog, branded, custom, and recent-food search.
- `POST /analysis-text-create`: typed phrase to editable meal draft.
- `POST /analysis-label-create`: OCR label text to editable packaged-food draft.
- `POST /analysis-voice-create`: edited voice transcript to editable meal draft.

## Privacy, Export, Delete

### `POST /exports-create`

- Validate JWT.
- Use `client_request_id` and `Idempotency-Key` for replay.
- Rate-limit creation attempts.
- Generate `nutrition_json` or `journal_csv` artifacts server-side.
- Store artifacts in `exports-private`.
- Persist artifact metadata and row counts in `export_requests`.
- Return `202` with an `export_request` state snapshot.

Important response fields:

- `status`: `processing`, `completed`, or `failed`.
- `result_storage_bucket` and `result_storage_path`: service/storage location.
- `signed_url`: short-lived download link for completed exports.
- `signed_url_expires_at`: signed URL expiry.
- `expires_at`: artifact expiry.
- `row_counts`: exported table counts.

### `GET /exports-create/{export_request_id}`

- Validate JWT and export ownership.
- Return `404` for missing or cross-user export IDs.
- Refresh the signed URL when the owned export is completed and the current URL is absent or near expiry.

### `POST /account-delete`

- Validate JWT.
- Require body `{ "confirmation": "DELETE" }`.
- Rate-limit destructive attempts.
- Delete known user storage objects and the Supabase Auth user.
- Return an `account_deletion` audit snapshot.
- Mobile must clear local data and sign out after success.

### `POST /media-retention-cleanup`

- Service-role only.
- Removes expired export artifacts.
- Removes retained meal media whose `retention_until` is in the past.
- Marks cleaned rows as expired/deleted.
- Returns cleanup counts for dashboards and alerts.

## Scheduled Operations

### `POST /weekly-insights-generate`

- Service-role only.
- Single-user mode accepts `user_id`.
- Batch mode omits `user_id` and uses `users_due_for_weekly_insights`.
- Staging/prod scheduling must be validated before broad feature-flag rollout.

Change endpoint shapes in `packages/api-contracts/openapi.yaml`, regenerate clients, then update this page.
