# Database

Supabase Postgres stores authenticated user data, feature flags, analytics events, private storage metadata, idempotency records, meal ledger data, photo-analysis state, multimodal catalog data, sync state, export requests, and weekly insight/default records.

## Current Migration Sequence

- `000001_extensions_and_helpers.sql`
- `000002_identity_foundation.sql`
- `000003_identity_foundation_rls.sql`
- `000004_storage_buckets.sql`
- `000005_phase1_measurements_and_flags.sql`
- `000006_settings_idempotency_rpc.sql`
- `000007_meal_core.sql`
- `000008_phase3_meal_completion.sql`
- `000009_phase4_photo_analysis.sql`
- `000010_phase5_catalog_multimodal.sql`
- `000011_phase6_sync_readiness.sql`
- `000012_phase7_insights_defaults.sql`

## Rules

- Add new schema changes through a new migration.
- Document schema, RLS, and index changes here.
- Add RLS tests for every new user-owned table.
- Keep service-only tables unreadable by clients.
- Keep derived rollup writes behind service-role RPCs.
- Keep correction events append-only.
- Keep model invocation details and feature flag overrides server-controlled.

More detail:

- [schema.md](schema.md)
- [rls.md](rls.md)
- [migrations.md](migrations.md)
