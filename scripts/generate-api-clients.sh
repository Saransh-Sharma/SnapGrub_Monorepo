#!/usr/bin/env bash
set -euo pipefail

node scripts/generate-api-clients.mjs "$@"
