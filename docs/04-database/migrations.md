# Migrations

Migration files live in `services/backend/supabase/migrations`.

## Safe Change Checklist

- Create a new numbered migration; do not edit applied migrations after shared use.
- Use the next free six-digit number. Supabase records applied migrations by that prefix, so two files sharing one cannot both be recorded and a fresh database fails to build. `npm run backend:lint:migrations` rejects duplicates.
- Add constraints close to the data they protect.
- Add RLS policies in the same phase as the table.
- Add indexes for expected access patterns.
- Update [schema.md](schema.md) and [rls.md](rls.md).
- Run:

```sh
npm run backend:lint:migrations
cd services/backend/supabase
supabase db reset
```

## Current Special Cases

- `settings-patch` writes through `public.patch_user_settings`.
- `api_idempotency` stores replay responses for `settings-patch`.
- `meals` writes through `public.upsert_user_meal` and `public.delete_user_meal`.
- `daily_rollups` are derived rows refreshed by `public.refresh_daily_rollup`; clients read only.
- Phase 4 analysis tables are created in `000009_phase4_photo_analysis.sql`.
- Phase 8 privacy/export/delete tables and helper RPCs are created in `000013_phase8_privacy_export_delete.sql`.
- Backend hardening for runtime grants, retention backfill, day listing, remediation, barcode miss caching, invocation privacy, custom-food ownership, safer cleanup, and atomic rule-analysis persistence is layered through `000014`-`000019`.
- `000020_conversational_journal.sql` adds daily threads, messages, agent runs, proposals and meal artwork.
- `000021_smart_foods_v2_flag.sql` was `000019` until October 2026; it was renumbered because it shared a version with `000019_persist_rule_analysis_rpc.sql`. It is an idempotent upsert and resets `smart_foods_v2.enabled` to false when applied.
- `000022_food_search_rpc.sql` adds trigram indexes and `public.search_canonical_foods` for ranked catalog search.
- `source=photo` meal writes are allowed only through `public.upsert_user_meal` after validating completed owned analysis and asset references.
- `exports-create` writes artifact metadata to `export_requests`; clients should not write these columns directly.
- `account-delete` writes `account_deletion_requests`; clients should not insert or update deletion audit rows directly.
- `api_rate_limits` is service-owned and should only be mutated through `public.consume_api_rate_limit`.
- `media-retention-cleanup` depends on `public.expired_export_artifacts`, `public.mark_exports_expired`, `public.expired_meal_assets`, and `public.mark_meal_assets_deleted`.
- Scheduled `weekly-insights-generate` batch mode depends on `public.users_due_for_weekly_insights`.
- RPC replacement migrations should re-create the full function body, re-apply revoke/grant statements, and add/update smoke tests.
- Private storage buckets support meal originals, thumbnails, and server-generated export artifacts under authenticated user prefixes.
