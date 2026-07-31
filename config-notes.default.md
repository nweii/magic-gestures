# Magic Gestures configuration

This file is managed by Magic Gestures and refreshed when the app starts. If
`AGENTS.local.md` exists beside it, read that file for user-specific instructions.

This folder holds the configuration for Magic Gestures, a macOS background app
that turns Magic Mouse and Magic Trackpad gestures into shortcuts, actions, or
custom URLs.

- `config.txt` is the only file it reads. Edit it here.
- Save the file, then pick **Reload Settings** in the menu bar to apply it.

## Preserve the installation

- Treat `config.txt` as user-owned. Change only what the user requested and
  preserve every unrelated binding and setting.
- Keep the application at its installed path during an update.
- Preview release notes and get approval before replacing the application or
  migrating its configuration.
- Validate `config.txt` before and after an edit or update. Finish when the
  requested behavior is represented by a valid binding and unrelated bindings
  are unchanged.

Source and full documentation: https://github.com/nweii/magic-gestures

## Format

`setting = value`, one per line. A `#` at the start of a line or after whitespace
starts a comment. Unknown or malformed lines are skipped and reported when you
pick Reload Settings.

`[mouse]`, `[trackpad]`, and `[general]` headers set what the lines below them
apply to. Use sections when editing related bindings by hand. An agent or script
can append one binding as `mouse.two-finger-tap` or `trackpad.two-finger-tap`,
which overrides the surrounding section. General settings belong in `[general]`.

## Values

A value is a keystroke, a built-in action, or a URL.

Keystrokes are modifiers plus one key. These are equivalent:

    cmd+shift+a
    command-shift-a
    ⌘⇧A
    Cmd Shift A

| Modifier | Accepted spellings |
|---|---|
| Command | `cmd` `command` `⌘` |
| Control | `ctrl` `control` `⌃` |
| Option | `opt` `option` `alt` `⌥` |
| Shift | `shift` `⇧` |

Key names: letters, digits, `return` `escape` `tab` `space` `delete`
`forward-delete` `up` `down` `left` `right` `home` `end` `page-up` `page-down`
`f1` through `f12`. Aliases: `enter` is `return`, `esc` is `escape`,
`backspace` and `del` are `delete`.

Built-in actions: `middle-click` `mission-control` `next-tab` `previous-tab`
`new-tab` `close-tab` `reopen-tab` `maximize` `minimize`.

Prefix an absolute URL with `url:`. macOS opens it in the application registered
for its scheme. This includes web URLs and app deep links that target a specific
place or action in Raycast, Obsidian, Things, or another app:

    hold-right-tap-left = url:raycast://extensions/raycast/raycast-ai/ai-chat
    three-finger-tap = url:obsidian://daily
    four-finger-tap = url:https://example.com/page#section

Reload Settings reports malformed URLs, unencoded spaces, and malformed percent
escapes. It does not require an application for the scheme to be installed. A
URL fragment can contain `#`; add whitespace before a trailing comment.

A URL binding can contain substitutions that resolve when its gesture fires:

| Substitution | Resolved value |
|---|---|
| `{{clipboard}}` | Clipboard text unchanged |
| `{{clipboard\|urlencode}}` | Clipboard text encoded as one URL component |
| `{{datetime:FORMAT}}` | Current local date and time in an Apple date format |

Examples:

    hold-left-slide-right = url:things:///add?title={{clipboard|urlencode}}
    four-finger-tap = url:things:///add?title={{clipboard|urlencode}}&when={{datetime:yyyy-MM-dd}}

Use `urlencode` for clipboard text in a query parameter. Raw clipboard text must
already be safe in its position. Reload Settings reports malformed substitution
syntax. The expanded URL is checked again when the gesture fires, without
logging expanded clipboard contents.

## Gestures

A name from one device does nothing on the other.

Mouse: `hold-left-tap-right` `hold-right-tap-left` `hold-left-slide-right`
`hold-right-slide-left` `one-finger-tap` `two-finger-tap` `three-finger-tap`
`front-right-tap` `one-finger-swipe-left` `one-finger-swipe-right`
`two-finger-swipe-left` `two-finger-swipe-right` `three-finger-swipe-left`
`three-finger-swipe-right` `three-finger-swipe-up` `three-finger-swipe-down`

Trackpad: `hold-left-tap-right` `hold-right-tap-left` `hold-slide`
`two-finger-tap` `three-finger-tap` `four-finger-tap` `index-to-pinky`
`pinky-to-index` `three-finger-swipe-left` `three-finger-swipe-right`
`three-finger-swipe-up` `three-finger-swipe-down` `four-finger-swipe-left`
`four-finger-swipe-right` `four-finger-swipe-up` `four-finger-swipe-down`

The `hold-` names describe where the fingers sit, not which finger does what.
`hold-left-tap-right` means hold a finger and tap to its right, which on a right
hand is the index finger holding and the middle finger tapping. Either hand
works.

Holding one finger still while another taps or slides cannot be produced by a
resting hand, and macOS binds nothing to that shape. Bind those for anything
that would be disruptive to fire by accident.

macOS already claims several motions, including four-finger swipes for Mission
Control, App Exposé, and full-screen app switching. Binding one of those fires
both. The finger counts are adjustable in System Settings, so check there before
assuming a motion is free.

## Behavior settings

| Setting | Value |
|---|---|
| `config-version` | Configuration format used by this file, currently `1` |
| `enable-mouse` | `true` or `false` |
| `enable-trackpad` | `true` or `false` |
| `tap-speed` | seconds a tap may last, default `0.25` |
| `verbose-logging` | `true` logs every gesture and keystroke to Console |

Booleans accept `true/false`, `yes/no`, `on/off`, and `1/0`.

Hiding the menu bar icon is not a setting here either. Use System Settings >
Menu Bar; gestures keep working without it.

Starting at login is not a setting here. It is the **Open at Login** item in the
menu bar, which writes a launchd file.

## Updating

The prompt that opened this agent names the running app path. If that app is
inside a source checkout containing `scripts/update.sh`, use that script. It
previews incoming commits, requires approval, validates the source, rebuilds,
and restarts the app.

A copied release app currently updates by replacing the app with a newer release
at the same path. Show the release notes and get approval before replacement.
Keep `config.txt`; the updated app refreshes this file when it starts.

## Applications that ignore synthesized keystrokes

Some applications watch the keyboard through a `CGEventTap` and accept only
events that came from real hardware. A gesture cannot drive those, and no
configuration changes it.

Test an application before binding a gesture to it. Set the hotkey in that
application, then send the same keystroke from Terminal:

    osascript -e 'tell application "System Events" to keystroke "a" using {command down, shift down}'

If it responds when you type the keys but not when Terminal sends them, a
gesture will not reach it either.

The Fn key cannot be sent at all. It is a HID usage rather than an ordinary key
event.
