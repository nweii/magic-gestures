# Magic Gestures

Trigger a shortcut or open a URL without taking your hand off the mouse.

Magic Gestures turns finger gestures on a Magic Mouse or Magic Trackpad into
keyboard shortcuts, built-in actions, or custom URLs. Each device supports
sixteen gestures, including taps, swipes, and motions where you hold one finger
still while another taps or slides. It requires macOS 13 or later.

By default, holding your middle finger on the device and tapping to its left
with your index finger sends Return. The app runs in the background with a menu
bar item and does not affect normal clicks or existing gestures.

## Features

- **Flexible bindings.** Send keyboard shortcuts, run built-in actions such as
  middle click or Mission Control, or open custom URLs.
- **App deep links.** Target actions in Raycast, Obsidian, Things, and other
  apps with URL schemes. Clipboard and date/time substitutions can fill in
  parameters when the gesture fires.
- **Sixteen gestures per device.** Bind taps, swipes, and deliberate motions on
  a Magic Mouse and Magic Trackpad independently.
- **Agent-native configuration.** Open a coding agent from the menu bar with
  the configuration file and current instructions ready. The agent can help
  choose a gesture, construct a deep link, or update the installation.
- **Keeps existing gestures intact.** Magic Gestures adds bindings without
  replacing the clicks, scrolling, and gestures configured in macOS.

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

Source builds require Xcode Command Line Tools.

```bash
./scripts/build.sh
./scripts/start.sh
```

This builds the app in the project folder and launches it. A local build does
not require the Gatekeeper steps above, but it still needs Accessibility
permission.

To update a source checkout later:

```bash
./scripts/update.sh
```

The script requires a clean checkout, previews incoming commits, asks before
installing them, runs the checks, rebuilds, and restarts the app. Fetching the
public repository does not require GitHub CLI or GitHub authentication.

### Let an agent set it up

An agent can install the app, help choose gestures, and edit the configuration
for the apps you use. It can help decide whether a keyboard shortcut, built-in
action, or URL binding best fits each request. If a URL binding fits, it can
construct the app deep link and encode its parameters.

Paste this into Claude Code, or any coding agent:

```text
Set up https://github.com/nweii/magic-gestures for me. Install it from the latest release zip, or clone and build from source if that suits my machine better. Ask me what I want a gesture to do, then suggest gestures from the project's GESTURES.md that fit it. A binding can send a shortcut, run a built-in action, or open a URL. Help me choose the simplest suitable form. If a URL binding fits my request, help construct the app deep link, including clipboard or date/time substitutions when useful. Then edit the settings file the app creates at ~/.config/magic-gestures/config.txt, and tell me what I have to approve in System Settings.
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
three-finger-tap = url:obsidian://daily
four-finger-tap = url:things:///add?title={{clipboard|urlencode}}
```

Pick **Reload Settings** from the menu bar to apply a change. No rebuild is
needed. **Current Gestures** shows what is bound right now.

To have a coding agent make the change, pick one under **Manage with Agent**. It
opens in the settings folder with the current instructions already there.

See `GESTURES.md` for the gesture names available on each device, supported keys
and modifiers, built-in actions, custom URLs, URL substitutions, and motions
already used by macOS.

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

The app has no telemetry, analytics, or crash reporting. It makes no network
requests itself. A URL binding asks macOS to open that URL in its registered
application, which may then use the network.

It does not read your keystrokes. The event tap it installs watches mouse and
scroll events so it can tell a gesture from a normal click. Keyboard events are
not in the set it listens for.

Touch data from the mouse and trackpad stays in memory and is never written
anywhere.

Outside its own folder, Magic Gestures writes to two places. It creates
`~/.config/magic-gestures/` on first run and puts your `config.txt` and an
`AGENTS.md` describing the installed version there. The app refreshes that file
when it starts and preserves `config.txt`. Picking a coding agent under **Manage
with Agent** adds a `manage-with-agent.command` script to that same folder and
runs it. Turning on Open at Login writes one launchd plist to
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
configurable keyboard shortcut or open a custom URL. Jitouch's built-in actions
remain available. It works with apps that accept synthesized hotkeys, and a menu
bar item replaces the preference pane.

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
