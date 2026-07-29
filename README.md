# MagicGestures

Press a key without taking your hand off the mouse.

MagicGestures turns a finger gesture on a Magic Mouse or Magic Trackpad into a
keyboard shortcut. You hold one finger still on the touch surface and tap beside
it with a second finger. The app sends the keystroke you picked.

By default it sends Return, but you can bind this to any shortcut you want. It runs in the background with no interface and does not affect normal clicks or existing gestures by default.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools
- Python 3

## Install

Build the app and start it:

```bash
python3 ./generate_config.py
./build.sh
./start.sh
```

macOS asks for Accessibility permission the first time. Open System Settings,
then Privacy & Security, then Accessibility. Turn on MagicGestures in the list.

The app is ad-hoc signed and not notarized. If macOS blocks it, hold Control,
click the app, and select Open. You might need to approve it in System Settings > Privacy & Security (scroll down) > "Open anyway" on MagicGestures.

## Default gestures

| Device | Gesture | Sends |
|---|---|---|
| Magic Mouse | Rest your middle finger, tap with your index | Return |
| Magic Trackpad | Rest one finger, tap close to its left with another | Return |

## Change the bindings

Edit the binding tables in `generate_config.py`. Then run:

```bash
python3 ./generate_config.py
./stop.sh && ./start.sh
```

A change to the bindings does not need a new build.

Gesture names must match the names in `src/jitouch/Jitouch/Gesture.m` exactly.
The two devices use different names for the same motion, so a binding on one
device does not reach the other.

Shift, Control, Option, and Command are the modifiers you can send.

## Start at login

```bash
./install-login-agent.sh
```

This writes one file to `~/Library/LaunchAgents`. The file starts the app at
login and restarts it if it stops. To remove the file, run
`./uninstall-login-agent.sh`.

## Limits

Some apps read the keyboard through a CGEventTap and accept only the events that
come from real hardware. These apps ignore the keystrokes that MagicGestures
sends (ex. Aqua Voice). Make sure that an app answers a synthesized
keystroke before you bind a gesture to it.

The Fn key cannot be sent at all.

## How it works

The gesture recognizers come from
[Jitouch](https://github.com/JitouchApp/Jitouch), which reads raw touch data
from the private `MultitouchSupport.framework`. This project keeps that engine,
removes its preference pane, and runs the result as a background agent that
reads a generated configuration file.

`AGENTS.md` covers the build, the configuration model, and the local changes to
the engine.

## License

GPL-3.0, inherited from Jitouch. See `NOTICE` for attribution.
