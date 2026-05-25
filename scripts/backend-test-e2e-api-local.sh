#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$(mktemp "${TMPDIR:-/tmp}/snapgrub-supabase-e2e.XXXXXX")"
edge_env_file="services/backend/supabase/functions/.env"

cleanup() {
  rm -f "$env_file"
}
trap cleanup EXIT

cd "$repo_root"
export CORS_ALLOW_ORIGIN="${CORS_ALLOW_ORIGIN:-http://localhost:3000}"
export AI_PROVIDER="${AI_PROVIDER:-mock}"
touch "$edge_env_file"
upsert_edge_env() {
  local key="$1"
  local value="$2"
  local escaped_value
  escaped_value="${value//\\/\\\\}"
  escaped_value="${escaped_value//&/\\&}"
  escaped_value="${escaped_value//|/\\|}"
  if grep -q "^${key}=" "$edge_env_file"; then
    sed -i.bak "s|^${key}=.*|${key}=${escaped_value}|" "$edge_env_file"
    rm -f "$edge_env_file.bak"
  else
    printf '%s=%s\n' "$key" "$value" >> "$edge_env_file"
  fi
}
upsert_edge_env CORS_ALLOW_ORIGIN "$CORS_ALLOW_ORIGIN"
upsert_edge_env AI_PROVIDER "$AI_PROVIDER"
(
  cd services/backend/supabase
  supabase stop --no-backup --yes >/dev/null 2>&1 || true
)
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
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    kong_container="$(docker ps --format '{{.Names}}' | grep '^supabase_kong_' | head -n 1 || true)"
    if [[ -n "$kong_container" ]]; then
      docker restart "$kong_container" >/dev/null
    fi
  fi
  wait_for_auth 60
fi

npm run backend:test:e2e:api
