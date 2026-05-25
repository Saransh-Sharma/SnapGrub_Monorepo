# Supabase Tests

Supabase backend tests are organized by scope. Use the broad API E2E suite for product-level backend confidence, then use the narrower integration, security, or unit layers when you need faster diagnostics.

## Test Tiers

- `e2e/api`:
  End-to-end backend API coverage through real local Supabase Auth, Storage, migrations, and Edge Functions. This is the highest-signal backend gate for client-visible behavior.
- `integration/*`:
  Focused feature smokes for auth/profile, meals, photo analysis, multimodal, offline-sync, insights, privacy, and remediation behavior.
- `security/*`:
  RLS and access-isolation checks that validate user scoping and service-only data boundaries.
- `unit/*`:
  Small targeted tests for hardened backend helpers and edge conditions that do not need full API orchestration.

## Which Command Should I Run?

- Broad backend confidence:
  `npm run backend:test:e2e:api:local`
- Fast targeted feature validation:
  Run the relevant smoke such as `npm run backend:test:meal-core`, `npm run backend:test:photo-analysis`, or `npm run backend:test:privacy`.
- RLS and policy verification:
  `npm run backend:test:rls`
- Backend remediation regression checks:
  `npm run backend:test:remediation` and `npm run backend:test:remediation-unit`

## Local API E2E Safety

`npm run backend:test:e2e:api:local` is intended for local use. It resets the local database, exports the local Supabase env values needed by Node tests, waits for auth readiness, and then runs the API E2E suite.

The suite creates disposable users, uploads private storage objects, generates exports, calls cleanup endpoints, and deletes accounts as part of validation. It also performs cleanup of the users and storage artifacts it creates, but it should still be treated as destructive local test infrastructure rather than as a shared-environment command.

## Common Local Flow

Run locally after installing the Supabase CLI when you want the layered backend gate:

```sh
npm run backend:test:e2e:api:local
npm run backend:test:rls
npm run backend:test:meal-core
npm run backend:test:auth-profile
npm run backend:test:photo-analysis
npm run backend:test:multimodal
npm run backend:test:offline-sync
npm run backend:test:insights
npm run backend:test:privacy
npm run backend:test:remediation-unit
npm run backend:test:remediation
```

If local Supabase is already running and you only want the API E2E layer without another reset, run `npm run backend:test:e2e:api`.
