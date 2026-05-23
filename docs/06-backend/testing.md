# Backend Testing

## Required Checks

```sh
npm run check:contracts
npm run backend:lint:migrations
npm run backend:typecheck
npm run backend:test:e2e:api:local
npm run backend:test:auth-profile
npm run backend:test:photo-analysis
npm run backend:test:rls
npm run backend:test:meal-core
npm run backend:test:multimodal
npm run backend:test:offline-sync
npm run backend:test:insights
npm run backend:test:privacy
npm run backend:test:remediation
```

`NODE_OPTIONS=--experimental-websocket` is required for Node 20 local integration tests because Supabase JS expects WebSocket support. Revalidate this flag when using Node 22 or newer.

## Automated Layers

- Migration filename/order lint.
- Deno typechecking for Edge Functions.
- Backend API E2E product-flow coverage through the public Edge Function surface.
- Focused smoke and security scripts for narrower feature diagnostics.

Add tests when adding tables, policies, or server-side write paths.

## Backend API E2E Suite

`npm run backend:test:e2e:api` runs the Node `node:test` suite against an already-running Supabase environment. It is the broadest backend automated gate in the repository. The suite is backend-only and API-focused: it drives real Edge Function requests, validates public response shapes against OpenAPI where applicable, and verifies state using service-role reads only when necessary to confirm backend behavior.

`npm run backend:test:e2e:api:local` is the standard local entrypoint. It wraps the raw suite with local Supabase setup and safety checks so engineers can run one command from a clean local state.

The suite is intentionally broad:

- It uses real local Supabase Auth for signed-in users.
- It uses real private Storage uploads and downloads.
- It uses the checked-in migrations and the local database reset path.
- It exercises Edge Functions through HTTP rather than bypassing them with direct SQL or RPC calls.
- It covers authenticated user paths, idempotent mutation replay, and service-role-only operations.

`backend:test:e2e:api:local` is destructive to local state because it runs `supabase db reset`. Treat it as a clean-room gate, not as a command to run against a local database you want to preserve.

Remote execution is intentionally guarded. The helper layer expects localhost by default because the suite creates users, uploads storage objects, generates exports, runs cleanup, and deletes accounts. Running it against a hosted environment requires an explicit override and should only be done for a deliberately isolated environment.

### Local Wrapper Behavior

`npm run backend:test:e2e:api:local` performs these steps:

1. Runs `bash scripts/run-local-supabase.sh`.
2. Resets the local database with `supabase db reset`.
3. Captures local Supabase env output from `supabase status -o env`.
4. Exports the env values needed by Node tests:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
5. Sets `NODE_OPTIONS=--experimental-websocket` for Node 20 compatibility.
6. Waits for local Auth readiness before invoking the Node suite.
7. Restarts the local Kong container if the auth proxy is stale after reset, then retries readiness.
8. Runs `npm run backend:test:e2e:api`.

### Coverage Map

The API E2E suite covers the backend surface by behavior, not by table:

- Auth, profile, settings, and events:
  Bootstrap profile/device state, privacy toggles, goals, body measurements, analytics ingest, install takeover rejection, idempotency replay, and idempotency conflicts.
- Meals and offline replay endpoints:
  Meal create/list/get/update/delete, day-filter behavior, correction events, rollups, stale revision rejection, custom foods, meal templates, and body measurement write paths.
- Multimodal and catalog APIs:
  Food search, barcode resolution, cached misses, text analysis, label analysis, voice analysis, and persisted analysis/model invocation state.
- Photo analysis:
  User-owned storage upload, `analysis-photo-create`, `analysis-get`, photo-meal save flow, storage ownership rejection, and forged reference rejection.
- Insights, privacy, and service-role operations:
  Weekly insight generation, exports, signed URL polling, cleanup endpoints, service-role rejection, storage cleanup, and destructive account deletion flow.

### Backend Defects This Suite Is Meant To Catch

The suite is expected to catch defects in the public backend contract and the server-side behavior behind it. Important examples already covered:

- Idempotency replay vs idempotency conflict behavior.
- Cross-user access rejection for owned resources.
- Storage ownership enforcement for private media paths.
- Service-role-only endpoint rejection for non-service-role callers.
- Revision conflict handling for stale meal writes.
- Export artifact generation, polling, expiry, and cleanup behavior.

## Focused Smokes And Security Checks

The API E2E suite does not replace the existing narrower checks. Keep them because they are faster to target and better at isolating regressions after a broad failure.

- `npm run backend:test:auth-profile`:
  Auth/profile/settings/events smoke coverage.
- `npm run backend:test:photo-analysis`:
  Mock photo-analysis smoke coverage, including private storage upload, `analysis-photo-create`, `analysis-get`, model invocation persistence, and storage path ownership rejection.
- `npm run backend:test:rls`:
  Cross-user RLS isolation, readable global flags, and restricted override/internal table access.
- `npm run backend:test:meal-core`:
  Meal create/update/delete RPC behavior, rollup refresh, correction events, and photo-reference validation.
- `npm run backend:test:multimodal`:
  Multimodal server write paths and seed assumptions for catalog/barcode support.
- `npm run backend:test:offline-sync`:
  Offline sync readiness and idempotency support primitives.
- `npm run backend:test:insights`:
  Insights/defaults smoke coverage.
- `npm run backend:test:privacy`:
  Privacy/export/delete smoke coverage, including export artifact generation, signed URL polling, storage download, account deletion cascade, and cleanup endpoint counts.
- `npm run backend:test:remediation` and `npm run backend:test:remediation-unit`:
  Targeted regressions for hardened behavior such as install takeover, invalid input idempotency, and service-role verification.

### Relationship To Existing Smokes

Use the API E2E suite as the broad product-journey gate. It answers: “does the backend API surface still behave correctly end to end from a client point of view?”

Use the narrower smoke and security scripts as diagnostics and regression probes. They answer: “which subsystem failed?” and “did a focused backend guarantee regress?”

In practice:

- Run `backend:test:e2e:api:local` when changing Edge Function behavior, request/response contracts, auth/storage semantics, or user-facing backend flows.
- Run the targeted smokes when iterating on one feature area or after the broad gate fails and you need narrower signal.

## How To Read Failures

Not every failing API E2E test means the backend is wrong. Triage failures by category:

- Contract mismatch:
  The backend responded successfully but no longer matches OpenAPI. Fix the implementation or update the contract and generated clients if the API change is intentional.
- Fixture or test bug:
  The test created unrealistic state, asserted the wrong aggregate, or failed to satisfy a documented prerequisite. Fix the test first and rerun the affected file.
- Backend defect:
  The backend returned the wrong status, wrong error envelope, wrong ownership behavior, wrong idempotency semantics, wrong cleanup result, or an unexpected 5xx. Fix the backend, then rerun the targeted file and the full local gate.

Recommended rerun flow:

1. Rerun the single failing API E2E file if the failure looks local to one suite.
2. Rerun the relevant narrow smoke/security script if you want a smaller repro.
3. Rerun `npm run backend:test:e2e:api:local` after the fix so the clean-reset path is revalidated.

## Required Environment

`npm run backend:test:e2e:api:local` starts and resets local Supabase, loads values from `supabase status -o env`, sets `NODE_OPTIONS=--experimental-websocket`, and runs the API E2E suite.

Load values from `supabase status -o env` before running individual integration tests:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` for RLS isolation.
- `SUPABASE_SERVICE_ROLE_KEY` for RLS setup and meal-core RPC smoke.

These values are local-only or server-side test values. Do not commit them, and do not use service-role values in Flutter.

## Maintenance

When adding a new Edge Function, changing a public API contract, or changing a backend behavior that affects ownership, idempotency, cleanup, or service-role authorization, update the API E2E coverage and this documentation together. The backend gate should continue to reflect the real contract surface rather than becoming a stale list of commands.
