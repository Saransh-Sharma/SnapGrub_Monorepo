# Database

Supabase Postgres stores authenticated user data, feature flags, analytics events, private storage metadata, idempotency records, and Phase 3 meal ledger data.

## Current Migration Sequence

- `000001_extensions_and_helpers.sql`
- `000002_identity_foundation.sql`
- `000003_identity_foundation_rls.sql`
- `000004_storage_buckets.sql`
- `000005_phase1_measurements_and_flags.sql`
- `000006_settings_idempotency_rpc.sql`
- `000007_meal_core.sql`
- `000008_phase3_meal_completion.sql`

## Rules

- Add new schema changes through a new migration.
- Document schema, RLS, and index changes here.
- Add RLS tests for every new user-owned table.
- Keep service-only tables unreadable by clients.
- Keep derived rollup writes behind service-role RPCs.
- Keep correction events append-only.

More detail:

- [schema.md](schema.md)
- [rls.md](rls.md)
- [migrations.md](migrations.md)
