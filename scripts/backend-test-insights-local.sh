#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$(mktemp "${TMPDIR:-/tmp}/snapgrub-supabase-insights.XXXXXX")"

cleanup() {
  rm -f "$env_file"
}
trap cleanup EXIT

require_command() {
  local command_name="$1"
  local install_hint="$2"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name. $install_hint" >&2
    exit 1
  fi
}

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

restart_local_kong_if_available() {
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    return 0
  fi
  local kong_container
  kong_container="$(docker ps --format '{{.Names}}' | grep '^supabase_kong_' | head -n 1 || true)"
  if [[ -n "$kong_container" ]]; then
    echo "Restarting stale local Supabase Kong container: $kong_container"
    docker restart "$kong_container" >/dev/null
  fi
}

require_command docker "Start Docker Desktop and ensure Docker is on PATH."
require_command supabase "Install with: brew install supabase/tap/supabase"
require_command node "Install Node 20 or newer."
require_command npm "Install npm with Node."
require_command curl "Install curl or ensure it is on PATH."

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop before running local Supabase tests." >&2
  exit 1
fi

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

if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "Supabase local env did not provide SUPABASE_URL." >&2
  exit 1
fi
if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "Supabase local env did not provide SUPABASE_ANON_KEY." >&2
  exit 1
fi
if [[ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "Supabase local env did not provide SUPABASE_SERVICE_ROLE_KEY." >&2
  exit 1
fi

export NODE_OPTIONS="${NODE_OPTIONS:+$NODE_OPTIONS }--experimental-websocket"

if ! wait_for_auth 10; then
  restart_local_kong_if_available
  if ! wait_for_auth 60; then
    echo "Local Supabase Auth did not become ready at $SUPABASE_URL/auth/v1/settings." >&2
    exit 1
  fi
fi

npm run backend:test:insights
