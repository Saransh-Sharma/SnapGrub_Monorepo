# Nutrition Catalog

Nutrition catalog ingestion is implemented as an MVP Phase 5 seed, with provenance rules captured here for future expansion.

## Current Status

- Shared domain notes exist under `packages/shared-domain/nutrition`.
- Phase 5 adds canonical food, alias, nutrient, portion, branded product, barcode, and catalog mapping tables.
- The current catalog is a curated MVP seed plus a small hot barcode cache, not broad production ingestion.
- `meal_items` preserve manual/custom/catalog/branded source metadata for confirmed meals.
- No broad scheduled catalog ingestion job is active yet.

Related:

- [sources-and-licensing.md](sources-and-licensing.md)
- [ingestion-plan.md](ingestion-plan.md)
