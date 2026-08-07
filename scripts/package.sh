#!/bin/zsh
# Builds a styled Trickpad disk image containing the app, Applications link,
# license notices, and exact corresponding-source link.
set -euo pipefail
export COPYFILE_DISABLE=1

ROOT="${0:A:h:h}"
APP_NAME="Trickpad"
BUILD_ROOT="$ROOT/build"
APP_BUNDLE="$BUILD_ROOT/$APP_NAME.app"
BACKGROUND="$ROOT/packaging/dmg-background.png"
BACKGROUND_RETINA="$ROOT/packaging/dmg-background@2x.png"

command -v appdmg >/dev/null || {
  echo "Packaging requires appdmg. Install it with: npm install -g appdmg" >&2
  exit 1
}

"$ROOT/scripts/build.sh" >/dev/null

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
DMG_PATH="$BUILD_ROOT/$APP_NAME-$VERSION.dmg"
VOLUME_NAME="$APP_NAME $VERSION"
WORK_ROOT="$(mktemp -d)"
STAGE="$WORK_ROOT/$APP_NAME-$VERSION"
SPEC="$WORK_ROOT/appdmg.json"
VERIFY_DIR="$WORK_ROOT/verify"
DEVICE=""

cleanup() {
  if [[ -n "$DEVICE" ]]; then
    hdiutil detach "$DEVICE" -quiet 2>/dev/null || true
  fi
}
trap cleanup EXIT

if TAG_COMMIT="$(git -C "$ROOT" rev-list -n 1 "v$VERSION" 2>/dev/null)" &&
   [[ -n "$TAG_COMMIT" && "$TAG_COMMIT" != "$(git -C "$ROOT" rev-parse HEAD)" ]]; then
  echo "Version $VERSION already belongs to a different source commit." >&2
  echo "Bump the app version before packaging this build." >&2
  exit 1
fi

[[ -f "$BACKGROUND" ]] || {
  echo "Missing DMG background: $BACKGROUND" >&2
  exit 1
}
[[ -f "$BACKGROUND_RETINA" ]] || {
  echo "Missing Retina DMG background: $BACKGROUND_RETINA" >&2
  exit 1
}

mkdir -p "$STAGE/Legal"
cp "$ROOT/LICENSE.txt" "$ROOT/NOTICE.txt" "$ROOT/TRADEMARKS.md" "$STAGE/Legal/"
printf '%s\n' \
  "The exact corresponding source for this build is available at:" \
  "https://github.com/nweii/trickpad/tree/v$VERSION" \
  > "$STAGE/Legal/SOURCE.txt"

cat > "$SPEC" <<JSON
{
  "title": "$VOLUME_NAME",
  "background": "$BACKGROUND",
  "icon-size": 104,
  "window": {
    "position": { "x": 120, "y": 120 },
    "size": { "width": 660, "height": 540 }
  },
  "format": "UDZO",
  "filesystem": "HFS+",
  "contents": [
    { "x": 175, "y": 150, "type": "file", "path": "$APP_BUNDLE" },
    { "x": 485, "y": 150, "type": "link", "path": "/Applications" },
    { "x": 330, "y": 445, "type": "file", "path": "$STAGE/Legal" }
  ]
}
JSON

[[ ! -e "$DMG_PATH" ]] || mv "$DMG_PATH" "$WORK_ROOT/previous.dmg"
appdmg "$SPEC" "$DMG_PATH"

hdiutil verify "$DMG_PATH" -quiet
mkdir -p "$VERIFY_DIR"
DEVICE="$(hdiutil attach -readonly -noverify -noautoopen -mountpoint "$VERIFY_DIR" "$DMG_PATH" |
  awk '/Apple_HFS/ { print $1; exit }')"
[[ -n "$DEVICE" ]] || {
  echo "Could not mount the finished disk image." >&2
  exit 1
}

for required in \
  "$APP_NAME.app/Contents/Info.plist" \
  "Applications" \
  "Legal/LICENSE.txt" \
  "Legal/NOTICE.txt" \
  "Legal/TRADEMARKS.md" \
  "Legal/SOURCE.txt"; do
  [[ -e "$VERIFY_DIR/$required" ]] || {
    echo "Disk image is missing $required" >&2
    exit 1
  }
done

grep -Fxq "https://github.com/nweii/trickpad/tree/v$VERSION" \
  "$VERIFY_DIR/Legal/SOURCE.txt" || {
    echo "Disk image has the wrong corresponding-source link." >&2
    exit 1
  }
codesign --verify --deep --strict "$VERIFY_DIR/$APP_NAME.app"

hdiutil detach "$DEVICE" -quiet
DEVICE=""
echo "$DMG_PATH"
