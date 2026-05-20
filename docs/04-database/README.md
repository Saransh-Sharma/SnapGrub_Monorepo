# Database

Supabase Postgres stores authenticated user data, feature flags, analytics events, private storage metadata, and idempotency records.

## Current Migration Sequence

- `000001_extensions_and_helpers.sql`
- `000002_identity_foundation.sql`
- `000003_identity_foundation_rls.sql`
- `000004_storage_buckets.sql`
- `000005_phase1_measurements_and_flags.sql`
- `000006_settings_idempotency_rpc.sql`

## Rules

- Add new schema changes through a new migration.
- Document schema, RLS, and index changes here.
- Add RLS tests for every new user-owned table.
- Keep service-only tables unreadable by clients.

More detail:

- [schema-phase-0-1.md](schema-phase-0-1.md)
- [rls.md](rls.md)
- [migrations.md](migrations.md)
