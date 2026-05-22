# Privacy, Export, Delete

Phase 8 adds user-facing privacy controls under Settings. The implementation lives under `apps/mobile/lib/features/privacy`.

## Routes

- `/settings/privacy`: privacy hub.
- `/settings/privacy/ai-consent`: AI improvement consent toggle.
- `/settings/privacy/media-retention`: cloud media and original-photo retention toggles.
- `/settings/privacy/export`: export request and signed URL display.
- `/settings/privacy/delete-account`: destructive cloud account deletion.
- `/settings/privacy/clear-local-data`: local cache clearing only.

## User Flows

### AI Consent

- Reads the current profile from `profileControllerProvider`.
- Saves `ai_improvement_consent` through `ProfileRepository.savePrivacySettings`.
- Uses `settings-patch` remotely when online.
- Queues `settings.patch` when the failure is retryable.
- Must not imply AI improvement is mandatory for core functionality.

### Media Retention

- Saves `cloud_media_storage` and `save_original_photos` through the same settings path.
- The toggle state is local-first, then synced.
- Backend cleanup of expired retained assets is owned by `media-retention-cleanup`.

### Export Data

- User chooses `nutrition_json` or `journal_csv`.
- Mobile calls `exports-create` with a fresh `client_request_id`.
- The response displays export status, type, expiry, and signed URL.
- The signed URL is selectable/copyable because opening/downloading behavior differs by platform and release channel.
- If the export fails, show the returned error and allow retry with a new request ID.

### Delete Account

- User must type `DELETE`.
- Mobile calls `account-delete`.
- On success, mobile clears local Drift data, signs out, and routes to Auth.
- This flow must be online; do not enqueue account deletion offline.
- This operation deletes cloud account data and storage through the backend service-role path.

### Clear Local Data

- Clears local Drift tables for this device.
- Signs out locally.
- Does not call cloud deletion APIs.
- Must be described separately from account deletion in QA and release notes.

## Failure Rules

- Settings toggles can queue as `settings.patch`.
- Export creation may queue as `export.create`, but no artifact exists until the command drains online.
- Account deletion failure must leave the user signed in and local data intact.
- Clear-local failure should keep the user on the same screen and allow retry.
- Signed export URLs expire; polling `GET /exports-create/{export_request_id}` refreshes a completed export's URL.

## Manual Acceptance

- Toggle AI consent online and offline; confirm profile sync state.
- Toggle media retention online and offline; confirm state persists after relaunch.
- Create JSON export with no meals.
- Create CSV export with meals and item rows.
- Copy a signed export URL and confirm it expires according to backend metadata.
- Delete a test account and confirm relaunch lands on Auth.
- Clear local data and confirm cloud account still exists when signing in again.
