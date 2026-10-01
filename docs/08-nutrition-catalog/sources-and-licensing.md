# Sources And Licensing

Every nutrition data source must be approved before ingestion.

## Required Source Metadata

- Source name and owner.
- License and commercial-use constraints.
- Attribution requirements.
- Update frequency.
- Region/cuisine coverage.
- Data fields and known limitations.

## Provenance Rules

Catalog records must preserve source, version/import batch, and transformation notes. Do not merge sources in a way that loses attribution or licensing constraints.

Manual and custom-food Phase 3 entries should be marked as user-owned provenance, not licensed catalog data. Future canonical/branded catalog records must remain distinguishable from user-authored custom foods.

## Approved Sources

### USDA FoodData Central (Foundation Foods, SR Legacy)

- Owner: U.S. Department of Agriculture, Agricultural Research Service.
- License: public domain, published under CC0 1.0. No commercial-use limits. USDA asks for a citation.
- Attribution: "U.S. Department of Agriculture, Agricultural Research Service. FoodData Central." with the release date of the download.
- Update frequency: Foundation Foods twice a year; SR Legacy is final (2018).
- Coverage: generic foods, mostly as eaten in the United States. Weak on Indian home dishes.
- Fields used: description, category, energy, protein, fat, carbohydrate, fibre per 100 g, household portions.
- Stored as `source_type = 'usda_fdc'`, `source_id = 'fdc:<fdcId>'`, `license_tag = 'CC0-1.0'`.

### Pending

- Indian food composition data (IFCT 2017 or another source): licence not yet confirmed. Do not ingest until it is.

