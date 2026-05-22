#!/usr/bin/env bash
set -euo pipefail

missing=()

[[ -f apps/mobile/android/settings.gradle.kts ]] || missing+=("apps/mobile/android/settings.gradle.kts")
[[ -f apps/mobile/android/app/build.gradle.kts ]] || missing+=("apps/mobile/android/app/build.gradle.kts")
[[ -f apps/mobile/android/app/src/main/AndroidManifest.xml ]] || missing+=("apps/mobile/android/app/src/main/AndroidManifest.xml")
[[ -f apps/mobile/android/app/src/main/kotlin/com/snapgrub/snapgrub/MainActivity.kt ]] || missing+=("apps/mobile/android/app/src/main/kotlin/com/snapgrub/snapgrub/MainActivity.kt")
[[ -f apps/mobile/ios/Runner.xcodeproj/project.pbxproj ]] || missing+=("apps/mobile/ios/Runner.xcodeproj/project.pbxproj")
[[ -f apps/mobile/ios/Flutter/Debug.xcconfig ]] || missing+=("apps/mobile/ios/Flutter/Debug.xcconfig")
[[ -f apps/mobile/ios/Flutter/Profile.xcconfig ]] || missing+=("apps/mobile/ios/Flutter/Profile.xcconfig")
[[ -f apps/mobile/ios/Flutter/Release.xcconfig ]] || missing+=("apps/mobile/ios/Flutter/Release.xcconfig")
[[ -f apps/mobile/ios/Runner/Info.plist ]] || missing+=("apps/mobile/ios/Runner/Info.plist")
[[ -f apps/mobile/ios/Runner/AppDelegate.swift ]] || missing+=("apps/mobile/ios/Runner/AppDelegate.swift")

if (( ${#missing[@]} > 0 )); then
  cat >&2 <<'EOF'
Native Flutter platform project files are missing.

Run this once from apps/mobile on a machine with Flutter installed:
  flutter create --platforms android,ios --android-language kotlin --org com.snapgrub .

Then configure and commit dev/staging/prod flavors before relying on mobile CI.
EOF
  printf 'Missing required files:\n' >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

echo "Native Flutter platform project files are present."
