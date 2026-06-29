#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="$(xcrun --show-sdk-path)"
SWIFTC=(xcrun swiftc -sdk "$SDK" -parse-as-library)

SOURCES=(
  "$ROOT/NotchPrompter/Services/PrompterTextMetrics.swift"
  "$ROOT/NotchPrompter/Services/PrompterTextTokenizer.swift"
  "$ROOT/NotchPrompter/Services/PrompterLineLayout.swift"
)

DISPLAY_SOURCES=(
  "$ROOT/NotchPrompter/Services/PrompterTextTokenizer.swift"
  "$ROOT/NotchPrompter/Services/PrompterWordDisplay.swift"
)

echo "Running Keynote slide-27 hit regression…"
"${SWIFTC[@]}" "${SOURCES[@]}" "$ROOT/scripts/verify_keynote_hit.swift" -o /tmp/verify_keynote_hit
/tmp/verify_keynote_hit

echo ""
echo "Running word display tests…"
"${SWIFTC[@]}" "${DISPLAY_SOURCES[@]}" "$ROOT/scripts/verify_word_display.swift" -o /tmp/verify_word_display
/tmp/verify_word_display

echo ""
echo "Building NotchPrompter (Release, no launch)…"
cd "$ROOT"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcodebuild \
  -project NotchPrompter.xcodeproj \
  -scheme NotchPrompter \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  build > /tmp/notch_build.log 2>&1

BUILT_APP=$(find build/DerivedData -name "NotchPrompter.app" -type d | head -1)
if [[ -z "$BUILT_APP" ]]; then
  echo "Build failed:"
  tail -20 /tmp/notch_build.log
  exit 1
fi
mkdir -p dist
rm -rf dist/NotchPrompter.app
cp -R "$BUILT_APP" dist/NotchPrompter.app
echo "Build succeeded: $ROOT/dist/NotchPrompter.app"
