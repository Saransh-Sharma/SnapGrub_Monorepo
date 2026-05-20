# Frontend Offline Outbox

The mobile outbox currently supports only `settings.patch`.

## Behavior

- `saveOnboarding` validates draft data before local write.
- Local profile/goal data is stored with `pending` sync status before remote sync.
- Retryable remote failures enqueue `settings.patch` with `client_request_id`.
- Bootstrap and manual refresh drain pending commands for the signed-in user.
- Successful drain marks commands `synced` and caches the server response.
- Validation/auth/idempotency conflicts are not requeued.

## Safe Change Rules

- Keep commands user-scoped.
- Keep replay idempotent with `client_request_id`.
- Do not add meal/photo outbox commands until their server contracts exist.
- Update backend idempotency docs when replay behavior changes.
