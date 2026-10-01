#!/usr/bin/env bash
set -euo pipefail

failed=0
for file in services/backend/supabase/migrations/*.sql; do
  if [[ ! "$file" =~ /[0-9]{6}_.+\.sql$ ]]; then
    echo "Migration name must start with a six-digit sequence: $file" >&2
    failed=1
  fi
done

# Supabase keys applied migrations by this prefix, so two files sharing one
# cannot both be recorded and a fresh database fails to build.
duplicates="$(
  for file in services/backend/supabase/migrations/*.sql; do
    basename "$file" | cut -c1-6
  done | sort | uniq -d
)"
if [[ -n "$duplicates" ]]; then
  for version in $duplicates; do
    echo "Migration version $version is used by more than one file:" >&2
    ls services/backend/supabase/migrations/"$version"_*.sql >&2
  done
  failed=1
fi

exit "$failed"
