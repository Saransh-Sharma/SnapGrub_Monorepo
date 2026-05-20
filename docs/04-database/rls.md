# Row-Level Security

All user-owned Phase 0/1 tables must enforce tenant isolation with Supabase RLS.

## Current Expectations

| Table | Client access |
| --- | --- |
| `profiles` | authenticated user can select/insert/update own row |
| `nutrition_goals` | authenticated user can CRUD own goals |
| `devices` | authenticated user can CRUD own devices |
| `body_measurements` | authenticated user can CRUD own measurements |
| `feature_flags` | authenticated users can read global flags |
| `feature_flag_overrides` | no direct client access |
| `analytics_events` | authenticated users can insert own/pre-auth events only |
| `api_idempotency` | service-side only |

## Test Coverage

The RLS harness lives at `services/backend/supabase/tests/rls_isolation.mjs`.

It creates two auth users and checks:

- User A can read/update own records.
- User A cannot read/update User B records.
- Feature flag overrides and analytics reads are blocked.
- Global feature flags are readable.

Run it after `supabase db reset` with local Supabase env variables loaded.
