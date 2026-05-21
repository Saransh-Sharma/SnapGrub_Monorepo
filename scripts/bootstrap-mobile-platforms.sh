#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d apps/mobile/android/app || ! -d apps/mobile/ios/Runner ]]; then
  cat >&2 <<'EOF'
Native Flutter platform folders are missing.

Run this once from apps/mobile on a machine with Flutter installed:
  flutter create --platforms android,ios --android-language kotlin --org com.snapgrub .

Then configure and commit dev/staging/prod flavors before relying on mobile CI.
EOF
  exit 1
fi

echo "Native Flutter platform folders are present."
