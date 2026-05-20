# Settings Patch RPC

`settings-patch` applies profile, active goal, and optional body measurement updates through `public.patch_user_settings`.

## Why It Exists

The RPC keeps multi-table settings updates atomic and centralizes server-side validation.

## Behavior

- Validates `unit_system`, `goal_type`, macro ranges, measurement ranges, and cuisine preference shape.
- Upserts the profile row for the authenticated user.
- Inserts or updates the active nutrition goal.
- Inserts an optional body measurement.
- Returns a profile/goal/measurement snapshot.
- Uses `api_idempotency` to replay the same `client_request_id` safely.

## Safe Change Rules

- Update OpenAPI before changing request/response fields.
- Keep one-active-goal enforcement server-side.
- Add tests for invalid updates that must not partially write.
- Treat same idempotency key with different body as a conflict.
