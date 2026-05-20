# Offline Sync

Phase 1 implements the smallest local-first sync surface needed for onboarding/settings: `settings.patch`.

## How It Works

1. The app validates onboarding/settings locally.
2. It writes profile, active goal, and optional body measurement into Drift.
3. It calls `settings-patch` when remote config is available.
4. Retryable failures create one pending `settings.patch` outbox command.
5. Bootstrap or manual refresh drains pending settings commands.
6. Successful drain marks the command `synced` and updates local state from the server response.

## Current Limits

- Only `settings.patch` is supported.
- Network-restored hooks are deferred.
- Meal/photo/catalog sync is not implemented.

## Safe Change Rules

- Scope outbox commands by `userId`.
- Do not queue validation or auth failures.
- Preserve `client_request_id` for idempotency.
- Avoid adding new command types without documenting replay, conflict, and failure behavior.
