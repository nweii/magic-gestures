#!/bin/zsh
# Builds the distributable Trickpad folder with the app, license notices, and
# exact-source link, then creates the release archive.
set -euo pipefail
export COPYFILE_DISABLE=1

ROOT="${0:A:h:h}"
APP_NAME="Trickpad"
BUILD_ROOT="$ROOT/build"
APP_BUNDLE="$BUILD_ROOT/$APP_NAME.app"

"$ROOT/scripts/build.sh" >/dev/null

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
ARCHIVE_PATH="$BUILD_ROOT/$APP_NAME-$VERSION.zip"
DIST_ROOT="$(mktemp -d)"
DIST_DIR="$DIST_ROOT/$APP_NAME-$VERSION"

mkdir -p "$DIST_DIR"
ditto --norsrc --noextattr "$APP_BUNDLE" "$DIST_DIR/$APP_NAME.app"
cp "$ROOT/LICENSE.txt" "$ROOT/NOTICE.txt" "$DIST_DIR/"
printf '%s\n' \
  "The exact corresponding source for this build is available at:" \
  "https://github.com/nweii/trickpad/tree/v$VERSION" \
  > "$DIST_DIR/SOURCE.txt"
[[ ! -e "$ARCHIVE_PATH" ]] || mv "$ARCHIVE_PATH" "$DIST_ROOT/previous.zip"
ditto -c -k --norsrc --noextattr --keepParent "$DIST_DIR" "$ARCHIVE_PATH"

echo "$ARCHIVE_PATH"
