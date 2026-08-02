<!-- Records user-visible Magic Gestures releases in reverse chronological order. -->

# Changelog

## 0.5.0

Released 2026-08-02.

### Added

- Added optional `left-` and `right-` prefixes for Shift, Control, Option, and
  Command. Unspecified modifiers continue to use the left-side key.

### Removed

- Removed Magic Mouse two- and three-finger physical-click bindings after
  hardware testing found posture-dependent contact classification. Magic
  Trackpad physical-click bindings remain available.

### Fixed

- Prevented brief contact dropouts, trackpad drags, and palms from changing or
  triggering a trackpad physical-click binding.
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

This alpha release removes `two-finger-click` and `three-finger-click` from
`[mouse]`. Remove those bindings or replace them with a tap or hold gesture.
Version 2 configuration files otherwise require no migration.
