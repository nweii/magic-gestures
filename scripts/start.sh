#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="Trickpad"
APP_BUNDLE="$ROOT/build/$APP_NAME.app"
CONFIG_DIR="$HOME/.config/trickpad"

mkdir -p "$ROOT/run"

if [[ ! -x "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ]]; then
  "$ROOT/scripts/build.sh" >/dev/null
fi

mkdir -p "$CONFIG_DIR"
[[ -f "$CONFIG_DIR/config.toml" ]] || cp "$ROOT/config.default.toml" "$CONFIG_DIR/config.toml"
AGENT_TMP="$(mktemp "$CONFIG_DIR/.AGENTS.md.XXXXXX")"
cp "$ROOT/config-notes.default.md" "$AGENT_TMP"
mv -f "$AGENT_TMP" "$CONFIG_DIR/AGENTS.md"

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  killall "$APP_NAME" >/dev/null 2>&1 || true
  sleep 1
fi

open "$APP_BUNDLE"

for _ in {1..20}; do
  if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    echo "$APP_NAME running"
    exit 0
  fi
  sleep 1
done

echo "$APP_NAME failed to launch" >&2
exit 1
