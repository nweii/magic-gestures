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
| `hold-left-slide-right` | Hold the left finger still, slide the right one toward or away |
| `hold-right-slide-left` | Hold the right finger still, slide the left one toward or away |
| `one-finger-tap` | Tap with one finger |
| `two-finger-tap` | Tap with two fingers |
| `three-finger-tap` | Tap with three fingers |
| `front-right-tap` | Tap the front right of the surface |
| `one-finger-swipe-left` | Swipe left with one finger |
| `one-finger-swipe-right` | Swipe right with one finger |
| `two-finger-swipe-left` | Swipe left with two fingers |
| `two-finger-swipe-right` | Swipe right with two fingers |
| `three-finger-swipe-left` | Swipe left with three fingers |
| `three-finger-swipe-right` | Swipe right with three fingers |
| `three-finger-swipe-up` | Swipe up with three fingers |
| `three-finger-swipe-down` | Swipe down with three fingers |

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

## What a gesture can send

A keystroke, or a built-in action.

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

Keys: any letter or digit, plus `return` `escape` `tab` `space` `delete`
`forward-delete` `up` `down` `left` `right` `home` `end` `page-up` `page-down`
and `f1` through `f12`.

Aliases: `enter` is `return`, `esc` is `escape`, `backspace` and `del` are
`delete`, `spacebar` is `space`.

Fn cannot be sent. It is a HID usage rather than an ordinary key event, so no
gesture can stand in for an Fn shortcut.

### Actions

`middle-click` `mission-control` `next-tab` `previous-tab` `new-tab`
`close-tab` `reopen-tab` `maximize` `minimize`

`middle-click` posts a real middle-button event, which gives a Magic Mouse a
button it does not otherwise have.

## Settings

| Setting | Value |
|---|---|
| `show-menu-bar-icon` | `true` or `false` |
| `enable-mouse` | `true` or `false` |
| `enable-trackpad` | `true` or `false` |
| `tap-speed` | Seconds a tap may last, default `0.25` |
| `verbose-logging` | `true` logs every gesture and keystroke to Console |

Booleans accept `true/false`, `yes/no`, `on/off`, and `1/0`.

Starting at login is not a setting here. Tick **Open at Login** in the menu bar
item, or run `scripts/install-login-agent.sh`.

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

Free on a default setup: every `hold-` gesture, `three-finger-tap`,
`four-finger-tap`, `index-to-pinky`, `pinky-to-index`, and the
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
