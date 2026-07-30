#!/usr/bin/env python3
import plistlib
from pathlib import Path


ROOT = Path(__file__).resolve().parent
CONFIG_DIR = ROOT / "config"
CONFIG_PATH = CONFIG_DIR / "MagicGestures.plist"
SUMMARY_PATH = CONFIG_DIR / "bindings.md"


CMD = 1 << 20
SHIFT = 1 << 17
ALT = 1 << 19
CTRL = 1 << 18


def action(gesture: str, command: str) -> dict:
    return {
        "Gesture": gesture,
        "Command": command,
        "IsAction": True,
        "ModifierFlags": 0,
        "KeyCode": 0,
        "Enable": True,
    }


def shortcut(gesture: str, label: str, keycode: int, modifiers: int) -> dict:
    return {
        "Gesture": gesture,
        "Command": label,
        "IsAction": False,
        "ModifierFlags": modifiers,
        "KeyCode": keycode,
        "Enable": True,
    }


def app_entry(name: str, path: str, gestures: list[dict]) -> dict:
    return {"Application": name, "Path": path, "Gestures": gestures}


RETURN_KEYCODE = 36  # Return, sent bare to submit the focused field


def build_magic_mouse_commands() -> list[dict]:
    # Hold the middle finger still and tap beside it with the index finger. A
    # resting hand cannot produce that, unlike a plain tap or a swipe, which is
    # what makes a fix-tap safe to bind.
    #
    # Near and far variants fire the same shortcut, so the gap between the two
    # fingers does not have to be precise.
    return [
        app_entry(
            "All Applications",
            "",
            [
                shortcut("Middle-Fix Index-Near-Tap", "Submit", RETURN_KEYCODE, 0),
                shortcut("Middle-Fix Index-Far-Tap", "Submit", RETURN_KEYCODE, 0),
            ],
        ),
    ]


def build_trackpad_commands() -> list[dict]:
    # The same action as the mouse, so one muscle memory covers both devices.
    # The trackpad names gestures by where the tap lands rather than by finger,
    # so the equivalent of "hold middle, tap index" is a tap to the left of the
    # anchor.
    #
    # Bindings add behavior rather than replacing it, so nothing here overrides
    # a click that System Settings already owns.
    return [
        app_entry(
            "All Applications",
            "",
            [
                shortcut("One-Fix Left-Tap", "Submit", RETURN_KEYCODE, 0),
            ],
        )
    ]


def build_recognition_commands() -> list[dict]:
    return [app_entry("All Applications", "", [])]


def write_summary() -> None:
    text = """# Gesture bindings

Submit the focused field from the mouse or trackpad, without reaching for the
keyboard. Return is far from a mouse hand and comes up constantly while
pointing at something.

Hold the middle finger still on the mouse and tap beside it with the index
finger. On the trackpad, hold a finger and tap to its left.

Holding one finger still while tapping with another cannot be produced by a
resting hand, which is what makes it safe to bind. Near and far tap positions
both fire on the mouse, so finger spacing does not have to be precise.

Two constraints shape what can be bound here:

- The Fn key cannot be synthesized. It is a HID usage rather than an ordinary
  key event, so a gesture can never stand in for an Fn-based binding.
- Bindings add behavior rather than replacing it. Tap-to-click, secondary
  click, and the built-in swipes keep working the way System Settings has
  them.

## Applications that reject synthesized keystrokes

Some applications watch the keyboard through a CGEventTap and ignore key events
that did not originate from real hardware. They cannot be driven from here, and
no configuration change fixes it. Verify a target responds to a synthesized
keystroke before building bindings around it.

Aqua Voice is one such application, which is why dictation is not bound here.
This was isolated by binding a gesture to Ctrl+Shift+Cmd+4, a shortcut both
Aqua and the macOS screenshot service listen on: firing it produced a
screenshot and no dictation, from a single event.

Getting past that needs a channel the application accepts. Aqua exposes no
Shortcuts actions, and its aquavoice:// scheme handles only captions sessions,
Slack status, onboarding, and auth tokens. The remaining routes are an official
trigger added by its developers, or injecting through a virtual HID device,
which requires a DriverKit system extension and a root helper process.

## Trackpad

Both devices are enabled and carry the same binding. The trackpad names its
gestures by where the tap lands rather than by which finger is which, so
"hold middle, tap index" becomes "hold a finger, tap to its left".
"""
    SUMMARY_PATH.write_text(text)


def main() -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)

    payload = {
        "Revision": 26,
        "enAll": 1,
        "ClickSpeed": 0.25,
        "Sensitivity": 4.6666,
        "ShowIcon": 0,
        "LogLevel": 1,  # Raise to 2 to log every dispatched gesture and shortcut.
        "enTPAll": 1,
        "Handed": 0,
        "enMMAll": 1,
        "MMHanded": 0,
        "enCharRegTP": 0,
        "enCharRegMM": 0,
        "charRegMouseButton": 0,
        "charRegIndexRingDistance": 0.33,
        "enOneDrawing": 0,
        "enTwoDrawing": 1,
        "TrackpadCommands": build_trackpad_commands(),
        "MagicMouseCommands": build_magic_mouse_commands(),
        "RecognitionCommands": build_recognition_commands(),
    }

    with CONFIG_PATH.open("wb") as f:
        plistlib.dump(payload, f, sort_keys=False)

    write_summary()
    print(CONFIG_PATH)


if __name__ == "__main__":
    main()
