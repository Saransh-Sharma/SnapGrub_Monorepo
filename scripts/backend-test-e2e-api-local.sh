#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${TMPDIR:-/tmp}/snapgrub-supabase-e2e.env"

cd "$repo_root"
bash scripts/run-local-supabase.sh

(
  cd services/backend/supabase
  supabase status -o env > "$env_file"
)

set -a
# shellcheck disable=SC1090
. "$env_file"
set +a

export SUPABASE_URL="${SUPABASE_URL:-${API_URL:-}}"
export SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-${ANON_KEY:-}}"
export SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-${SERVICE_ROLE_KEY:-}}"
export NODE_OPTIONS="${NODE_OPTIONS:+$NODE_OPTIONS }--experimental-websocket"
export AI_PROVIDER="${AI_PROVIDER:-mock}"

wait_for_auth() {
  local attempts="$1"
  local curl_bin
  curl_bin="$(command -v curl)"
  for _ in $(seq 1 "$attempts"); do
    if "$curl_bin" -fsS "$SUPABASE_URL/auth/v1/settings" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

if ! wait_for_auth 10; then
  kong_container="$(docker ps --format '{{.Names}}' | grep '^supabase_kong_' | head -n 1 || true)"
  if [[ -n "$kong_container" ]]; then
    docker restart "$kong_container" >/dev/null
  fi
  wait_for_auth 60
fi

npm run backend:test:e2e:api
