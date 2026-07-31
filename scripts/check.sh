#!/bin/zsh
set -euo pipefail

# Compiles and runs the configuration parser checks without a test framework or
# fixtures. These checks catch bindings that parse without producing an action.

ROOT="${0:A:h:h}"
OUT="$(mktemp -d)/configcheck"
SDKROOT="$(xcrun --show-sdk-path)"

clang \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$ROOT/src" \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  -framework ApplicationServices \
  -framework Carbon \
  "$ROOT/src/Config.m" \
  "$ROOT/src/ConfigCheck.m" \
  -o "$OUT" 2>/dev/null

"$OUT" "$ROOT/config.default.txt" "$ROOT/config-notes.default.md" "$ROOT/GESTURES.md"

# The login item plist is written by two independent pieces of code: the app's
# Open at Login menu item (JitouchAppDelegate.m) and scripts/install-login-agent.sh.
# They may differ in how they launch the app, but the job label and the keys
# that govern its behavior must stay identical, or a login item written by one
# side stops being recognized or managed by the other.
APP_SRC="$ROOT/src/jitouch/Jitouch/JitouchAppDelegate.m"
INSTALL_SH="$ROOT/scripts/install-login-agent.sh"
LABEL="fyi.nathancheng.magic-gestures.agent"

fail() {
  echo "login item drift: $1" >&2
  echo "  The app (src/jitouch/Jitouch/JitouchAppDelegate.m, loginAgentPlistContents)" >&2
  echo "  and scripts/install-login-agent.sh both write the launchd plist and must" >&2
  echo "  agree on the label and behavior keys. Edit whichever side changed so both" >&2
  echo "  match, then rerun scripts/check.sh." >&2
  exit 1
}

for f in "$APP_SRC" "$INSTALL_SH" "$ROOT/scripts/uninstall-login-agent.sh" "$ROOT/scripts/uninstall.sh"; do
  grep -q "$LABEL" "$f" || fail "$f does not contain the label $LABEL"
done

for key in RunAtLoad KeepAlive ProcessType; do
  grep -q "<key>$key</key>" "$APP_SRC"    || fail "the app's plist is missing <key>$key</key>"
  grep -q "<key>$key</key>" "$INSTALL_SH" || fail "install-login-agent.sh's plist is missing <key>$key</key>"
done
grep -q "<string>Interactive</string>" "$APP_SRC"    || fail "the app's plist does not set ProcessType to Interactive"
grep -q "<string>Interactive</string>" "$INSTALL_SH" || fail "install-login-agent.sh's plist does not set ProcessType to Interactive"

echo "login item plist writers agree"
