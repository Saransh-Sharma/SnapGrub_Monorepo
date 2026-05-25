#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$ROOT/apps/mobile"

rm -rf "$MOBILE_DIR/ios/Flutter/ephemeral/Packages/.packages"
