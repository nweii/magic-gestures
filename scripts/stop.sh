#!/bin/zsh
set -euo pipefail

APP_NAME="Trickpad"

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  killall "$APP_NAME"
fi
