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

"$OUT" \
  "$ROOT/config.default.txt" \
  "$ROOT/config-notes.default.md" \
  "$ROOT/GESTURES.md" \
  "$ROOT/src/jitouch/Jitouch/Gesture.m"

KEY_OUT="$(mktemp -d)/keyeventcheck"
clang \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$ROOT/src" \
  -isysroot "$SDKROOT" \
  -framework ApplicationServices \
  "$ROOT/src/KeyEventSequence.m" \
  "$ROOT/src/KeyEventSequenceCheck.m" \
  -o "$KEY_OUT" 2>/dev/null
"$KEY_OUT"

DEFER_OUT="$(mktemp -d)/defercheck"
clang \
  -fblocks \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$ROOT/src" \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  "$ROOT/src/DeferredGestureDispatcher.m" \
  "$ROOT/src/DeferredGestureDispatcherCheck.m" \
  -o "$DEFER_OUT" 2>/dev/null
"$DEFER_OUT"

CONTACT_TAP_OUT="$(mktemp -d)/contacttapcheck"
clang \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$ROOT/src" \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  "$ROOT/src/ContactTapRecognizer.m" \
  "$ROOT/src/ContactTapRecognizerCheck.m" \
  -o "$CONTACT_TAP_OUT" 2>/dev/null
"$CONTACT_TAP_OUT"

GESTURE_SEQUENCE_OUT="$(mktemp -d)/gesturesequencecheck"
clang \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$ROOT/src" \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  "$ROOT/src/GestureSequence.m" \
  "$ROOT/src/GestureSequenceCheck.m" \
  -o "$GESTURE_SEQUENCE_OUT" 2>/dev/null
"$GESTURE_SEQUENCE_OUT"

MOUSE_CONTACT_FILTER_OUT="$(mktemp -d)/mousecontactfiltercheck"
clang \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$ROOT/src" \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  "$ROOT/src/MouseContactFilter.m" \
  "$ROOT/src/MouseContactFilterCheck.m" \
  -o "$MOUSE_CONTACT_FILTER_OUT" 2>/dev/null
"$MOUSE_CONTACT_FILTER_OUT"

TRACKPAD_INTERACTION_OUT="$(mktemp -d)/trackpadinteractioncheck"
clang \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$ROOT/src" \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  "$ROOT/src/GestureSequence.m" \
  "$ROOT/src/TrackpadInteraction.m" \
  "$ROOT/src/TrackpadInteractionCheck.m" \
  -o "$TRACKPAD_INTERACTION_OUT" 2>/dev/null
"$TRACKPAD_INTERACTION_OUT"

SCRIPT_RUNNER_OUT="$(mktemp -d)/scriptrunnercheck"
clang \
  -fblocks \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$ROOT/src" \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  "$ROOT/src/ScriptRunner.m" \
  "$ROOT/src/ScriptRunnerCheck.m" \
  -o "$SCRIPT_RUNNER_OUT" 2>/dev/null
"$SCRIPT_RUNNER_OUT"

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

managed_fail() {
  echo "managed installation files drift: $1" >&2
  echo "  config.txt is create-only, AGENTS.md is atomically refreshed, and" >&2
  echo "  AGENTS.local.md remains user-owned across every installation path." >&2
  exit 1
}

wake_fail() {
  echo "wake recovery drift: $1" >&2
  echo "  Waking must rebuild the multitouch device list and re-register callbacks." >&2
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

# The application owns AGENTS.md while config.txt and AGENTS.local.md remain
# user-owned. Every installation path must preserve that boundary.
grep -q 'mv -f "$AGENT_TMP" "$CONFIG_DIR/AGENTS.md"' "$ROOT/scripts/start.sh" || managed_fail "start.sh does not atomically refresh AGENTS.md"
grep -q 'mv -f "$AGENT_TMP" "$CONFIG_DIR/AGENTS.md"' "$INSTALL_SH" || managed_fail "install-login-agent.sh does not atomically refresh AGENTS.md"
grep -q 'NSDataWritingAtomic' "$APP_SRC" || managed_fail "the app does not atomically refresh AGENTS.md"
grep -q 'AGENTS.local.md' "$ROOT/config-notes.default.md" || managed_fail "installed agent instructions do not route to AGENTS.local.md"

for item in 'Diagnostics' 'Copy Debug Info' 'Open Recent Logs' 'Verbose Logging This Session'; do
  grep -q "$item" "$APP_SRC" || fail "the menu is missing $item"
done
grep -q 'BindingCount' "$APP_SRC" || fail "the menu does not report the active binding count"

grep -q 'NSWorkspaceDidWakeNotification' "$APP_SRC" || wake_fail "the app does not observe wake notifications"
grep -q '\[self reload\]' "$APP_SRC" || wake_fail "the wake handler does not reload gesture devices"
for token in MTDeviceStop MTDeviceCreateList MTRegisterContactFrameCallback MTDeviceStart; do
  grep -q "$token" "$ROOT/src/jitouch/Jitouch/Gesture.m" || wake_fail "Gesture reload is missing $token"
done

grep -q 'config-version' "$ROOT/config.default.txt" || managed_fail "the default config has no format version"
grep -q 'config-version' "$ROOT/GESTURES.md" || managed_fail "GESTURES.md does not document the format version"
for f in "$ROOT/config.default.txt" "$ROOT/config-notes.default.md" "$ROOT/GESTURES.md"; do
  grep -q 'defer = true' "$f" || managed_fail "$f does not document deferred tap bindings"
  grep -q 'script:' "$f" || managed_fail "$f does not document script bindings"
  grep -q 'haptic-feedback' "$f" || managed_fail "$f does not document haptic feedback"
done

echo "login item plist writers agree"
