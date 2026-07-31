# magic-gestures

Maps Magic Mouse and Magic Trackpad multi-touch gestures to keystrokes on
macOS. Runs headless as a background agent with no interface.

`CLAUDE.md` is a symlink to this file. Edit this one.

Shell scripts live in `scripts/` and resolve paths from the project root, two
levels up from themselves. `generate_config.py` stays at the root because it is
the file you edit to change behavior.

## Vendored engine, local config layer

Recognition is [Jitouch](https://github.com/JitouchApp/Jitouch), vendored under
`src/jitouch/` by way of a fork. The `upstream` remote points at that fork.

Jitouch is a gesture app with a catalog of built-in actions and a preference
pane for choosing among them. This project keeps its recognizers and drops the
rest, so a gesture sends whatever keyboard shortcut the configuration names.
Prefer that shape when adding anything: the built-in actions still work and are
worth using where they fit, but the catalog is not the point.

`src/main.m` is 26 lines. `Gesture.m` is roughly 4,800 lines of recognizers.
Changes belong in `generate_config.py` unless the engine is demonstrably wrong.

Jitouch reads the private `MultitouchSupport.framework`, which is undocumented
and free to change across macOS releases. Upstream has had no code commits since
January 2023, so breakage is ours to fix.

## Build and run

```bash
python3 ./generate_config.py   # -> config/MagicGestures.plist, config/bindings.md
./scripts/build.sh             # single clang call, no Xcode project
./scripts/stop.sh && ./scripts/start.sh
```

Config-only changes skip the build. Apply them from the menu bar item's Reload
Configuration, which regenerates the plist and reads it back, or restart with
`scripts/start.sh`. SIGHUP re-registers the multi-touch devices without
rereading settings, so it does not apply a binding change on its own.

The Accessibility grant binds to the bundle path plus the designated requirement
that `scripts/build.sh` pins. Keep both stable and the grant survives every rebuild.

## Login item

`./scripts/install-login-agent.sh` writes a launchd plist to
`~/Library/LaunchAgents/fyi.nathancheng.magic-gestures.agent.plist`, which
starts the agent at login and restarts it if it exits. The generated plist
opens with a comment naming what it does and pointing back here, since a bare
launchd label is easy to find and hard to identify.

`./scripts/uninstall-login-agent.sh` removes it. Deleting the plist by hand has
the same effect and leaves the project alone.

`./scripts/uninstall.sh` removes everything the project installed: the login
item, the running app, and the build. It keeps the settings folder unless
called with `--all`, and prints the two steps that cannot be scripted.

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

`GESTURES.md` lists every gesture name the engine recognizes, split by device.
Names must match exactly, and an unrecognized name is ignored without an error.
The two devices keep separate tables, enable flags, and vocabularies, so a
binding on one does not reach the other.

Shift, Control, Option, and Command are the available modifiers. Fn is a HID
usage rather than a key event and cannot be synthesized.

## Standing constraints

- **Add, never replace.** A binding extends what the hardware does. Anything
  System Settings owns — tap-to-click, secondary click, the built-in swipes —
  keeps behaving as the user configured it. `Middle Click` is fair game on a
  Magic Mouse, which has no middle button to override.
- **Check both conflict surfaces before binding.** macOS claims some motions,
  listed in `GESTURES.md`. The user's own hotkeys claim some chords, and a
  Caps Lock remapped to Cmd+Alt+Ctrl is a common one worth asking about.
- **Fix gestures carry anything consequential.** Holding one finger still while
  another taps or slides is unreachable by a resting hand, and macOS uses that
  shape nowhere.

## Hardware-only applications

Some applications watch the keyboard through a CGEventTap and accept only events
that originated from real hardware. No configuration reaches them. Confirm a
target responds to a synthesized keystroke before building bindings around it.

Aqua Voice behaves this way. Binding a gesture to `Ctrl+Shift+Cmd+4`, which both
Aqua and the macOS screenshot service listen for, produced a screenshot and no
dictation from a single event. The same holds for keystrokes sent by Apple's own
System Events, so the rejection is not specific to this tool.

`config/bindings.md`, generated alongside the plist and untracked, repeats this
next to the current bindings.

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
