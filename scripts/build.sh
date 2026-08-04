#!/bin/zsh
set -euo pipefail

APP_NAME="Trickpad"
BUNDLE_ID="fyi.thirdwind.trickpad"
ROOT="${0:A:h:h}"
SRC_ROOT="$ROOT/src/jitouch/Jitouch"
BUILD_ROOT="$ROOT/build"
APP_BUNDLE="$BUILD_ROOT/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RES_DIR="$APP_BUNDLE/Contents/Resources"

mkdir -p "$MACOS_DIR" "$RES_DIR"

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
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.6.1</string>
  <key>CFBundleVersion</key>
  <string>12</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST


SDKROOT="$(xcrun --show-sdk-path)"

clang \
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
  -fblocks \
  -fobjc-exceptions \
  -fno-objc-arc \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  "$ROOT/src/TraceAnalyzer.m" \
  -o "$RES_DIR/analyze-trace"

# A stable designated requirement lets macOS TCC associate Accessibility
# permission with this bundle identifier across rebuilds.
codesign --force --deep --sign - \
  --requirements "=designated => identifier \"$BUNDLE_ID\"" \
  "$APP_BUNDLE" >/dev/null 2>&1 || true

echo "$APP_BUNDLE"
