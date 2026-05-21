# API Errors

The canonical error envelope is defined in `packages/api-contracts/openapi.yaml` and generated into client packages.

Current error guidance is also available in [../api/error-codes.md](../api/error-codes.md).

## Rules

- Return structured `ErrorEnvelope` responses from Edge Functions.
- Include `request_id` for debugging.
- Mark retryability honestly so mobile outbox behavior can distinguish validation/auth failures from transient failures.
- Treat `INVALID_INPUT`, `AUTH_REQUIRED`, and `IDEMPOTENCY_CONFLICT` as non-retryable for `settings.patch`.

When adding an error code, update OpenAPI first, regenerate clients, then update examples.
