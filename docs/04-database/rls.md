# Row-Level Security

All user-owned tables must enforce tenant isolation with Supabase RLS.

## Current Expectations

| Table | Client access |
| --- | --- |
| `profiles` | authenticated user can select/insert/update own row |
| `nutrition_goals` | authenticated user can CRUD own goals |
| `devices` | authenticated user can CRUD own devices |
| `body_measurements` | authenticated user can select own measurements; Phase 6 creation uses `body-measurements` or `settings-patch` |
| `feature_flags` | authenticated users can read global flags |
| `feature_flag_overrides` | no direct client access |
| `analytics_events` | authenticated users can insert own/pre-auth events only |
| `api_idempotency` | service-side only |
| `meals` | authenticated user can select own rows; writes go through `meals` Edge Function/RPC path |
| `meal_items` | authenticated user can select own rows; writes follow meal ownership |
| `meal_templates` | authenticated user can read own rows; Phase 6 mobile mutations use the `meal-templates` Edge Function |
| `custom_foods` | authenticated user can read own rows; Phase 6 mobile mutations use the `custom-foods` Edge Function |
| `daily_rollups` | authenticated user can select own rows; service-role RPCs write derived rows |
| `correction_events` | authenticated user can select own rows; append-only writes from meal paths |
| `meal_assets` | authenticated user can select/insert/update own asset rows; storage path prefix must match user ID |
| `analysis_jobs` | authenticated user can select own jobs; service-role functions create/update jobs |
| `analysis_revisions` | authenticated user can select own revisions; service-role functions insert immutable revisions |
| `analysis_candidates` | authenticated user can select candidates through owned analysis revisions |
| `model_invocations` | authenticated user can select own invocation summaries; service-role functions insert rows |
| `pending_uploads` | authenticated user can select own upload state; service-role functions own writes |
| `export_requests` | authenticated user can select own export requests; creation goes through `exports-create` |

## Test Coverage

The RLS harness lives at `services/backend/supabase/tests/rls_isolation.mjs`.

It creates two auth users and checks:

- User A can read/update own records.
- User A cannot read/update User B records.
- Feature flag overrides and analytics reads are blocked.
- Global feature flags are readable.
- Phase 3 meal, item, template, custom-food, rollup, and correction-event isolation is checked.
- Phase 4 meal asset, analysis job, revision, candidate, and model invocation isolation is checked.

Run it after `supabase db reset` with local Supabase env variables loaded.
