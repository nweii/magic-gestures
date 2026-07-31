# MagicGestures configuration

This folder holds the configuration for MagicGestures, a macOS background app
that turns Magic Mouse and Magic Trackpad gestures into keystrokes.

- `config.txt` is the only file it reads. Edit it here.
- Save the file, then pick **Reload Settings** in the menu bar to apply it.

Source and full documentation: https://github.com/nweii/magic-gestures

## Format

`setting = value`, one per line. A `#` starts a comment. Unknown settings are
ignored rather than treated as errors.

`[mouse]`, `[trackpad]`, and `[general]` headers set what the lines below them
apply to. A line can also name its device inline, as `mouse.two-finger-tap`,
which works anywhere in the file. Use the inline form when appending a line
programmatically, so the section above it does not change its meaning.

## Values

A value is a keystroke or a built-in action.

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

Built-in actions: `middle-click` `mission-control` `move-resize` `next-tab`
`previous-tab` `new-tab` `close-tab` `reopen-tab` `maximize` `minimize`.

## Gestures

Mouse: `hold-index-tap-middle` `hold-middle-tap-index` `hold-index-slide-middle`
`hold-middle-slide-index` `one-finger-tap` `two-finger-tap` `three-finger-tap`
`front-right-tap` `one-finger-swipe-left` `one-finger-swipe-right`
`two-finger-swipe-left` `two-finger-swipe-right` `three-finger-swipe-left`
`three-finger-swipe-right` `three-finger-swipe-up` `three-finger-swipe-down`

Trackpad: `hold-tap-left` `hold-tap-right` `hold-slide` `two-finger-tap`
`three-finger-tap` `four-finger-tap` `index-to-pinky` `pinky-to-index`
`three-finger-swipe-left` `three-finger-swipe-right` `three-finger-swipe-up`
`three-finger-swipe-down` `four-finger-swipe-left` `four-finger-swipe-right`
`four-finger-swipe-up` `four-finger-swipe-down`

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
| `show-menu-bar-icon` | `true` or `false` |
| `open-at-login` | `true` or `false` |
| `enable-mouse` | `true` or `false` |
| `enable-trackpad` | `true` or `false` |
| `tap-speed` | seconds a tap may last, default `0.25` |
| `verbose-logging` | `true` logs every gesture and keystroke to Console |

Booleans accept `true/false`, `yes/no`, `on/off`, and `1/0`.

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
