# magic-gestures

Maps Magic Mouse and Magic Trackpad multi-touch gestures to keystrokes on
macOS. Runs headless as a background agent with no interface.

## Vendored engine, local config layer

Recognition is [Jitouch](https://github.com/JitouchApp/Jitouch), vendored under
`src/jitouch/` by way of a fork that strips its preference pane. The `upstream`
remote points at that fork.

`src/main.m` is 26 lines. `Gesture.m` is roughly 4,800 lines of recognizers.
Changes belong in `generate_config.py` unless the engine is demonstrably wrong.

Jitouch reads the private `MultitouchSupport.framework`, which is undocumented
and free to change across macOS releases. Upstream has had no code commits since
January 2023, so breakage is ours to fix.

## Build and run

```bash
python3 ./generate_config.py   # -> config/MagicGestures.plist, config/bindings.md
./build.sh                     # single clang call, no Xcode project
./stop.sh && ./start.sh
```

Config-only changes skip the build. The agent reloads on SIGHUP, and `start.sh`
restarts it cheaply either way.

The Accessibility grant binds to the bundle path plus the designated requirement
that `build.sh` pins. Keep both stable and the grant survives every rebuild.

## Login item

`./install-login-agent.sh` writes a launchd plist to
`~/Library/LaunchAgents/fyi.nathancheng.magic-gestures.agent.plist`, which
starts the agent at login and restarts it if it exits. The generated plist
opens with a comment naming what it does and pointing back here, since a bare
launchd label is easy to find and hard to identify.

`./uninstall-login-agent.sh` removes it. Deleting the plist by hand has the same
effect and leaves the project alone.

This is the only file the project writes outside its own directory.

## Logging

Set `LogLevel` to 2 for per-gesture and per-keystroke logging:

```bash
/usr/bin/log show --style compact --last 5m --predicate 'process == "MagicGestures"'
```

## Configuration model

`generate_config.py` defines every binding and writes the plist the engine
reads. There is no settings interface.

`Settings.m` resolves that plist by walking up two directories from the running
bundle, so `build/` and `config/` must stay siblings inside the project.
Setting `MAGIC_MOUSE_AGENT_SETTINGS` overrides the path. The `appID`
CFPreferences domain in `Settings.h` is vestigial — only the removed preference
pane wrote to it.

Three binding forms:

- `shortcut(gesture, label, keycode, modifiers)` sends a keystroke.
- `action(gesture, command)` invokes a built-in. Valid names are the string
  literals compared in `dispatchCommand` in `Gesture.m`.
- A dict carrying `OpenURL` with `IsAction` true opens a URL through
  `NSWorkspace`. Any command name matching no built-in falls through to it.

Gesture names must match `dispatchCommand`'s strings exactly. The two devices
keep separate tables, enable flags, and vocabularies: the mouse names gestures
by finger (`Index-Fix Middle-Near-Tap`), the trackpad by tap position relative
to the anchor (`One-Fix Right-Tap`). A binding on one device does not reach the
other.

Shift, Control, Option, and Command are the available modifiers. Fn is a HID
usage rather than a key event and cannot be synthesized.

## Standing constraints

- **Clicking stays native.** Gestures fire keystrokes and actions. Click
  behavior, including tap-to-click being off, stays as macOS provides it.
- **Hyper is reserved.** Cmd+Alt+Ctrl is Caps Lock remapped, and its letters
  belong to application launchers. Bindings here omit Alt.
- **Fix-taps carry anything consequential.** Holding one finger still while
  tapping with another is unreachable by a resting hand, unlike a plain tap or
  a swipe.

## Hardware-only applications

Some applications watch the keyboard through a CGEventTap and accept only events
that originated from real hardware. No configuration reaches them. Confirm a
target responds to a synthesized keystroke before building bindings around it.

`config/bindings.md` carries the worked example.

## Local modifications to the vendored engine

Two, both deliberate, neither upstream. Reverting either regresses silently.

`KeyUtility.m`, `simulateKeyCode:` posts through `CGEventCreateKeyboardEvent`
with modifiers set as flags on the keystroke itself, replacing the deprecated
`CGPostKeyboardEvent` and its separate synthetic modifier keypresses. Hotkey
APIs read `modifierFlags` off the key event, so the old path delivered a bare
key that matched no combination. Each modifier also sets its device-dependent
left-side bit (`NX_DEVICELSHIFTKEYMASK` and kin), since an application can
register a side-specific hotkey that the generic masks cannot satisfy.

`Gesture.m`, `gestureMagicMouseOneFingerSwipe` returns early when nothing is
bound to a one-finger swipe. The suppression below that point disables
horizontal scrolling on any one-finger horizontal movement, and upstream runs it
whether or not a swipe is bound, degrading ordinary scrolling in an unbound
configuration.
