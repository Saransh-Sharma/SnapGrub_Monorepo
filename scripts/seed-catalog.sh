#!/usr/bin/env bash
set -euo pipefail

# Loads a USDA FoodData Central JSON download into the catalog.
# Download "Foundation Foods" (JSON) from https://fdc.nal.usda.gov/download-datasets
# then run, for example:
#   bash scripts/seed-catalog.sh --file ~/Downloads/foundation.json --dry-run
# See docs/08-nutrition-catalog/ingestion-plan.md before pointing this at a
# hosted project.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
node scripts/catalog/ingest-fdc.mjs "$@"
