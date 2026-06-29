#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/dist/NotchPrompter.app"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if [[ ! -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
  echo "Xcode not found. Install from the App Store, then run:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

cd "$ROOT"
echo "Building NotchPrompter (Release)…"

xcodebuild \
  -project NotchPrompter.xcodeproj \
  -scheme NotchPrompter \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  build

BUILT_APP=$(find build/DerivedData -name "NotchPrompter.app" -type d | head -1)
if [[ -z "$BUILT_APP" ]]; then
  echo "Build failed — app bundle not found."
  exit 1
fi

mkdir -p dist
rm -rf dist/NotchPrompter.app
cp -R "$BUILT_APP" dist/NotchPrompter.app

echo ""
echo "Ready: $APP"

echo "Quitting any running NotchPrompter…"
osascript -e 'tell application "NotchPrompter" to quit' 2>/dev/null || true
pkill -x NotchPrompter 2>/dev/null || true
for _ in {1..20}; do
  pgrep -x NotchPrompter >/dev/null || break
  sleep 0.25
done

echo "Launching NotchPrompter…"
open "$APP"
