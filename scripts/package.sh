#!/bin/zsh
# Builds MagicGestures.app and zips it for a GitHub release, preserving the
# bundle structure and ad-hoc signature.
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="MagicGestures"
BUILD_ROOT="$ROOT/build"
APP_BUNDLE="$BUILD_ROOT/$APP_NAME.app"

"$ROOT/scripts/build.sh" >/dev/null

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
ARCHIVE_PATH="$BUILD_ROOT/$APP_NAME-$VERSION.zip"

rm -f "$ARCHIVE_PATH"
ditto -c -k --keepParent "$APP_BUNDLE" "$ARCHIVE_PATH"

echo "$ARCHIVE_PATH"
