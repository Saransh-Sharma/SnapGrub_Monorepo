# Ingestion Plan

Catalog ingestion is deferred. Before implementing it, define:

- Source approval and license review.
- Raw import storage location.
- Normalized schema and migration.
- Provenance fields.
- Validation rules for serving size, units, calories, macros, and locale.
- Duplicate detection and update strategy.
- QA samples and rollback process.

Do not run ingestion scripts against production data until the schema, source license, and rollback plan are documented.

Phase 3 custom foods are user-authored records and should not be mixed into global catalog ingestion. Future catalog mappings should preserve `food_ref_kind`, source IDs, and license/provenance fields on meal items.

## USDA FoodData Central

`scripts/seed-catalog.sh` loads an FDC JSON download into `canonical_foods`, `food_nutrients` and `food_portions`, and records the run in `catalog_ingest_runs`.

- Check the mapping first: `bash scripts/seed-catalog.sh --file <download.json> --dry-run`.
- Local project: set `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`, then run without `--dry-run`.
- Hosted project: the script refuses unless `--allow-remote` is passed.
- Validation: records without protein, fat and carbohydrate are skipped. Energy uses the published kcal value, or 4/4/9 from macros when none exists.
- Duplicates: foods upsert on `(source_type, source_id)`, so a re-run updates in place.
- Rollback: `delete from public.canonical_foods where source_type = 'usda_fdc';` Nutrients and portions cascade; meal items keep their saved numbers and lose only the catalog link.
- Known limit: FDC names read like "Rice, white, long-grain, cooked". They work for search but rarely match a model's item name exactly, so grounding still depends on curated names and aliases.

