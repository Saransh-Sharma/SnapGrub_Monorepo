#!/usr/bin/env bash
# Captures App Store / marketing screenshots on an iPhone 17 Pro Max simulator
# (6.9", 1320×2868), derives the 6.5" set (1284×2778) and composes captioned
# marketing frames.
#
#   tool/marketing/capture.sh            # everything
#   tool/marketing/capture.sh --frames   # only re-compose frames (edit captions.json)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mobile="$(cd "$here/../.." && pwd)"
out="$mobile/marketing/out"
art="$mobile/marketing/illustrations"
device_name="SnapGrub Marketing 17 Pro Max"
device_type="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max"

compose_frames() {
  node "$here/frames/compose.mjs"
}

if [[ "${1:-}" == "--frames" ]]; then
  compose_frames
  exit 0
fi

command -v flutter >/dev/null || export PATH="$HOME/Developer/SDKs/flutter/bin:$PATH"

# 0. Illustrations (regenerate if missing).
if [[ ! -f "$art/hero-plate.png" ]]; then
  node "$here/illustrations/render.mjs"
fi

# 1. Simulator: create once, boot, clean status bar.
runtime="$(xcrun simctl list runtimes | grep -Eo 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+' | tail -1)"
udid="$(xcrun simctl list devices | grep -F "$device_name (" | grep -v unavailable | grep -Eo '[0-9A-F-]{36}' | head -1 || true)"
if [[ -z "$udid" ]]; then
  udid="$(xcrun simctl create "$device_name" "$device_type" "$runtime")"
fi
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
xcrun simctl status_bar "$udid" override --time "12:41" --batteryState charged \
  --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3 \
  --dataNetwork wifi --operatorName ""

# 2. Run the capture test; screenshot on every SHOT: marker.
rm -rf "$out"
mkdir -p "$out/6.9/raw/light" "$out/6.9/raw/dark" "$out/6.5/raw/light" "$out/6.5/raw/dark"
log="$out/capture.log"
: > "$log"
(
  cd "$mobile"
  flutter test integration_test/marketing/app_store_shots_test.dart -d "$udid" \
    --dart-define=SNAPGRUB_E2E=true --dart-define=SNAPGRUB_E2E_BACKEND=mock \
    --dart-define=SNAPGRUB_E2E_AUTH=password \
    --dart-define=MARKETING_ART_DIR="$art" >> "$log" 2>&1 && status=0 || status=$?
  echo "CAPTURE_EXIT:$status" >> "$log"
) &
seen=" "
while true; do
  for name in $(grep -o 'SHOT:[a-z0-9_]*' "$log" | cut -d: -f2); do
    if [[ "$seen" != *" $name "* ]]; then
      theme="${name%%_*}"
      file="${name#*_}"
      xcrun simctl io "$udid" screenshot "$out/6.9/raw/$theme/$file.png" >/dev/null 2>&1
      seen="$seen$name "
      echo "  captured $theme/$file"
    fi
  done
  grep -q 'CAPTURE_EXIT' "$log" && break
  sleep 0.3
done
xcrun simctl status_bar "$udid" clear || true

if ! grep -q 'CAPTURE_EXIT:0' "$log" || grep -q 'EXCEPTION CAUGHT' "$log"; then
  echo "Capture failed — see $log" >&2
  grep -A6 'EXCEPTION CAUGHT' "$log" | head -40 >&2 || true
  exit 1
fi

# 3. 6.5" set: scale to 1284 wide, centre-crop to 1284×2778.
for f in "$out"/6.9/raw/*/*.png; do
  rel="${f#"$out"/6.9/}"
  dest="$out/6.5/$rel"
  sips --resampleWidth 1284 "$f" --out "$dest" >/dev/null
  sips --cropToHeightWidth 2778 1284 "$dest" >/dev/null
done

# 4. Captioned frames at both sizes.
compose_frames

# 5. Summary.
echo
echo "Output: $out"
for dir in "$out"/6.9/raw/* "$out"/6.5/raw/* "$out"/6.9/framed/* "$out"/6.5/framed/*; do
  [[ -d "$dir" ]] || continue
  count=$(ls "$dir"/*.png 2>/dev/null | wc -l | tr -d ' ')
  first=$(ls "$dir"/*.png 2>/dev/null | head -1)
  dims=$(sips -g pixelWidth -g pixelHeight "$first" 2>/dev/null | awk '/pixel/ {printf "%s ", $2}')
  echo "  ${dir#"$out"/}: $count images (${dims% })"
done
