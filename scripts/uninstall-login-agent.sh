#!/bin/zsh
set -euo pipefail

LABEL="fyi.nathancheng.magic-gestures.agent"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"
GUI_DOMAIN="gui/$(id -u)"

# PLIST_ONLY removes the file without changing the running launchd job. The menu
# bar item uses it to avoid terminating its own process.
if [[ -z "${PLIST_ONLY:-}" ]]; then
  launchctl bootout "$GUI_DOMAIN" "$PLIST_DST" >/dev/null 2>&1 || true
  launchctl disable "$GUI_DOMAIN/$LABEL" >/dev/null 2>&1 || true
fi
rm -f "$PLIST_DST"
