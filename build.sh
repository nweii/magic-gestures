#!/bin/zsh
set -euo pipefail

APP_NAME="MagicGestures"
BUNDLE_ID="fyi.nathancheng.magic-gestures"
ROOT="${0:A:h}"
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
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.1</string>
  <key>CFBundleVersion</key>
  <string>2</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

cp "$ROOT/assets/move.png" "$RES_DIR/"
cp "$ROOT/assets/resize.png" "$RES_DIR/"
cp "$ROOT/assets/tab.png" "$RES_DIR/"
cp "$ROOT/assets/logosmall.png" "$RES_DIR/"
cp "$ROOT/assets/logosmalloff.png" "$RES_DIR/"

SDKROOT="$(xcrun --show-sdk-path)"

clang \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$SRC_ROOT" \
  -isysroot "$SDKROOT" \
  -F"$SDKROOT/System/Library/PrivateFrameworks" \
  -framework Cocoa \
  -framework Carbon \
  -framework ApplicationServices \
  -framework IOKit \
  -framework ScriptingBridge \
  -framework MultitouchSupport \
  "$ROOT/src/main.m" \
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

# Keep the designated requirement stable across rebuilds so macOS TCC can
# continue associating Accessibility permission with this bundle identifier.
codesign --force --deep --sign - \
  --requirements "=designated => identifier \"$BUNDLE_ID\"" \
  "$APP_BUNDLE" >/dev/null 2>&1 || true

echo "$APP_BUNDLE"
