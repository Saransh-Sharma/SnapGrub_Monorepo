# Privacy Export Delete Acceptance

Privacy export/delete is accepted only when backend smoke, mobile manual acceptance, and staging operations gates all pass.

## Backend Automated Gate

Run after `supabase db reset` with local Supabase env values loaded:

```sh
export NODE_OPTIONS=--experimental-websocket
npm run backend:test:privacy
```

The smoke verifies:

- JSON export artifact generation.
- Export row completion metadata.
- Signed export URL presence.
- Export polling by owned ID.
- Artifact contents in `exports-private`.
- Account deletion completion.
- Profile row removal after auth-user deletion cascade.
- Cleanup endpoint callable response shape.

## Mobile Manual Gate

Run on at least one iOS simulator/device and one Android emulator/device:

- Open Settings and verify the Privacy entry is visible.
- Toggle AI improvement consent online; relaunch and confirm state persists.
- Toggle AI improvement consent offline; reconnect and confirm sync.
- Toggle cloud media storage and original-photo retention online/offline.
- Create a JSON export with no meals.
- Create a CSV export after saving at least one meal with at least one item.
- Copy signed export URL and confirm it is present only after completed export.
- Delete account using the exact `DELETE` confirmation.
- Relaunch after deletion and confirm Auth is shown.
- Clear local data on a different test account and confirm cloud data is not deleted after signing in again.

## Backend Manual/Staging Gate

- Deploy privacy migrations and functions to staging.
- Configure `media-retention-cleanup` scheduled invocation.
- Configure `weekly-insights-generate` scheduled invocation in batch mode.
- Generate exports for users with no meals, manual meals, photo meals, custom foods, templates, correction events, and weekly insights.
- Expire an export row and confirm cleanup removes the artifact.
- Create a retained media asset with expired `retention_until` and confirm cleanup removes original/thumbnail objects.
- Delete a staging test user with meal assets and exports; confirm storage objects are removed.

## Regression Checks

- User A cannot poll User B export ID.
- Authenticated users cannot upload arbitrary export artifacts directly as part of normal app flow.
- `account-delete` without `confirmation: "DELETE"` fails and does not delete data.
- `exports-create` idempotency replay returns the same response for the same key/body.
- Reusing the same idempotency key with a different export body fails.
- Rate limits produce retryable `429`/`CONFLICT` behavior.
- Service-role cleanup endpoints reject non-service-role callers.

## Not Accepted Until

- Flutter analyze/test/build pass in an environment with Flutter/Dart on `PATH`.
- iOS and Android privacy/export/delete manual QA pass.
- Staging schedules are observed successfully.
- Staging dashboards/alerts include export/delete/cleanup failures.
