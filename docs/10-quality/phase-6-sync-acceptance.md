# Phase 6 Sync Acceptance

## Automated

- `npm run backend:test:phase6`
- `flutter analyze`
- `flutter test`

## Manual

- Save, edit, and delete a meal offline; reconnect and confirm outbox drain.
- Trigger a retryable backend/network failure and confirm the command remains pending with backoff.
- Trigger or seed a conflict command and confirm Home shows sync attention.
- Open the Sync status screen from Home and verify the conflicting/pending command is visible.
- Uploading the same queued photo asset does not create duplicate upload state.
- `analytics.batch`, `body_measurement.create`, `template.*`, `custom_food.*`, and `export.create` remain idempotent when replayed.
- `exports-create` only enqueues a request; artifact generation remains deferred.
