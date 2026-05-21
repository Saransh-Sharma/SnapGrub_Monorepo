# Runbooks

Existing runbooks remain under `docs/runbooks`:

- [../runbooks/supabase-incident.md](../runbooks/supabase-incident.md)
- [../runbooks/storage-cleanup.md](../runbooks/storage-cleanup.md)

## Phase 8 Operational Playbooks

### Export Failure

Checks:

- Inspect `export_requests.status`, `error_code`, `result_storage_path`, and `row_counts`.
- Check `exports-create` logs by request ID.
- Confirm `exports-private` bucket exists and is private.
- Confirm service-role runtime secrets are configured.
- Retry with a new `client_request_id` only after confirming the previous request is failed or expired.

Mitigation:

- For transient storage errors, rerun export from the app or staging tool.
- For malformed data, reproduce with `npm run backend:test:phase8` locally and patch export serialization.
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
- Confirm `mark_expired_exports_failed`, `expired_meal_assets`, and `mark_meal_assets_deleted` are present.
- Confirm schedule uses service-role authorization.
- Check object paths returned by cleanup helper RPCs.

Mitigation:

- Rerun cleanup with a small `limit`.
- If one object path blocks cleanup, remove it manually with service-role storage tooling and rerun.
- Keep production cleanup disabled until staging cleanup succeeds at least once after a migration or function change.

Add new operational runbooks here or link them from this index. Keep runbooks action-oriented: symptoms, checks, mitigation, rollback, and owner.
