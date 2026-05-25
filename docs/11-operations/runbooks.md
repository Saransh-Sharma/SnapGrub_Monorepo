# Runbooks

Existing runbooks remain under `docs/runbooks`:

- [../runbooks/supabase-incident.md](../runbooks/supabase-incident.md)
- [../runbooks/storage-cleanup.md](../runbooks/storage-cleanup.md)

## Privacy Operational Playbooks

### Export Failure

Checks:

- Inspect `export_requests.status`, `error_code`, `result_storage_path`, and `row_counts`.
- Check `exports-create` logs by request ID.
- Confirm `exports-private` bucket exists and is private.
- Confirm service-role runtime secrets are configured.
- Retry with a new `client_request_id` only after confirming the previous request is failed or expired.

Mitigation:

- For transient storage errors, rerun export from the app or staging tool.
- For malformed data, reproduce with `npm run backend:test:privacy` locally and patch export serialization.
- For expired signed URLs, poll `GET /exports-create/{export_request_id}` to refresh the URL.

### Account Delete Failure

Checks:

- Inspect `account_deletion_requests.status`, `error_code`, and `error_message`.
- Confirm the user typed exact `DELETE` confirmation.
- Check `account-delete` logs by request ID.
- Inspect storage objects under the user prefix in meal and export buckets.
- Confirm Supabase Auth admin delete is available to the service-role runtime.

Mitigation:

- If storage deletion failed, remove remaining user-prefix objects with service-role tooling, then retry account deletion if the auth user still exists.
- If auth deletion succeeded but audit update failed, verify cascade removed user-owned rows and update the audit row manually only with incident approval.
- Never ask the mobile client to use service-role credentials.

### Cleanup Job Failure

Checks:

- Inspect `media-retention-cleanup` logs by request ID.
- Confirm `expired_export_artifacts`, `mark_exports_expired`, `expired_meal_assets`, and `mark_meal_assets_deleted` are present.
- Confirm schedule uses service-role authorization.
- Check object paths returned by cleanup helper RPCs.

Mitigation:

- Rerun cleanup with a small `limit`.
- If one object path blocks cleanup, remove it manually with service-role storage tooling and rerun.
- Keep production cleanup disabled until staging cleanup succeeds at least once after a migration or function change.

## Backend Deploy Rollback

Checks:

- Confirm the failing deploy by Edge Function name, migration version, and request IDs.
- Inspect `job_runs` for scheduled job failures and `export_requests` / `account_deletion_requests` for user-visible privacy failures.
- Verify whether the issue is code-only, migration-only, or a contract mismatch.

Rollback:

- For Edge Function regressions, redeploy the previous known-good function bundle for only the affected functions first.
- For migration regressions, do not hand-edit production schema ad hoc; prepare a forward rollback migration that restores policies, constraints, grants, or functions explicitly.
- Pause production schedules for `weekly-insights-generate` and `media-retention-cleanup` if job failures continue after one retry.
- Keep service-role and provider keys server-side during rollback; never move privileged work to mobile as a workaround.

Post-rollback validation:

- Run the affected smoke test locally and in staging.
- Confirm dashboards show recovered 5xx rate, scheduled job success, and no new export/delete failures.
- Record the rollback migration/function version and request IDs in the incident notes.

Add new operational runbooks here or link them from this index. Keep runbooks action-oriented: symptoms, checks, mitigation, rollback, and owner.
