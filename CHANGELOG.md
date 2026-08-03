<!-- Records user-visible Magic Gestures releases in reverse chronological order. -->

# Changelog

## Unreleased

### Changed

- Replaced the custom configuration grammar with TOML. Settings now live in
  `~/.config/magic-gestures/config.toml`; actions, shortcuts, URLs, scripts, and
  exclusions are quoted strings.
- Changed application-specific table headings to TOML nested tables such as
  `[TRACKPAD."Final Cut Pro"]`.
- Made duplicate tables, duplicate keys, unquoted strings, and malformed TOML
  reject the reload while preserving the running configuration. Unknown Magic
  Gestures settings and bindings continue to be reported individually.

This changes the alpha configuration interface from version 2 to version 3.
Version 2 files must be converted before updating.

## 0.5.1

Released 2026-08-02.

### Added

- Added **Copy Prompt** under **Manage with Agent**. It gives any chat assistant
  the public configuration reference and asks for a ready-to-paste block without
  copying the user's existing configuration or private values.

### Changed

- Simplified the starter configuration from a compact reference document to a
  short working setup with a separated examples area. Existing user-owned
  configurations are unchanged during updates.
- Kept guided hardware trace capture internal and hidden by default while
  retaining logs and copied debug state in the public Diagnostics menu.

### Fixed

- Allowed up to three pixels of incidental Magic Mouse movement during a
  multi-finger physical click. Four pixels of displacement begins a drag and
  cancels the configured action.
- Delayed Magic Mouse physical-click actions until mouse-up, preserving the
  native click and preventing an intentional click-and-drag from firing the
  configured action early.
- Scoped trace results to the physical-click gesture under test so a configured
  tap action is not reported as a click false positive.
- Made the internal trace window closable after completion, increased its label
  contrast, and prevented execution-quality buttons from truncating.

This is a backward-compatible patch release. Existing version 2 configuration
files keep working. Magic Mouse physical-click bindings remain disabled by
default behind `experimental-mouse-click-gestures` while their behavior is
tested in daily use.

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
