#!/bin/zsh
set -euo pipefail

APP_NAME="Trickpad"
BUNDLE_ID="fyi.thirdwind.trickpad"
MIN_MACOS_VERSION="11.0"
ARCHITECTURES=(x86_64 arm64)
ROOT="${0:A:h:h}"
SRC_ROOT="$ROOT/src/jitouch/Jitouch"
BUILD_ROOT="$ROOT/build"
APP_BUNDLE="$BUILD_ROOT/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RES_DIR="$APP_BUNDLE/Contents/Resources"
ICON_SOURCE="$ROOT/Trickpad.icon"
ICON_BUILD_SOURCE="$BUILD_ROOT/Trickpad.icon"
ICON_INFO="$BUILD_ROOT/TrickpadIconInfo.plist"

mkdir -p "$MACOS_DIR" "$RES_DIR"

# Icon Composer 2.0 writes a top-level feature declaration that its renderer
# understands but Xcode 26.6's asset compiler rejects. Compile a compatible
# generated copy while retaining the authored document unchanged.
ditto "$ICON_SOURCE" "$ICON_BUILD_SOURCE"
plutil -remove features "$ICON_BUILD_SOURCE/icon.json" 2>/dev/null || true

# Compile the Icon Composer document into the layered asset catalog macOS 26
# uses, plus the flattened ICNS fallback for earlier supported releases.
xcrun actool "$ICON_BUILD_SOURCE" \
  --compile "$RES_DIR" \
  --platform macosx \
  --minimum-deployment-target "$MIN_MACOS_VERSION" \
  --app-icon "$APP_NAME" \
  --output-partial-info-plist "$ICON_INFO" \
  --warnings \
  --notices \
  --errors >/dev/null

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>Trickpad</string>
  <key>CFBundleIconFile</key>
  <string>Trickpad</string>
  <key>CFBundleIconName</key>
  <string>Trickpad</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.7.0</string>
  <key>CFBundleVersion</key>
  <string>13</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_MACOS_VERSION</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST


SDKROOT="$(xcrun --show-sdk-path)"

clang \
  -arch x86_64 \
  -arch arm64 \
  -mmacosx-version-min="$MIN_MACOS_VERSION" \
  -Werror=unguarded-availability-new \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$SRC_ROOT" \
  -I"$ROOT/src" \
  -I"$ROOT/third_party/tomlc17" \
  -isysroot "$SDKROOT" \
  -F"$SDKROOT/System/Library/PrivateFrameworks" \
  -framework Cocoa \
  -framework Carbon \
  -framework ApplicationServices \
  -framework AudioToolbox \
  -framework IOKit \
  -framework ScriptingBridge \
  -framework MultitouchSupport \
  "$ROOT/src/main.m" \
  "$ROOT/src/Config.m" \
  "$ROOT/src/ContactTapRecognizer.m" \
  "$ROOT/src/DeferredGestureDispatcher.m" \
  "$ROOT/src/GestureSequence.m" \
  "$ROOT/src/KeyEventSequence.m" \
  "$ROOT/src/MouseContactFilter.m" \
  "$ROOT/src/MouseClickInteraction.m" \
  "$ROOT/src/ContactOnsetTracker.m" \
  "$ROOT/src/ScriptRunner.m" \
  "$ROOT/src/TraceRecorder.m" \
  "$ROOT/src/TraceSessionModel.m" \
  "$ROOT/src/TrackpadInteraction.m" \
  "$ROOT/third_party/tomlc17/tomlc17.c" \
  "$SRC_ROOT/JitouchAppDelegate.m" \
  "$SRC_ROOT/Settings.m" \
  "$SRC_ROOT/Gesture.m" \
  "$SRC_ROOT/KeyUtility.m" \
  "$SRC_ROOT/CursorWindow.m" \
  "$SRC_ROOT/CursorView.m" \
  "$SRC_ROOT/GestureWindow.m" \
  "$SRC_ROOT/GestureView.m" \
  "$SRC_ROOT/SizeHistory.m" \
  -o "$MACOS_DIR/$APP_NAME"

# The bundle carries its own seed files so a copied app can create the
# configuration folder without the source tree beside it.
cp "$ROOT/config.default.toml" "$RES_DIR/config.default.toml"
cp "$ROOT/config-notes.default.md" "$RES_DIR/config-notes.default.md"

# The installed app analyzes its redacted export without depending on source files.
clang \
  -arch x86_64 \
  -arch arm64 \
  -mmacosx-version-min="$MIN_MACOS_VERSION" \
  -Werror=unguarded-availability-new \
  -fblocks \
  -fobjc-exceptions \
  -fno-objc-arc \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  "$ROOT/src/TraceAnalyzer.m" \
  -o "$RES_DIR/analyze-trace"

# Keep the public compatibility claim tied to the binaries users receive.
for binary in "$MACOS_DIR/$APP_NAME" "$RES_DIR/analyze-trace"; do
  xcrun vtool -show-build "$binary" | grep -q "minos $MIN_MACOS_VERSION" || {
    echo "Unexpected deployment target in $binary" >&2
    exit 1
  }
  built_architectures="$(lipo -archs "$binary")"
  for architecture in "${ARCHITECTURES[@]}"; do
    [[ " $built_architectures " == *" $architecture "* ]] || {
      echo "Missing $architecture architecture in $binary" >&2
      exit 1
    }
  done
done

# A stable designated requirement lets macOS TCC associate Accessibility
# permission with this bundle identifier across rebuilds.
codesign --force --deep --sign - \
  --requirements "=designated => identifier \"$BUNDLE_ID\"" \
  "$APP_BUNDLE" >/dev/null
codesign --verify --deep --strict "$APP_BUNDLE" >/dev/null

echo "$APP_BUNDLE"
