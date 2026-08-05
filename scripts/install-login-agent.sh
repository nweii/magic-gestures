#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="Trickpad"
APP_BUNDLE="$ROOT/build/$APP_NAME.app"
CONFIG_DIR="$HOME/.config/trickpad"
LABEL="fyi.thirdwind.trickpad.agent"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"
GUI_DOMAIN="gui/$(id -u)"

mkdir -p "$ROOT/run" "$HOME/Library/LaunchAgents"

if [[ ! -x "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ]]; then
  "$ROOT/scripts/build.sh" >/dev/null
fi

mkdir -p "$CONFIG_DIR"
[[ -f "$CONFIG_DIR/config.toml" ]] || cp "$ROOT/config.default.toml" "$CONFIG_DIR/config.toml"
AGENT_TMP="$(mktemp "$CONFIG_DIR/.AGENTS.md.XXXXXX")"
cp "$ROOT/config-notes.default.md" "$AGENT_TMP"
mv -f "$AGENT_TMP" "$CONFIG_DIR/AGENTS.md"

cat > "$PLIST_DST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!--
  Maps Magic Mouse and Magic Trackpad gestures to keystrokes.

  Application:   $APP_BUNDLE
  Settings:      $CONFIG_DIR

  Deleting this file stops the agent from starting at login. It leaves the
  application and its settings untouched.
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

# PLIST_ONLY writes the file without changing the running launchd job. The menu
# bar item uses it to avoid restarting or terminating its own process.
if [[ -z "${PLIST_ONLY:-}" ]]; then
  launchctl bootout "$GUI_DOMAIN" "$PLIST_DST" >/dev/null 2>&1 || true
  # `launchctl disable` persists across logins. Re-enable the job before
  # bootstrapping so installation also works after the job has been disabled.
  launchctl enable "$GUI_DOMAIN/$LABEL"
  launchctl bootstrap "$GUI_DOMAIN" "$PLIST_DST"
  launchctl kickstart -k "$GUI_DOMAIN/$LABEL" >/dev/null 2>&1 || true
else
  launchctl enable "$GUI_DOMAIN/$LABEL" >/dev/null 2>&1 || true
fi

echo "$PLIST_DST"
