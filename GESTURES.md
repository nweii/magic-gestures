# Gesture reference

Everything you can write in `config.txt`. Each device has its own table, and a
name from one table does nothing on the other.

The recognizers are compiled in. A name that is not listed here is skipped
without an error.

Gestures that hold one finger still are named by where the fingers sit, not by
which finger does what. `hold-left-tap-right` means hold a finger and tap to its
right, which on a right hand is the index finger holding and the middle finger
tapping. Either hand works, and either finger can play either part.

## Magic Mouse

| Write this | The motion |
|---|---|
| `hold-left-tap-right` | Hold one finger still, tap to its right with another |
| `hold-right-tap-left` | Hold one finger still, tap to its left with another |
| `one-finger-tap` | Tap with one finger |
| `two-finger-tap` | Tap with two fingers |
| `three-finger-tap` | Tap with three fingers |
| `two-finger-click` | Experimental: physically click with two fingers touching |
| `three-finger-click` | Experimental: physically click with three fingers touching |
| `front-right-tap` | Tap the front right of the surface |
| `one-finger-swipe-left` | Swipe left with one finger |
| `one-finger-swipe-right` | Swipe right with one finger |
| `two-finger-swipe-left` | Swipe left with two fingers |
| `two-finger-swipe-right` | Swipe right with two fingers |
| `three-finger-swipe-left` | Swipe left with three fingers |
| `three-finger-swipe-right` | Swipe right with three fingers |
| `three-finger-swipe-up` | Swipe up with three fingers |
| `three-finger-swipe-down` | Swipe down with three fingers |

Physical clicks ignore narrow contacts at either side and palm contacts at the
rear. Counted fingertips must form one connected cluster; a recognized thumb
does not count toward the gesture. They are disabled by default while
recognition is calibrated across natural grips and hardware. Set
`experimental-mouse-click-gestures = true` under `[general]` to opt in.

## Magic Trackpad

The trackpad recognizes a hold-and-slide in one direction only, so it has one
slide name where the mouse has two.

| Write this | The motion |
|---|---|
| `hold-left-tap-right` | Hold one finger still, tap to its right with another |
| `hold-right-tap-left` | Hold one finger still, tap to its left with another |
| `hold-slide` | Hold one finger still, slide another |
| `two-finger-tap` | Tap with two fingers |
| `three-finger-tap` | Tap with three fingers |
| `four-finger-tap` | Tap with four fingers |
| `five-finger-tap` | Tap with five fingers together |
| `three-finger-click` | Physically click with three fingers touching |
| `four-finger-click` | Physically click with four fingers touching |
| `three-finger-swipe-left` | Swipe left with three fingers |
| `three-finger-swipe-right` | Swipe right with three fingers |
| `three-finger-swipe-up` | Swipe up with three fingers |
| `three-finger-swipe-down` | Swipe down with three fingers |
| `four-finger-swipe-left` | Swipe left with four fingers |
| `four-finger-swipe-right` | Swipe right with four fingers |
| `four-finger-swipe-up` | Swipe up with four fingers |
| `four-finger-swipe-down` | Swipe down with four fingers |
| `index-to-pinky` | Brush your fingers across in sequence, index first |
| `pinky-to-index` | Brush your fingers across in sequence, pinky first |

On both devices, the native click continues and the configured action fires on
release. A drag keeps its native events and does not fire the configured click
action.

One continuous touch sequence can run one kind of configured gesture. A swipe
or hold gesture may repeat while it owns the sequence, but a physical click,
tap, or different gesture will not also run until every finger lifts.

## Application-specific bindings

Put an application name or exact bundle identifier in a device heading:

    [trackpad "Final Cut Pro"]
    three-finger-click = escape
    four-finger-tap = off

The application section overrides global bindings for the same gesture. `off`
excludes a global binding in that application. Sections may repeat, which lets
related application bindings stay together without requiring device prefixes.

## Binding options

Use braces when a binding needs options. Separate properties with commas; line
breaks are optional:

    three-finger-tap {
      action = "ctrl+cmd+a",
      defer = true,
      haptic = false
    }

An application-specific block may omit `action` to inherit the global action:

    [trackpad "Final Cut Pro"]
    three-finger-tap { haptic = false }

`haptic` is valid only for trackpad bindings. It overrides the global
`haptic-feedback` setting for that binding.

### Deferring a tap

Set `defer = true` when the first tap also begins a double-tap gesture in macOS
or another application:

    two-finger-tap { action = "ctrl+cmd+a", defer = true }

Magic Gestures waits through the Mac's double-click interval before sending the
single-tap action. A second matching tap on the same device cancels it. This
preserves the double-tap gesture at the cost of latency on the single tap.

`defer` works only with tap gestures. A swipe, slide, or hold using it is
reported and skipped.

## What a gesture can send

A keystroke, a built-in action, a URL, or an executable script.

### Keystrokes

Modifiers, then one key. These four are the same binding:

    cmd+shift+a
    command-shift-a
    ⌘⇧A
    Cmd Shift A

| Modifier | Write any of |
|---|---|
| Command | `cmd` `command` `⌘` |
| Control | `ctrl` `control` `⌃` |
| Option | `opt` `option` `alt` `⌥` |
| Shift | `shift` `⇧` |

Modifiers default to the left-side key. Prefix a written name with `left-` or
`right-` when an application distinguishes the two sides, such as
`right-control+space`. The prefix works with every written alias, including
`right-ctrl`, `right-cmd`, and `right-alt`. Modifier symbols use the default
left side.

Keys: any letter or digit, plus `return` `escape` `tab` `space` `delete`
`forward-delete` `up` `down` `left` `right` `home` `end` `page-up` `page-down`
and `f1` through `f12`. Punctuation keys: `[` `]` `-` `=` `;` `'` `,` `.`
`/` `\` and backtick (`` ` ``).

Aliases: `enter` is `return`, `esc` is `escape`, `backspace` and `del` are
`delete`, `spacebar` is `space`.

Fn cannot be sent. It is a HID usage rather than an ordinary key event, so no
gesture can stand in for an Fn shortcut.

### Actions

`middle-click` `mission-control` `next-tab` `previous-tab` `new-tab`
`close-tab` `reopen-tab` `maximize` `minimize`

`middle-click` posts a real middle-button event, which gives a Magic Mouse a
button it does not otherwise have.

### URL bindings and app deep links

Prefix an absolute URL with `url:`. macOS opens it in the application registered
for its scheme. A URL binding can open a web URL or an app deep link that targets
a specific place or action in Raycast, Obsidian, Things, or another app:

    hold-right-tap-left = url:raycast://extensions/raycast/raycast-ai/ai-chat
    three-finger-tap = url:obsidian://daily
    four-finger-tap = url:https://example.com/page#section

The URL must include a scheme followed by `:`. Reload Settings reports malformed
URLs, unencoded spaces, and malformed percent escapes. It does not require an
application for the scheme to be installed; macOS resolves the handler when the
gesture fires.

A `#` starts a comment only at the start of a line or after whitespace. This
keeps URL fragments intact. Add whitespace before a trailing comment:

    three-finger-tap = url:obsidian://daily # Open today's daily note

#### Substitutions

A URL binding can contain substitutions that resolve when its gesture fires:

| Substitution | Resolved value |
|---|---|
| `{{clipboard}}` | Clipboard text unchanged |
| `{{clipboard\|urlencode}}` | Clipboard text encoded as one URL component |
| `{{datetime:FORMAT}}` | Current local date and time in the given Apple date format |

For example:

    four-finger-tap = url:things:///add?title={{clipboard|urlencode}}
    four-finger-tap = url:things:///add?title={{clipboard|urlencode}}&when={{datetime:yyyy-MM-dd}}

Use `urlencode` for clipboard text placed in a query parameter. It escapes
characters such as spaces, `&`, `=`, `/`, and `?` so the clipboard cannot change
the URL's structure. Use raw `{{clipboard}}` only when the copied text is already
safe in that position.

An empty clipboard resolves to an empty value. Reload Settings reports unknown
substitutions and filters, unmatched braces, empty date formats, and unmatched
quotes in date formats. The expanded URL is checked again when the gesture fires.
If it is invalid, nothing opens and Console records the problem without the
expanded clipboard contents.

### Scripts

Prefix an executable path with `script:`:

    hold-right-tap-left = script: ~/.config/magic-gestures/scripts/capture-selection

The path may begin with `~` or be absolute. It must exist and be executable when
the settings reload. Magic Gestures launches it directly through its shebang,
uses the script's folder as its working directory, and does not wait for it to
finish. It does not interpret shell commands, arguments, substitutions, or an
interactive shell profile. Console records launch failures and nonzero exits.

## Settings

| Setting | Value |
|---|---|
| `config-version` | Configuration format used by this file, currently `2` |
| `enable-mouse` | `true` or `false` |
| `enable-trackpad` | `true` or `false` |
| `dominant-hand` | `left` or `right`; mirrors positional recognition for left-handed use, default `right` |
| `tap-speed` | Seconds a tap may last, default `0.25` |
| `haptic-feedback` | `true` requests confirmation for configured trackpad gestures, default `true` |
| `experimental-mouse-click-gestures` | `true` enables posture-sensitive Magic Mouse physical-click bindings, default `false` |
| `verbose-logging` | `true` logs every gesture and keystroke to Console |

Booleans accept `true/false`, `yes/no`, `on/off`, and `1/0`.

Hiding the menu bar icon is not a setting here either. Use System Settings >
Menu Bar; gestures keep working without it.

Starting at login is not a setting here. Tick **Open at Login** in the menu bar
item. From a source checkout, `scripts/install-login-agent.sh` does the same
thing from the shell.

## Conflicts with built-in macOS gestures

macOS claims several of these motions first, in System Settings under Trackpad
and Mouse. When both want the same motion, both fire.

Check your own settings before binding, because the finger counts are
adjustable. A default trackpad puts these out of reach:

| Motion | Built-in use |
|---|---|
| `four-finger-swipe-up` | Mission Control |
| `four-finger-swipe-down` | App Exposé |
| `four-finger-swipe-left`, `four-finger-swipe-right` | Swipe between full-screen apps |

Mission Control and App Exposé can be moved between three and four fingers, so a
trackpad set to three fingers takes the `three-finger-swipe` names out instead
and frees the four-finger ones.

On the Magic Mouse, one-finger and two-finger horizontal motion drives scrolling
and page navigation, which is why `one-finger-swipe-left` and
`one-finger-swipe-right` fight the system.

Free on a default setup: every `hold-` gesture, multi-finger tap or click,
`index-to-pinky`, `pinky-to-index`, and the
`three-finger-swipe` names.

## Choosing one

The `hold-` gestures hold one finger still while another taps or slides. A
resting hand does not produce that shape and macOS binds nothing to it, so they
stay clear on both counts. Bind those for anything you would regret firing by
accident.

A tap fires while your hand rests on the surface. A swipe competes with
scrolling. Both are fine for something harmless.

## Where these come from

The recognizers are [Jitouch](https://github.com/JitouchApp/Jitouch), vendored
under `src/jitouch/`. `src/Config.m` maps the names above to the engine's
internal names, which are longer and encode detail a hand does not distinguish,
such as how far apart two fingers land.
