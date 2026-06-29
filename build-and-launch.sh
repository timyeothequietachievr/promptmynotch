#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

APP="$ROOT/dist/NotchPrompter.app"
SDK="$(xcrun --show-sdk-path 2>/dev/null || true)"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

check_toolchain() {
  if [[ -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]]; then
    return 0
  fi
  if swiftc -version >/dev/null 2>&1 && [[ -n "$SDK" ]]; then
    if swiftc -sdk "$SDK" -target "$(uname -m)-apple-macosx$(sw_vers -productVersion | cut -d. -f1).0" \
      -parse-as-library -o /tmp/np-toolchain-test \
      - <<'EOF' 2>/dev/null
import Foundation
@main struct T { static func main() { print("ok") } }
EOF
    then
      rm -f /tmp/np-toolchain-test
      return 0
    fi
  fi
  return 1
}

build_with_xcode() {
  echo "Building with Xcode…"
  DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" \
    xcodebuild \
      -project NotchPrompter.xcodeproj \
      -scheme NotchPrompter \
      -configuration Release \
      -derivedDataPath "$ROOT/build/DerivedData" \
      CODE_SIGN_IDENTITY="-" \
      CODE_SIGNING_ALLOWED=YES \
      build

  local built
  built="$(find "$ROOT/build/DerivedData" -name 'NotchPrompter.app' -type d | head -1)"
  [[ -n "$built" ]] || die "xcodebuild succeeded but NotchPrompter.app was not found."

  mkdir -p "$ROOT/dist"
  rm -rf "$APP"
  cp -R "$built" "$APP"
}

build_with_swiftc() {
  echo "Building with swiftc…"
  bash "$ROOT/scripts/bundle-app.sh"
}

echo "=== NotchPrompter build ==="

if [[ -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]]; then
  build_with_xcode
elif check_toolchain; then
  build_with_swiftc
else
  cat >&2 <<'EOF'

Cannot build: Swift toolchain is broken or missing.

Fix (pick one):

  A) Install Xcode (recommended)
     - App Store → Xcode → Install
     - Then run:
         sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
         ./build-and-launch.sh

  B) Reinstall Command Line Tools
         sudo rm -rf /Library/Developer/CommandLineTools
         xcode-select --install
     - After install finishes, run:
         ./build-and-launch.sh

EOF
  die "No working Swift compiler found."
fi

codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo ""
echo "Built: $APP"

echo "Quitting any running NotchPrompter…"
osascript -e 'tell application "NotchPrompter" to quit' 2>/dev/null || true
pkill -x NotchPrompter 2>/dev/null || true
for _ in {1..20}; do
  pgrep -x NotchPrompter >/dev/null || break
  sleep 0.25
done

echo "Launching NotchPrompter…"
open "$APP"
