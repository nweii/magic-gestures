# Trickpad configuration

This file is managed by Trickpad and refreshed when the app starts. If
`AGENTS.local.md` exists beside it, read that file for user-specific instructions.

This folder holds the configuration for Trickpad, a macOS background app
that turns Magic Mouse and Magic Trackpad gestures into shortcuts, actions,
custom URLs, or executable scripts.

- `config.toml` is the only file it reads. Edit it here.
- Save the file, then pick **Reload Settings** in the menu bar to apply it.
- The menu reports loaded bindings and skipped lines. **Diagnostics** can copy
  the running state or open recent logs while troubleshooting.

## Preserve the installation

- Treat `config.toml` as user-owned. Change only what the user requested and
  preserve every unrelated binding and setting.
- Keep the application at its installed path during an update.
- Preview release notes and get approval before replacing the application or
  migrating its configuration.
- Validate `config.toml` before and after an edit or update. Finish when the
  requested behavior is represented by a valid binding and unrelated bindings
  are unchanged.

Source and full documentation: https://github.com/nweii/trickpad

## Format

The file is TOML. Strings are quoted, booleans are `true` or `false`, and `#`
starts a comment outside a string. Invalid TOML rejects the reload. Unknown
settings and gestures are skipped and reported when you pick Reload Settings.

`[MOUSE]`, `[TRACKPAD]`, and `[GENERAL]` headers set what the lines below them
apply to. TOML tables cannot repeat. General settings belong in `[GENERAL]`.

Most bindings use the compact form:

    [MOUSE]

    two-finger-tap = "ctrl+cmd+a"

Use an expanded binding when it needs options:

    [MOUSE]

    two-finger-tap = { action = "ctrl+cmd+a", defer = true }

The single-tap action waits through the Mac's double-click interval. A second
matching tap on the same device cancels it, preserving the double-tap gesture at
the cost of latency on the single tap. `defer` is valid only for tap gestures.

An application name or exact bundle identifier in a device heading limits the
bindings below it to that application:

    [TRACKPAD."Final Cut Pro"]

    three-finger-click = "escape"
    four-finger-tap = "off"

Application bindings override global bindings for the same gesture. `off`
excludes a global binding. An expanded application binding may omit `action` to
inherit the global action and change one option:

    [TRACKPAD."Final Cut Pro"]

    three-finger-click = { haptic = false }

Expanded properties are separated by commas, so a binding may occupy one line
or several. `haptic` is valid only for trackpad bindings and overrides the
global `haptic-feedback` setting for that binding.

One continuous touch sequence can run one kind of configured gesture. A swipe
or hold gesture may repeat while it owns the sequence, but a click, tap, or
different gesture waits until every finger lifts.

## Values

A value is a keystroke, a built-in action, a URL, or an executable script.

Keystrokes are modifiers plus one key. These are equivalent:

    "cmd+shift+a"
    "command-shift-a"
    "⌘⇧A"
    "Cmd Shift A"

| Modifier | Accepted spellings |
|---|---|
| Command | `cmd` `command` `⌘` |
| Control | `ctrl` `control` `⌃` |
| Option | `opt` `option` `alt` `⌥` |
| Shift | `shift` `⇧` |

Modifiers default to the left-side key. Prefix a written name with `left-` or
`right-` when an application distinguishes the two sides:

    "right-control+space"

The prefix works with every written alias, including `right-ctrl`, `right-cmd`,
and `right-alt`. Modifier symbols use the default left side.

Key names: letters, digits, `return` `escape` `tab` `space` `delete`
`forward-delete` `up` `down` `left` `right` `home` `end` `page-up` `page-down`
`f1` through `f12`, and punctuation `[` `]` `-` `=` `;` `'` `,` `.` `/` `\`
and backtick (`` ` ``). Aliases: `enter` is `return`, `esc` is `escape`,
`backspace` and `del` are `delete`, `spacebar` is `space`.

Built-in actions: `middle-click` `mission-control` `next-tab` `previous-tab`
`new-tab` `close-tab` `reopen-tab` `maximize` `minimize`.

Prefix an absolute URL with `url:`. macOS opens it in the application registered
for its scheme. This includes web URLs and app deep links that target a specific
place or action in Raycast, Obsidian, Things, or another app:

    hold-right-tap-left = "url:raycast://extensions/raycast/raycast-ai/ai-chat"
    three-finger-tap = "url:obsidian://daily"
    four-finger-tap = "url:https://example.com/page#section"

Reload Settings reports malformed URLs, unencoded spaces, and malformed percent
escapes. It does not require an application for the scheme to be installed. A
URL fragment remains part of the quoted string; comments follow its closing quote.

A URL binding can contain substitutions that resolve when its gesture fires:

| Substitution | Resolved value |
|---|---|
| `{{clipboard}}` | Clipboard text unchanged |
| `{{clipboard\|urlencode}}` | Clipboard text encoded as one URL component |
| `{{datetime:FORMAT}}` | Current local date and time in an Apple date format |

Examples:

    four-finger-tap = "url:things:///add?title={{clipboard|urlencode}}"
    four-finger-tap = "url:things:///add?title={{clipboard|urlencode}}&when={{datetime:yyyy-MM-dd}}"

Use `urlencode` for clipboard text in a query parameter. Raw clipboard text must
already be safe in its position. Reload Settings reports malformed substitution
syntax. The expanded URL is checked again when the gesture fires, without
logging expanded clipboard contents.

Prefix an executable path with `script:`:

    hold-right-tap-left = "script:~/.config/trickpad/scripts/capture-selection"

The path may begin with `~` or be absolute. It must exist and be executable when
the settings reload. Trickpad launches it directly through its shebang,
uses the script's folder as its working directory, and does not interpret shell
commands, arguments, substitutions, or an interactive shell profile.

## Gestures

A name from one device does nothing on the other.

Mouse: `hold-left-tap-right` `hold-right-tap-left` `one-finger-tap`
`two-finger-tap` `three-finger-tap`
`two-finger-click` `three-finger-click`
`front-right-tap` `one-finger-swipe-left` `one-finger-swipe-right`
`two-finger-swipe-left` `two-finger-swipe-right` `three-finger-swipe-left`
`three-finger-swipe-right` `three-finger-swipe-up` `three-finger-swipe-down`

Magic Mouse physical clicks are experimental and disabled by default. Set
`experimental-mouse-click-gestures = true` under `[GENERAL]` to test them. They
may miss depending on hand placement and how quickly contacts lift. A recognized
binding replaces the normal click. An ambiguous click keeps its normal behavior
and does not fire the binding.

Trackpad: `hold-left-tap-right` `hold-right-tap-left` `hold-slide`
`two-finger-tap` `three-finger-tap` `four-finger-tap` `five-finger-tap` `three-finger-click`
`four-finger-click` `index-to-pinky`
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
| `config-version` | Configuration format used by this file, currently `3` |
| `enable-mouse` | `true` or `false` |
| `enable-trackpad` | `true` or `false` |
| `dominant-hand` | `left` or `right`; mirrors positional recognition for left-handed use, default `right` |
| `tap-speed` | seconds a tap may last, default `0.25` |
| `haptic-feedback` | `true` requests confirmation for configured trackpad gestures, default `true` |
| `experimental-mouse-click-gestures` | `true` enables posture-sensitive Magic Mouse physical-click bindings, default `false` |
| `verbose-logging` | `true` logs every gesture and keystroke to Console |

Booleans are `true` or `false`, following TOML.

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
Keep `config.toml`; the updated app refreshes this file when it starts.

## Hotkey compatibility

Modified shortcuts use explicit modifier presses and releases around the key
event, matching the sequence expected by apps such as Aqua Voice and Wispr
Flow. A shortcut sent through System Events is not an equivalent compatibility
test because it may use a different event sequence. Test the configured gesture
in the target application instead.

The Fn key cannot be sent at all. It is a HID usage rather than an ordinary key
event.
