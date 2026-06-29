#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SDK="$(xcrun --show-sdk-path)"
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  TARGET="arm64-apple-macosx14.0"
else
  TARGET="x86_64-apple-macosx14.0"
fi

SOURCES=()
while IFS= read -r file; do
  SOURCES+=("$file")
done < <(find NotchPrompter -name '*.swift' | sort)

echo "Compiling ${#SOURCES[@]} Swift files for $TARGET..."

mkdir -p "$ROOT/dist"
BINARY="$ROOT/dist/NotchPrompter.bin"

swiftc -O \
  -sdk "$SDK" \
  -target "$TARGET" \
  -parse-as-library \
  -o "$BINARY" \
  "${SOURCES[@]}" \
  -framework AppKit \
  -framework SwiftUI \
  -framework AVFoundation \
  -framework AuthenticationServices \
  -framework UniformTypeIdentifiers \
  -framework QuartzCore \
  -framework Combine \
  -framework CoreGraphics \
  -framework Foundation \
  -framework Observation

APP="$ROOT/dist/NotchPrompter.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$ROOT/NotchPrompter/Info.plist" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable NotchPrompter" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.notchprompter.app" "$APP/Contents/Info.plist"

cp "$BINARY" "$APP/Contents/MacOS/NotchPrompter"
chmod +x "$APP/Contents/MacOS/NotchPrompter"
rm -f "$BINARY"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP" 2>/dev/null || true
fi

echo ""
echo "Ready: $APP"
echo "  Launch: open \"$APP\""
echo "  Or drag NotchPrompter.app to Applications."
