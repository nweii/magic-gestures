# Magic Gestures

Press a key without taking your hand off the mouse.

Magic Gestures turns finger gestures on a Magic Mouse or Magic Trackpad into
keyboard shortcuts. Each device supports sixteen gestures, including taps,
swipes, and motions where you hold one finger still while another taps or
slides. Each gesture can send any supported shortcut.

By default, holding your middle finger on the device and tapping to its left
with your index finger sends Return. The app runs in the background with a menu
bar item and does not affect normal clicks or existing gestures.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools, to build from source

## Install

Choose one of the three installation methods below. The first time you run the
app, macOS asks for Accessibility permission so it can send keystrokes. Open
System Settings > Privacy & Security > Accessibility and turn on Magic Gestures.
The app starts automatically when you log in. Turn off **Open at Login** from
the menu bar item if you do not want this.

### From the release zip

Download the zip from the [Releases
page](https://github.com/nweii/magic-gestures/releases), unzip it, and drag
`MagicGestures.app` wherever you keep apps (`/Applications` works). Open it.

The app is ad-hoc signed and not notarized, so macOS blocks it the first time
you open it. Click **Done**, then open System Settings > Privacy & Security.
Scroll to the message that MagicGestures was blocked, click **Open Anyway**,
authenticate, and click **Open** in the final prompt.

### Build from source

```bash
./scripts/build.sh
./scripts/start.sh
```

This builds the app in the project folder and launches it. A local build does
not require the Gatekeeper steps above, but it still needs Accessibility
permission.

### Let an agent set it up

An agent can install the app, help choose gestures, and edit the configuration
for the apps you use.

Paste this into Claude Code, or any coding agent:

```text
Set up https://github.com/nweii/magic-gestures for me. Install it from the latest release zip, or clone and build from source if that suits my machine better. Ask me what I want a gesture to do, then suggest gestures from the project's GESTURES.md that fit it. Then edit the settings file the app creates at ~/.config/magic-gestures/config.txt, and tell me what I have to approve in System Settings.
```

For a zip install, you need to complete the Gatekeeper steps yourself. Building
from source requires the Xcode Command Line Tools but skips those steps.

## Default gestures

| Device | Gesture | Write this | Sends |
|---|---|---|---|
| Magic Mouse | Rest your middle finger, tap to its left with your index | `hold-right-tap-left` | Return |
| Magic Trackpad | Rest one finger, tap to its left with another | `hold-right-tap-left` | Return |

## Change the gestures

The gesture configuration is a text file. Open it from **Edit Settings** in the
menu bar item, or edit it directly:

```
~/.config/magic-gestures/config.txt
```

The folder also contains an `AGENTS.md` that explains the format to coding
agents. The configuration looks like this:

```
[mouse]
hold-right-tap-left = return
two-finger-tap = middle-click

[trackpad]
hold-left-tap-right = cmd+shift+a
```

Pick **Reload Settings** from the menu bar to apply a change. No rebuild is
needed. **Current Gestures** shows what is bound right now.

To have a coding agent make the change, pick one under **Change Settings with
Agent**. It opens in the settings folder with the notes already there.

See `GESTURES.md` for the gesture names available on each device, supported keys
and modifiers, built-in actions, and motions already used by macOS.

## Uninstall

### From a zip install

Untick **Open at Login** if it is on, then Quit from the menu bar item. Drag
`MagicGestures.app` to the Trash. Delete `~/.config/magic-gestures` if you do
not want your settings back later, and remove Magic Gestures from System
Settings > Privacy & Security > Accessibility.

### From a source checkout

```bash
./scripts/uninstall.sh
```

This stops the app, removes the login item, and deletes the built app. Your
settings in `~/.config/magic-gestures/` are kept; pass `--all` to remove those
too.

The script cannot remove the Accessibility entry or the project folder. Remove
Magic Gestures from System Settings > Privacy & Security > Accessibility, then
delete the project folder if you no longer need it.

## Privacy

Magic Gestures needs Accessibility permission because macOS requires it for
apps that send keystrokes to other apps.

The app has no telemetry, analytics, crash reporting, or network code. It makes
no outbound connections.

It does not read your keystrokes. The event tap it installs watches mouse and
scroll events so it can tell a gesture from a normal click. Keyboard events are
not in the set it listens for.

Touch data from the mouse and trackpad stays in memory and is never written
anywhere.

Outside its own folder, Magic Gestures writes to two places. It creates
`~/.config/magic-gestures/` on first run and puts your `config.txt` and an
`AGENTS.md` describing the format there. Picking a coding agent under **Change
Settings with Agent** adds a `configure-with-agent.command` script to that same
folder and runs it. Turning on Open at Login writes one launchd plist to
`~/Library/LaunchAgents`.

## Limits

Some apps read the keyboard through a CGEventTap and accept only events from
physical hardware. These apps, including Aqua Voice, ignore keystrokes from
Magic Gestures. Test the target app with a synthesized keystroke before binding
a gesture to it.

The Fn key cannot be sent at all.

## Relation to Jitouch

Jitouch is a full gesture app with a catalog of actions built in. It switches
browser tabs, snaps windows, opens Mission Control, and recognizes letters you
draw on the trackpad. You pick from that catalog in a preference pane.

Magic Gestures keeps Jitouch's recognizers but lets each gesture send a
configurable keyboard shortcut. Jitouch's built-in actions remain available.
It works with apps that accept synthesized hotkeys, and a menu bar item replaces
the preference pane.

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
