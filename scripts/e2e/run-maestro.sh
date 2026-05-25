#!/usr/bin/env bash
set -euo pipefail

platform="${1:-}"
backend="${2:-mock}"
target="${3:-local}"

if [[ "$platform" != "android" && "$platform" != "ios" ]]; then
  echo "usage: $0 android|ios mock|supabase [local|developer]" >&2
  exit 2
fi

if [[ "$backend" != "mock" && "$backend" != "supabase" ]]; then
  echo "usage: $0 android|ios mock|supabase [local|developer]" >&2
  exit 2
fi

if [[ "$target" != "local" && "$target" != "developer" ]]; then
  echo "usage: $0 android|ios mock|supabase [local|developer]" >&2
  exit 2
fi

if [[ "$backend" == "mock" && "$target" != "local" ]]; then
  echo "mock E2E only supports the local target" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mobile_dir="$repo_root/apps/mobile"
app_id="com.snapgrub.dev"
password="${E2E_PASSWORD:-SnapGrub-e2e-password-123}"

export PATH="$PATH:$HOME/.maestro/bin"

if ! command -v maestro >/dev/null 2>&1; then
  echo "Maestro is not installed. Run: npm run e2e:maestro:doctor" >&2
  exit 1
fi

load_env_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    value="${value%$'\r'}"
    value="${value%\"}"
    value="${value#\"}"
    export "$key=$value"
  done < "$file"
}

is_localhost_url() {
  local value="${1:-}"
  [[ "$value" == http://127.0.0.1:* || "$value" == http://localhost:* || "$value" == http://0.0.0.0:* ]]
}

slugify() {
  printf '%s' "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//'
}

platform_label="$([[ "$platform" == "ios" ]] && printf 'iOS' || printf 'Android')"
case "$target" in
  developer) target_label="Developer Cloud" ;;
  local) target_label="$([[ "$backend" == "mock" ]] && printf 'Mock' || printf 'Local Supabase')" ;;
esac
data_prefix="$platform_label $target_label"

export E2E_PASSWORD="$password"
export E2E_EMAIL="${E2E_EMAIL:-snapgrub-e2e-$platform@example.com}"
export E2E_DATA_PREFIX="${E2E_DATA_PREFIX:-$data_prefix}"
export E2E_DISPLAY_NAME="${E2E_DISPLAY_NAME:-$data_prefix Tester}"
export E2E_MANUAL_MEAL_TITLE="${E2E_MANUAL_MEAL_TITLE:-$data_prefix Manual Lunch}"
export E2E_EDITED_MEAL_TITLE="${E2E_EDITED_MEAL_TITLE:-$data_prefix Edited Lunch}"
export E2E_CUSTOM_FOOD_NAME="${E2E_CUSTOM_FOOD_NAME:-$data_prefix Granola}"
export E2E_TEXT_MEAL_INPUT="${E2E_TEXT_MEAL_INPUT:-dal and rice}"
export E2E_TEXT_MEAL_TITLE="${E2E_TEXT_MEAL_TITLE:-$data_prefix Text Dal Rice}"
export E2E_VOICE_MEAL_INPUT="${E2E_VOICE_MEAL_INPUT:-poha}"
export E2E_VOICE_MEAL_TITLE="${E2E_VOICE_MEAL_TITLE:-$data_prefix Voice Poha}"
export E2E_UNKNOWN_BAR_TITLE="${E2E_UNKNOWN_BAR_TITLE:-$data_prefix Unknown Bar}"
export E2E_PHOTO_MEAL_TITLE="${E2E_PHOTO_MEAL_TITLE:-$data_prefix Photo Meal}"

E2E_MANUAL_MEAL_ID="journal.meal.$(slugify "$E2E_MANUAL_MEAL_TITLE")"
E2E_MANUAL_MEAL_COPY_ID="${E2E_MANUAL_MEAL_ID}_copy"
E2E_EDITED_MEAL_ID="journal.meal.$(slugify "$E2E_EDITED_MEAL_TITLE")"
E2E_TEXT_MEAL_ID="journal.meal.$(slugify "$E2E_TEXT_MEAL_TITLE")"
E2E_VOICE_MEAL_ID="journal.meal.$(slugify "$E2E_VOICE_MEAL_TITLE")"
E2E_UNKNOWN_BAR_ID="journal.meal.$(slugify "$E2E_UNKNOWN_BAR_TITLE")"
E2E_PHOTO_MEAL_ID="journal.meal.$(slugify "$E2E_PHOTO_MEAL_TITLE")"
export E2E_MANUAL_MEAL_ID
export E2E_MANUAL_MEAL_COPY_ID
export E2E_EDITED_MEAL_ID
export E2E_TEXT_MEAL_ID
export E2E_VOICE_MEAL_ID
export E2E_UNKNOWN_BAR_ID
export E2E_PHOTO_MEAL_ID

if [[ "$backend" == "supabase" ]]; then
  app_env_file="$mobile_dir/.env.$target"
  load_env_file "$app_env_file"
  : "${SUPABASE_URL:?SUPABASE_URL is required in $app_env_file for Supabase E2E}"
  : "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY is required in $app_env_file for Supabase E2E}"
  if [[ "$target" == "developer" ]] && is_localhost_url "$SUPABASE_URL"; then
    echo "developer Supabase E2E requires a non-localhost SUPABASE_URL in $app_env_file" >&2
    exit 1
  fi
  if [[ "$target" == "local" ]] && ! is_localhost_url "$SUPABASE_URL"; then
    echo "local Supabase E2E expected a localhost SUPABASE_URL in $app_env_file" >&2
    exit 1
  fi
  E2E_PLATFORM="$platform" E2E_TARGET="$target" E2E_EMAIL="$E2E_EMAIL" E2E_PASSWORD="$E2E_PASSWORD" \
    node "$repo_root/scripts/e2e/seed-supabase-dev.mjs"
fi

dart_defines=(
  "--dart-define=SNAPGRUB_ENV=dev"
  "--dart-define=SNAPGRUB_E2E=true"
  "--dart-define=SNAPGRUB_E2E_BACKEND=$backend"
  "--dart-define=SNAPGRUB_E2E_AUTH=password"
)

if [[ "$backend" == "supabase" ]]; then
  dart_defines+=(
    "--dart-define=SUPABASE_URL=$SUPABASE_URL"
    "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
  )
fi

encode_dart_defines() {
  local encoded=()
  local define_arg define
  for define_arg in "${dart_defines[@]}"; do
    define="${define_arg#--dart-define=}"
    encoded+=("$(printf '%s' "$define" | base64 | tr -d '\n')")
  done
  local IFS=,
  echo "${encoded[*]}"
}

ios_simulator_build_prepared=0

prepare_ios_simulator_build() {
  local pubspec="$mobile_dir/pubspec.yaml"
  local recognizer="$mobile_dir/lib/features/barcode/data/label_text_recognizer.dart"
  cp "$pubspec" "$pubspec.e2e-ios.bak"
  cp "$recognizer" "$recognizer.e2e-ios.bak"
  sed -i '' '/google_mlkit_text_recognition/d' "$pubspec"
  cat > "$recognizer" <<'EOF'
/// Stub-only export for iOS simulator E2E (google_mlkit lacks arm64 sim slices).
library;

export 'label_text_recognizer_stub.dart';
EOF
  ios_simulator_build_prepared=1
  flutter pub get
  (cd "$mobile_dir/ios" && pod install)
}

restore_ios_simulator_build() {
  if [[ "$ios_simulator_build_prepared" != "1" ]]; then
    return 0
  fi
  local pubspec="$mobile_dir/pubspec.yaml"
  local recognizer="$mobile_dir/lib/features/barcode/data/label_text_recognizer.dart"
  mv "$pubspec.e2e-ios.bak" "$pubspec"
  mv "$recognizer.e2e-ios.bak" "$recognizer"
  ios_simulator_build_prepared=0
  flutter pub get
  (cd "$mobile_dir/ios" && pod install)
}

allow_arm64_ios_simulator_build() {
  local generated_xcconfig="$mobile_dir/ios/Flutter/Generated.xcconfig"
  [[ -f "$generated_xcconfig" ]] || return 0
  sed -i '' 's/EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]=i386 arm64/EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386/' \
    "$generated_xcconfig"
}

open_simulator_app() {
  open -a Simulator
  osascript -e 'tell application "Simulator" to activate' 2>/dev/null || true
}

cd "$mobile_dir"

if [[ "$platform" == "android" ]]; then
  flutter pub get
  flutter build apk --debug --flavor dev "${dart_defines[@]}"
  adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk
else
  trap restore_ios_simulator_build EXIT
  prepare_ios_simulator_build
  ios_simulator_name="${IOS_SIMULATOR_NAME:-iPhone 16 Pro}"
  open_simulator_app
  xcrun simctl boot "$ios_simulator_name" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$ios_simulator_name" -b
  ios_app_path="build/ios/iphonesimulator/Runner.app"
  allow_arm64_ios_simulator_build
  if ! flutter build ios --simulator --debug "${dart_defines[@]}"; then
    echo "flutter build ios failed; retrying arm64 simulator build with xcodebuild" >&2
    allow_arm64_ios_simulator_build
    dart_defines_encoded="$(encode_dart_defines)"
    xcodebuild \
      -workspace ios/Runner.xcworkspace \
      -scheme Runner \
      -configuration Debug \
      -sdk iphonesimulator \
      -destination "platform=iOS Simulator,name=$ios_simulator_name" \
      ARCHS=arm64 \
      ONLY_ACTIVE_ARCH=YES \
      SNAPGRUB_DISPLAY_NAME="SnapGrub Dev" \
      SNAPGRUB_BUNDLE_ID="$app_id" \
      DART_DEFINES="$dart_defines_encoded"
    ios_app_path="$(find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 8 -path '*Debug-iphonesimulator/Runner.app' -type d -print | sort | tail -n 1)"
  fi
  allow_arm64_ios_simulator_build
  if [[ -f "$ios_app_path/Runner" ]]; then
    runner_arch="$(lipo -info "$ios_app_path/Runner" 2>/dev/null || true)"
    if [[ "$runner_arch" != *"arm64"* ]]; then
      echo "expected arm64 iOS simulator build, got: $runner_arch" >&2
      exit 1
    fi
  fi
  if [[ ! -d "$ios_app_path" ]]; then
    echo "iOS app bundle not found at $ios_app_path" >&2
    exit 1
  fi
  xcrun simctl install booted "$ios_app_path"
fi

maestro test \
  --config "$mobile_dir/maestro/config.yaml" \
  -e "APP_ID=$app_id" \
  -e "E2E_EMAIL=$E2E_EMAIL" \
  -e "E2E_PASSWORD=$E2E_PASSWORD" \
  -e "E2E_DISPLAY_NAME=$E2E_DISPLAY_NAME" \
  -e "E2E_MANUAL_MEAL_TITLE=$E2E_MANUAL_MEAL_TITLE" \
  -e "E2E_MANUAL_MEAL_ID=$E2E_MANUAL_MEAL_ID" \
  -e "E2E_MANUAL_MEAL_COPY_ID=$E2E_MANUAL_MEAL_COPY_ID" \
  -e "E2E_EDITED_MEAL_TITLE=$E2E_EDITED_MEAL_TITLE" \
  -e "E2E_EDITED_MEAL_ID=$E2E_EDITED_MEAL_ID" \
  -e "E2E_CUSTOM_FOOD_NAME=$E2E_CUSTOM_FOOD_NAME" \
  -e "E2E_TEXT_MEAL_INPUT=$E2E_TEXT_MEAL_INPUT" \
  -e "E2E_TEXT_MEAL_TITLE=$E2E_TEXT_MEAL_TITLE" \
  -e "E2E_TEXT_MEAL_ID=$E2E_TEXT_MEAL_ID" \
  -e "E2E_VOICE_MEAL_INPUT=$E2E_VOICE_MEAL_INPUT" \
  -e "E2E_VOICE_MEAL_TITLE=$E2E_VOICE_MEAL_TITLE" \
  -e "E2E_VOICE_MEAL_ID=$E2E_VOICE_MEAL_ID" \
  -e "E2E_UNKNOWN_BAR_TITLE=$E2E_UNKNOWN_BAR_TITLE" \
  -e "E2E_UNKNOWN_BAR_ID=$E2E_UNKNOWN_BAR_ID" \
  -e "E2E_PHOTO_MEAL_TITLE=$E2E_PHOTO_MEAL_TITLE" \
  -e "E2E_PHOTO_MEAL_ID=$E2E_PHOTO_MEAL_ID" \
  "$mobile_dir/maestro/flows/01_critical_smoke.yaml"
