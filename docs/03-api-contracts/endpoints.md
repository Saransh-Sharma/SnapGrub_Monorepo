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

Change endpoint shapes in `packages/api-contracts/openapi.yaml`, regenerate clients, then update this page.
