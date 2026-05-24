#!/usr/bin/env bash
set -euo pipefail

missing=0
export PATH="$PATH:$HOME/.maestro/bin"

check() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "ok: %s -> %s\n" "$name" "$(command -v "$cmd")"
  else
    printf "missing: %s (%s)\n" "$name" "$cmd" >&2
    missing=1
  fi
}

check "Flutter" flutter
check "ADB" adb
check "Supabase CLI" supabase
check "Maestro" maestro

if ! command -v maestro >/dev/null 2>&1; then
  cat >&2 <<'MSG'

Install Maestro, then rerun this doctor:
  curl -Ls "https://get.maestro.mobile.dev" | bash

MSG
fi

if command -v flutter >/dev/null 2>&1; then
  flutter --version | sed -n '1,3p'
fi
if command -v maestro >/dev/null 2>&1; then
  maestro --version
fi

exit "$missing"
