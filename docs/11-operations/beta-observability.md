# Beta Observability and Release Gates

This checklist turns Phase 9 and Phase 10 into staging/prod gates. Dashboards and alerts must be validated with synthetic traffic before beta rollout.

## Metric Sources

| Area | Source | Required breakdown |
| --- | --- | --- |
| Photo analysis | `analysis_jobs`, `analysis_revisions`, `model_invocations`, Edge Function logs | provider, model, status, latency, retryable error, low-confidence rate |
| AI cost | `model_invocations.estimated_cost_usd` | provider, model, day, user cohort where allowed |
| Storage | Supabase Storage logs, `meal_assets`, `export_requests`, cleanup responses | bucket, operation, failure rate, cleaned objects |
| Export | `export_requests`, `exports-create` logs | status, type, generation latency, signed URL refresh, failure code |
| Account deletion | `account_deletion_requests`, `account-delete` logs | status, deleted storage objects, failure code |
| Sync | mobile outbox state, `api_idempotency`, Edge Function logs | command type, pending/failed/conflict, retry count |
| Product | `analytics_events`, meal tables, weekly insights | onboarding completion, meals saved/day, source mix, weekly insight impressions |
| Backend health | Edge Function logs, Supabase logs, scheduled job logs | 4xx, 5xx, request volume, missed jobs, RLS smoke status |

## Required Dashboards

- Photo analysis success rate and p50/p95 latency.
- Provider/model mix, fallback rate, low-confidence rate, and estimated daily cost.
- Storage upload failure rate, export generation failure rate, and cleanup counts.
- Sync pending/failed/conflict counts by command type.
- Edge Function 4xx/5xx by function.
- Export requests by status and type.
- Account deletion requests by status.
- Scheduled `weekly-insights-generate` and `media-retention-cleanup` run success.
- Meals saved/day and source mix.

## Required Alerts

- Photo analysis failure rate above 5% over 15 minutes.
- Photo analysis p95 above 12 seconds over 15 minutes.
- Edge Function 5xx spike above 2% over 10 minutes.
- Storage upload or export generation failures above 3% over 15 minutes.
- AI spend above the configured daily threshold.
- Sync failed/conflict rate spike above 5% over 30 minutes.
- Export or account deletion failure spike above 2 failures in 15 minutes during beta.
- Scheduled `weekly-insights-generate` or `media-retention-cleanup` misses one expected run.
- Any service-role/auth/provider secret appears in mobile logs or config.

## Staging Scheduled Jobs

Configure schedules only in staging first:

- `weekly-insights-generate`: service-role POST with no `user_id`, optional `week_start`, and a bounded `limit`.
- `media-retention-cleanup`: service-role POST with bounded `limit`.

Staging acceptance:

- Job executes on schedule.
- Logs contain request IDs.
- Dashboard shows success/failure.
- Failure alert fires when intentionally misconfigured in a controlled test.
- Production schedule is not enabled until staging has at least one successful observed run.

## Staging Synthetic Tests

1. Run mock-provider photo analysis and confirm request IDs appear in logs.
2. Run real Gemini photo analysis with a staged key.
3. Force provider failure and confirm fallback or retryable error telemetry.
4. Generate a JSON export and a CSV export.
5. Poll export status and download/copy the signed URL.
6. Expire an export row and run `media-retention-cleanup`.
7. Create a test user with storage objects and run `account-delete`.
8. Run `weekly-insights-generate` with no `user_id` to exercise batch scheduling.
9. Force an Edge Function error and confirm the 5xx alert.
10. Force an outbox conflict from a test client and confirm conflict telemetry.

## Release Candidate Blockers

- Any P0/P1 crash.
- Export or account deletion failure in staging.
- Service-role, provider, or Supabase secret exposure in mobile config.
- Missing camera/microphone/privacy platform strings.
- Staging p95 photo analysis above 12 seconds.
- Beta crash-free sessions below 99%.
- Missed scheduled insight or cleanup job.
- No dashboard for export/delete failures.
- No tested rollback path for backend function deployment.
