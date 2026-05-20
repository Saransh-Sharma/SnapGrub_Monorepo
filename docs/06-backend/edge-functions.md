# Edge Functions

Edge Functions are the current callable backend API surface.

## Functions

- `profile-bootstrap`: authenticated app-start bootstrap, profile creation, device upsert, feature flag resolution.
- `settings-patch`: authenticated profile/goal/measurement update through an atomic RPC.
- `events-ingest`: authenticated append-only analytics ingest.

## Rules

- Keep deploy names aligned with OpenAPI paths.
- Validate JWT before user-specific behavior.
- Use shared error envelopes.
- Keep service-role credentials inside backend runtime only.
- Update OpenAPI and generated clients before changing request or response shapes.
