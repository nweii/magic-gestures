#!/bin/zsh
set -euo pipefail

APP_NAME="MagicGestures"
LABEL="fyi.nathancheng.magic-gestures.agent"
GUI_DOMAIN="gui/$(id -u)"

echo -n "app_process="
if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  echo "running"
else
  echo "not_running"
fi
echo -n "launch_agent="
launchctl print "$GUI_DOMAIN/$LABEL" >/dev/null 2>&1 && echo "loaded" || echo "not_loaded"
