#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="MagicGestures"
APP_BUNDLE="$ROOT/build/$APP_NAME.app"
CONFIG="$ROOT/config/MagicGestures.plist"
LABEL="fyi.nathancheng.magic-gestures.agent"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"
GUI_DOMAIN="gui/$(id -u)"

mkdir -p "$ROOT/run" "$HOME/Library/LaunchAgents"

if [[ ! -x "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ]]; then
  "$ROOT/build.sh" >/dev/null
fi

if [[ ! -f "$CONFIG" ]]; then
  python3 "$ROOT/generate_config.py" >/dev/null
fi

cat > "$PLIST_DST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!--
  Maps Magic Mouse and Magic Trackpad gestures to keystrokes.

  Source and configuration:  $ROOT
  Written by:                $ROOT/install-login-agent.sh
  To remove:                 $ROOT/uninstall-login-agent.sh

  Deleting this file stops the agent from starting at login. It leaves the
  project itself untouched.
-->
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/open</string>
    <string>-W</string>
    <string>$APP_BUNDLE</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ProcessType</key>
  <string>Interactive</string>
  <key>StandardOutPath</key>
  <string>$ROOT/run/launchd.stdout.log</string>
  <key>StandardErrorPath</key>
  <string>$ROOT/run/launchd.stderr.log</string>
</dict>
</plist>
PLIST

# PLIST_ONLY writes the file and stops. The menu bar item uses it so toggling
# the setting cannot restart or terminate the app that is running the toggle.
if [[ -z "${PLIST_ONLY:-}" ]]; then
  launchctl bootout "$GUI_DOMAIN" "$PLIST_DST" >/dev/null 2>&1 || true
  # `launchctl disable` persists across logins. Re-enable first so a reinstall
  # can recover a previously removed or disabled login item before bootstrapping.
  launchctl enable "$GUI_DOMAIN/$LABEL"
  launchctl bootstrap "$GUI_DOMAIN" "$PLIST_DST"
  launchctl kickstart -k "$GUI_DOMAIN/$LABEL" >/dev/null 2>&1 || true
else
  launchctl enable "$GUI_DOMAIN/$LABEL" >/dev/null 2>&1 || true
fi

echo "$PLIST_DST"
