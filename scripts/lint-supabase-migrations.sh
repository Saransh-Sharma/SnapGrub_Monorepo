#!/usr/bin/env bash
set -euo pipefail

missing=0
for file in services/backend/supabase/migrations/*.sql; do
  if [[ ! "$file" =~ /[0-9]{6}_.+\.sql$ ]]; then
    echo "Migration name must start with a six-digit sequence: $file" >&2
    missing=1
  fi
done

exit "$missing"
