# Error Codes

Phase 0-1 uses the shared `ErrorEnvelope`.

- `AUTH_REQUIRED`: user must re-authenticate.
- `INVALID_INPUT`: request payload failed validation.
- `NOT_FOUND`: requested resource does not exist or is inaccessible.
- `CONFLICT`: request conflicts with current server state.
- `UNKNOWN`: unexpected server error.
