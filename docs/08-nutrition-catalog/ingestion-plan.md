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
