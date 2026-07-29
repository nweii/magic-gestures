#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="MagicGestures"
VERSION="${1:-0.1.1}"
DIST_DIR="$ROOT/dist"
STAGE_ROOT="$(mktemp -d "/tmp/${APP_NAME}.XXXXXX")"
PACKAGE_DIR="$STAGE_ROOT/$APP_NAME-$VERSION"
ARCHIVE_PATH="$DIST_DIR/$APP_NAME-$VERSION-macos.zip"

mkdir -p "$DIST_DIR"

python3 "$ROOT/generate_config.py" >/dev/null
"$ROOT/build.sh" >/dev/null

mkdir -p "$PACKAGE_DIR"

rsync -a \
  --exclude '.git' \
  --exclude 'dist' \
  --exclude '.DS_Store' \
  "$ROOT/" "$PACKAGE_DIR/"

ditto -c -k --sequesterRsrc --keepParent "$PACKAGE_DIR" "$ARCHIVE_PATH"

echo "$ARCHIVE_PATH"
