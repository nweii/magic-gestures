<!-- Records user-visible Magic Gestures releases in reverse chronological order. -->

# Changelog

## 0.5.0

Released 2026-08-02.

### Added

- Added optional `left-` and `right-` prefixes for Shift, Control, Option, and
  Command. Unspecified modifiers continue to use the left-side key.
- Added diagnostics for Magic Mouse physical-click correlation to verbose logs.
- Added experimental Magic Mouse two- and three-finger physical-click bindings.
  They are disabled by default and require
  `experimental-mouse-click-gestures = true` under `[general]`.

### Fixed

- Correlated physical clicks with touch frames that arrive before mouse-down,
  after mouse-down, or just after mouse-up.
- Prevented brief contact dropouts, trackpad drags, palms, thumbs, and isolated
  edge contacts from changing or triggering a physical-click binding.
- Allowed substantial fingertips near the rear of a Magic Mouse while retaining
  rejection for measured rear-palm and narrow side-edge contacts.
- Gave each contact sequence one gesture owner so taps, clicks, holds, and swipes
  cannot dispatch over one another.
- Preserved native scrolling for unbound swipe families and suppressed it only
  while a bound swipe owns the active contact sequence.
- Preserved the native trackpad click while adding a configured multi-finger
  click action.
- Corrected expanded application bindings that inherit a global action, explicit
  `defer = false`, malformed block recovery, and last-declaration display in
  Current Gestures.
- Reported rejected configuration reloads in the menu instead of presenting an
  empty configuration as successful.

This is a backward-compatible minor release. Existing version 2 configuration
files keep working. Magic Mouse physical-click bindings require an explicit
experimental opt-in because their recognition remains sensitive to contact
timing and hand posture.
