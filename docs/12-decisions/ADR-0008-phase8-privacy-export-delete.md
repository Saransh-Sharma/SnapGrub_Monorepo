# ADR-0008 Phase 8 Privacy, Export, And Delete Architecture

## Status

Accepted

## Context

MVP requires user data export, account deletion, explicit AI improvement consent, media retention controls, and clear separation between local cache clearing and destructive cloud deletion. The previous Phase 6 `exports-create` path only created an export request row and did not generate an artifact. That was insufficient for MVP release acceptance and privacy obligations.

The implementation also needed to preserve existing architectural constraints:

- Supabase remains the system of record.
- Mobile must never receive service-role keys.
- User-owned data remains protected by RLS and private storage buckets.
- Destructive paths need explicit confirmation and auditability.
- MVP should avoid introducing a new worker platform unless necessary.

## Decision

Phase 8 implements privacy/export/delete in Supabase Edge Functions and Postgres:

- `exports-create` synchronously generates MVP-sized export artifacts for `nutrition_json` and `journal_csv`.
- Export artifacts are stored in the private `exports-private` bucket under the authenticated user's prefix.
- Export rows store artifact metadata, row counts, artifact expiry, signed URL, and signed URL expiry.
- `GET /exports-create/{export_request_id}` refreshes signed URLs only after authenticated ownership checks.
- `account-delete` is an authenticated Edge Function requiring exact `DELETE` confirmation.
- `account-delete` uses service-role privileges server-side to remove known user-owned storage and delete the Supabase Auth user.
- `account_deletion_requests` records deletion status, failures, and deleted storage object counts.
- `media-retention-cleanup` is service-role only and handles expired export artifacts and expired retained meal media.
- `weekly-insights-generate` supports batch mode so scheduled staging/prod jobs can omit `user_id`.
- `api_rate_limits` and `consume_api_rate_limit` protect export creation and account deletion from repeated expensive/destructive calls.

## Consequences

Benefits:

- MVP gets concrete export artifacts without a separate worker platform.
- Mobile keeps using public Supabase auth/session credentials only.
- Signed export URLs are short-lived and ownership-checked before refresh.
- Account deletion is auditable and keeps destructive service-role behavior out of the client.
- Existing backend smoke infrastructure can verify Phase 8 locally.

Tradeoffs:

- Synchronous export generation is acceptable for MVP data sizes but may need a background worker for large accounts.
- Account deletion depends on Supabase Auth admin deletion cascade behavior plus explicit storage cleanup.
- Cleanup and weekly insight schedules still require staging/prod operational configuration.
- Mobile must treat delete account as online-only because queueing destructive deletion offline would create unsafe ambiguity.

Follow-up obligations:

- Run Phase 8 mobile device acceptance before beta.
- Configure and observe `weekly-insights-generate` and `media-retention-cleanup` schedules in staging.
- Add dashboards/alerts for export/delete/cleanup failures.
- Revisit asynchronous export generation if export latency or size becomes a beta issue.
