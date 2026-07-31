# Magic Gestures

Press a key without taking your hand off the mouse.

Magic Gestures turns a finger gesture on a Magic Mouse or Magic Trackpad into a
keyboard shortcut. You hold one finger still on the touch surface and tap beside
it with a second finger. The app sends the keystroke you picked.

By default it sends Return, but you can bind this to any shortcut you want. It
runs in the background from a menu bar item, and does not affect normal clicks
or existing gestures by default.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools

## Install

Build the app and start it:

```bash
./scripts/build.sh
./scripts/start.sh
```

macOS asks for Accessibility permission the first time. Open System Settings,
then Privacy & Security, then Accessibility. Turn on Magic Gestures in the list.

The app is ad-hoc signed and not notarized. If macOS blocks it, hold Control,
click the app, and select Open. You might need to approve it in System Settings >
Privacy & Security (scroll down) > "Open anyway" on Magic Gestures.

## Or let an agent set it up

Paste this into Claude Code, or any coding agent, from the folder where you keep
your projects:

```text
Clone https://github.com/nweii/magic-gestures and set it up for me.
Read AGENTS.md first. Ask me which gesture I want and which keyboard shortcut
it should send. Build it, start it, then edit the settings file it creates
at ~/.config/magic-gestures/config.txt.
Read GESTURES.md and let me pick from the gestures listed there.
Tell me what I have to approve in System Settings.
```

`AGENTS.md` covers the build and the configuration model. `GESTURES.md` lists
every gesture you can bind.

## Default gestures

| Device | Gesture | Write this | Sends |
|---|---|---|---|
| Magic Mouse | Rest your middle finger, tap to its left with your index | `hold-right-tap-left` | Return |
| Magic Trackpad | Rest one finger, tap to its left with another | `hold-right-tap-left` | Return |

## Change the gestures

Gestures live in a text file. Open it from the menu bar item under **Edit Settings**, or edit it directly:

```
~/.config/magic-gestures/config.txt
```

That folder also gets an `AGENTS.md` describing the format, so a coding agent
opened there has what it needs without the source. Lines look like this:

```
[mouse]
hold-right-tap-left = return
two-finger-tap = middle-click

[trackpad]
hold-left-tap-right = cmd+shift+a
```

Pick **Reload Settings** from the menu bar to apply a change. No rebuild is
needed. **Current Gestures** shows what is bound right now.

To have a coding agent make the change, pick one under **Change Gestures with
Agent**. It opens in the settings folder with the notes already there.

`GESTURES.md` is the full reference: every gesture name by device, every key
and modifier you can send, the built-in actions, and which motions macOS has
already claimed.

## Start at login

Tick **Open at Login** in the menu bar item, or run:

```bash
./scripts/install-login-agent.sh
```

This writes one file to `~/Library/LaunchAgents`. The file starts the app at
login and restarts it if it stops. To remove the file, run
`./scripts/uninstall-login-agent.sh`.

## Uninstall

```bash
./scripts/uninstall.sh
```

This stops the app, removes the login item, and deletes the built app. Your
settings in `~/.config/magic-gestures/` are kept; pass `--all` to remove those
too.

Two steps are left over, because no script can do them: remove Magic Gestures
from System Settings > Privacy & Security > Accessibility, and delete the
project folder.

## Privacy

Magic Gestures needs Accessibility permission to send keystrokes. That permission
is what lets any app post keyboard events to other apps.

It sends no data anywhere. There is no telemetry, no analytics, no crash
reporting, and no network code of any kind. The app makes no outbound
connections.

It does not read your keystrokes. The event tap it installs watches mouse and
scroll events so it can tell a gesture from a normal click. Keyboard events are
not in the set it listens for.

Touch data from the mouse and trackpad stays in memory and is never written
anywhere.

Outside its own folder, Magic Gestures writes to two places. It creates
`~/.config/magic-gestures/` on first run and puts your `config.txt` and an
`AGENTS.md` describing the format there. Picking a coding agent under **Change
Gestures with Agent** adds a `configure-with-agent.command` script to that same
folder and runs it. Turning on Open at Login writes one launchd plist to
`~/Library/LaunchAgents`.

## Limits

Some apps read the keyboard through a CGEventTap and accept only the events that
come from real hardware. These apps ignore the keystrokes that Magic Gestures
sends (ex. Aqua Voice). Make sure that an app answers a synthesized keystroke
before you bind a gesture to it.

The Fn key cannot be sent at all.

## Relation to Jitouch

Jitouch is a full gesture app with a catalog of actions built in. It switches
browser tabs, snaps windows, opens Mission Control, and recognizes letters you
draw on the trackpad. You pick from that catalog in a preference pane.

Magic Gestures keeps Jitouch's recognizers and drops the catalog, so a gesture
sends the keyboard shortcut you name instead of choosing from a fixed list. That
covers any app with a hotkey. A menu bar item replaces the preference pane.

## How it works

The gesture recognizers come from
[Jitouch](https://github.com/JitouchApp/Jitouch), which reads raw touch data
from the private `MultitouchSupport.framework`. This project keeps that engine,
removes its preference pane, and runs the result as a background agent that
reads a text configuration file.

`AGENTS.md` covers the build, the configuration model, and the local changes to
the engine.

## AI usage

Claude Code wrote most of the code and documentation here, working from my
direction. I decided what to build and what to leave out, chose the gesture and
binding design, tested every change on my own hardware, and rejected the
approaches that did not hold up. The gesture recognizers are Jitouch's, changed
in two places.

## License

GPL-3.0, inherited from Jitouch. See `NOTICE.txt` for attribution.
