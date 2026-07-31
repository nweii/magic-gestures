#!/bin/zsh
set -euo pipefail

# Removes MagicGestures from the system. Settings are kept unless --all is
# passed, since they are the only part a reinstall cannot recreate.

ROOT="${0:A:h:h}"
APP_NAME="MagicGestures"
LABEL="fyi.nathancheng.magic-gestures.agent"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
CONFIG_DIR="$HOME/.config/magic-gestures"
GUI_DOMAIN="gui/$(id -u)"

REMOVE_SETTINGS=0
[[ "${1:-}" == "--all" ]] && REMOVE_SETTINGS=1

echo "Removing $APP_NAME."

if [[ -f "$PLIST" ]]; then
  launchctl bootout "$GUI_DOMAIN" "$PLIST" >/dev/null 2>&1 || true
  launchctl disable "$GUI_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  rm -f "$PLIST"
  echo "  Removed the login item."
fi

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  killall "$APP_NAME" >/dev/null 2>&1 || true
  echo "  Stopped the running app."
fi

if [[ -d "$ROOT/build" ]]; then
  rm -rf "$ROOT/build"
  echo "  Removed the built app."
fi

if (( REMOVE_SETTINGS )); then
  if [[ -d "$CONFIG_DIR" ]]; then
    rm -rf "$CONFIG_DIR"
    echo "  Removed $CONFIG_DIR."
  fi
else
  [[ -d "$CONFIG_DIR" ]] && echo "  Kept your settings at $CONFIG_DIR. Pass --all to remove them."
fi

cat <<'NOTE'

Two things are left, because no script can do them:

  1. Open System Settings > Privacy & Security > Accessibility and remove
     MagicGestures from the list.
  2. Delete this project folder if you no longer want the source.
NOTE
