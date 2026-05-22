# API Errors

The canonical error envelope is defined in `packages/api-contracts/openapi.yaml` and generated into client packages.

Current error guidance is also available in [../api/error-codes.md](../api/error-codes.md).

## Rules

- Return structured `ErrorEnvelope` responses from Edge Functions.
- Include `request_id` for debugging.
- Mark retryability honestly so mobile outbox behavior can distinguish validation/auth failures from transient failures.
- Treat `INVALID_INPUT`, `AUTH_REQUIRED`, and `IDEMPOTENCY_CONFLICT` as non-retryable for `settings.patch`.
- Treat account deletion confirmation failures as non-retryable `INVALID_INPUT`.
- Treat export/account-delete rate-limit responses as retryable `CONFLICT` with HTTP `429`.
- Treat cross-user export polling as `NOT_FOUND`, not authorization leakage.
- Preserve request IDs for export, cleanup, and deletion failures because these are operationally sensitive paths.

When adding an error code, update OpenAPI first, regenerate clients, then update examples.
