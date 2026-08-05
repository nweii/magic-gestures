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

if TAG_COMMIT="$(git -C "$ROOT" rev-list -n 1 "v$VERSION" 2>/dev/null)" &&
   [[ -n "$TAG_COMMIT" && "$TAG_COMMIT" != "$(git -C "$ROOT" rev-parse HEAD)" ]]; then
  echo "Version $VERSION already belongs to a different source commit." >&2
  echo "Bump the app version before packaging this build." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
ditto --norsrc --noextattr "$APP_BUNDLE" "$DIST_DIR/$APP_NAME.app"
cp "$ROOT/LICENSE.txt" "$ROOT/NOTICE.txt" "$ROOT/TRADEMARKS.md" "$DIST_DIR/"
printf '%s\n' \
  "The exact corresponding source for this build is available at:" \
  "https://github.com/nweii/trickpad/tree/v$VERSION" \
  > "$DIST_DIR/SOURCE.txt"
[[ ! -e "$ARCHIVE_PATH" ]] || mv "$ARCHIVE_PATH" "$DIST_ROOT/previous.zip"
ditto -c -k --norsrc --noextattr --keepParent "$DIST_DIR" "$ARCHIVE_PATH"

for required in \
  "$APP_NAME-$VERSION/$APP_NAME.app/Contents/Info.plist" \
  "$APP_NAME-$VERSION/LICENSE.txt" \
  "$APP_NAME-$VERSION/NOTICE.txt" \
  "$APP_NAME-$VERSION/TRADEMARKS.md" \
  "$APP_NAME-$VERSION/SOURCE.txt"; do
  unzip -Z1 "$ARCHIVE_PATH" | grep -Fxq "$required" || {
    echo "Packaged archive is missing $required" >&2
    exit 1
  }
done

echo "$ARCHIVE_PATH"
