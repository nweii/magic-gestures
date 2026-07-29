# Gesture vocabulary

Every gesture name that the engine recognizes. Bind any of these in
`generate_config.py`. The names must match exactly, and each device has its own
list, so a name from one table does nothing on the other.

You cannot invent a gesture. The recognizers are compiled in, and a name that is
not on this list is silently ignored.

## Reading the names

| Term | Meaning |
|---|---|
| Fix | Hold this finger still while another one moves or taps |
| Tap | Touch and lift |
| Slide | Touch and move, holding contact |
| Swipe | Move several fingers together across the surface |
| Near, Far | How far the tapping finger lands from the held one |
| In, Out | Toward or away from the held finger |

Two-finger swipes are missing from both lists because macOS already uses that
motion for scrolling.

## Magic Mouse

Taps:

- `One-Finger Tap`
- `Two-Finger Tap`
- `Right-Front Tap`
- `Thumb`

Swipes and pinches:

- `One-Swipe-Left`, `One-Swipe-Right`
- `Three-Swipe-Up`, `Three-Swipe-Down`, `Three-Swipe-Left`, `Three-Swipe-Right`
- `Pinch In`, `Pinch Out`

Fix-taps, which hold one finger still and tap with another:

- `Index-Fix Middle-Near-Tap`, `Index-Fix Middle-Far-Tap`
- `Middle-Fix Index-Near-Tap`, `Middle-Fix Index-Far-Tap`

Fix-slides, which hold one finger still and drag with another:

- `Index-Fix Middle-Slide-In`, `Index-Fix Middle-Slide-Out`
- `Middle-Fix Index-Slide-In`, `Middle-Fix Index-Slide-Out`
- `Two-Fix One-Slide-Up`, `Two-Fix One-Slide-Down`
- `Two-Fix One-Slide-Left`, `Two-Fix One-Slide-Right`

## Magic Trackpad

Taps:

- `Three-Finger Tap`
- `Four-Finger Tap`

Swipes and pinches:

- `Three-Swipe-Up`, `Three-Swipe-Down`, `Three-Swipe-Left`, `Three-Swipe-Right`
- `Four-Swipe-Up`, `Four-Swipe-Down`, `Four-Swipe-Left`, `Four-Swipe-Right`
- `Three-Finger Pinch-In`, `Three-Finger Pinch-Out`

Fix-taps:

- `One-Fix Left-Tap`, `One-Fix Right-Tap`
- `Two-Fix Index-Double-Tap`, `Two-Fix Middle-Double-Tap`,
  `Two-Fix Ring-Double-Tap`

Fix-slides:

- `One-Fix Two-Slide-Up`, `One-Fix Two-Slide-Down`
- `One-Fix-Press Two-Slide-Up`, `One-Fix-Press Two-Slide-Down`
- `One-Fix Three-Slide`
- `Two-Fix One-Slide-Up`, `Two-Fix One-Slide-Down`
- `Two-Fix One-Slide-Left`, `Two-Fix One-Slide-Right`

Finger runs:

- `Index-To-Pinky`, `Pinky-To-Index`

## Choosing one

A swipe or a plain tap competes with motions your hand makes anyway. A
three-finger swipe fires while you scroll with three fingers resting. A
one-finger tap fires when you set your hand down.

Fix gestures hold one finger still while another moves, which a resting hand
does not produce. Bind those to anything you would regret firing by accident.

## Where these come from

This list is the set of names passed to `dispatchCommand` in
`src/jitouch/Jitouch/Gesture.m`. To confirm it against the source:

```bash
grep -oE 'dispatchCommand\(@"[^"]+", MAGICMOUSE' src/jitouch/Jitouch/Gesture.m | sort -u
grep -oE 'dispatchCommand\(@"[^"]+", TRACKPAD' src/jitouch/Jitouch/Gesture.m | sort -u
```
