# MagicGestures

Press a key without taking your hand off the mouse.

MagicGestures turns a finger gesture on a Magic Mouse or Magic Trackpad into a
keyboard shortcut. You hold one finger still on the touch surface and tap beside
it with a second finger. The app sends the keystroke you picked.

By default it sends Return. Bind it to any shortcut you want.

It runs in the background with no interface. Clicking is unchanged.

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
click the app, and select Open.

## Default gestures

| Device | Gesture | Sends |
|---|---|---|
| Magic Mouse | Hold the middle finger still, tap with the index finger | Return |
| Magic Trackpad | Hold one finger still, tap to its left | Return |

On the Magic Mouse, the distance between the two fingers does not matter. The
tap must finish in 0.25 seconds, and both fingers must stay still.

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
sends. Aqua Voice is one example. Make sure that an app answers a synthesized
keystroke before you bind a gesture to it.

The Fn key cannot be sent at all. Fn is a HID usage rather than a normal key
event.

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
