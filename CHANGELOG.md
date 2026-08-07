<!-- Records user-visible Trickpad releases in reverse chronological order.
     Entries are written in the imperative, following Keep a Changelog: the
     Added/Changed/Fixed heading supplies the tense, so the bullet does not. -->

# Changelog

## 0.8.0

Released 2026-08-07.

### Added

- Warn about gesture conflicts on every configuration load. Trickpad reads
  the macOS mouse, trackpad, and accessibility gesture settings and lists any
  binding whose trigger a built-in gesture already uses, naming the System
  Settings pane where it lives. Bindings still run; Trickpad adds to what the
  hardware does rather than replacing it. Agents get the same report from the
  bundled `Contents/Resources/system-gestures.sh`.
- Add `sound:` and `say:` binding values for testing gestures.
  `"sound:Glass"` plays a system sound and `"say:three fingers"` speaks any
  words, with no other action, so a gesture can be proven before a real
  action rides on it. A gesture fired mid-sound interrupts and restarts it,
  so silence always means the gesture did not fire.
- Add `sound` and `say` binding options, which play a system sound or speak
  any words alongside a binding's real action:
  `{ action = "cmd+shift+4", sound = "Glass" }`. Both work on either device,
  so a Magic Mouse gesture can be confirmed by ear where haptic feedback is
  unavailable. Each starts immediately, delays neither the action nor the next
  gesture, and interrupts itself when the gesture repeats.
- Show each binding's own `config.toml` line comment beside it in the
  Current Gestures menu.
- Add menu key equivalents while the menu is open: `⌘,` opens settings,
  `⌘R` reloads, `⌘C` copies the agent prompt, `⌥⌘C` copies it with
  `config.toml` attached, and `⌘Q` quits.
- Title the gesture list with its binding count, so one row carries the
  configuration state and skipped-line details open from inside it.
- Open the menu once on first launch, so a new install shows where the app
  lives instead of leaving a menu bar icon to be found.
- Expand the installed agent guide around designing personal bindings: what
  earns a gesture, cheap trial and error, keeping the file's own formatting,
  and checking conflicts before proposing anything.
- Teach the installed agent guide to draft a support email to
  support@thirdwind.fyi, carrying the version, macOS version, device, and the
  bindings that bear on the problem. The agent drafts and shows it; the person
  sends it.

### Changed

- Rework the starter configuration for first reading: a header that explains
  commenting a line out, two examples per device, and no optional-binding
  catalogs.
- Move Open at Login below the separator with the app-lifecycle rows, leaving
  the group above to configuration actions.

### Fixed

- Correct a `script:` example that named a path nothing ships, so
  uncommenting it failed at reload.
- Probe installed coding agents in one background shell instead of one
  synchronous shell per agent, so the Manage with Agent submenu opens
  without delay.
- Require a hold gesture's resting finger to genuinely rest before the
  second finger lands, so a two-finger tap is no longer misread as a
  hold-tap. This also makes `defer = true` behave as documented.
- Keep Magic Mouse taps quiet after a physical click until the clicking
  fingers lift, so a resting hand no longer fires a tap on release.
- Stop counting the index finger of a level three-finger row as a thumb,
  which made some three-finger clicks dispatch as two-finger clicks.

This is a backward-compatible minor release. Existing version 3 configuration
files keep working.

## 0.7.1

Released 2026-08-05.

### Changed

- Make Copy Prompt use the stable, agent-readable web documentation and account
  for differences between the installed version and the latest reference.
- Rework the installed agent guide around safe configuration edits and
  gesture selection while keeping detailed syntax in the canonical reference.
- Document how a macOS shortcut assigned to an existing app menu command can
  become a Trickpad binding.

This is a backward-compatible patch release. Existing version 3 configuration
files keep working.

## 0.7.0

Released 2026-08-05.

### Added

- Add an experimental Magic Mouse two- or three-finger physical-click binding
  that can replace the normal click when confidently recognized. It remains off
  by default; ambiguous clicks and drags keep their native behavior.
- Add universal Intel and Apple silicon builds for macOS 11 and later.
- Add a configurable menu-bar icon. Use the bundled Trickpad mark or name an
  SF Symbol in `config.toml`; suspended gestures dim either choice.
- Add a provider-independent Get Latest Version menu item that opens Trickpad's
  stable download-retrieval page.

### Changed

- Establish the Trickpad app bundle, login item, and
  `~/.config/trickpad` configuration folder.
- Ship official builds in a styled disk image with an Applications link,
  first-launch guidance, license notices, and an exact corresponding-source
  link. GitHub releases carry the source and changelog without a binary.

This changes the alpha installation and configuration location.

## 0.6.1

Released 2026-08-03.

### Fixed

- Prevent a resting Magic Mouse edge contact from being recruited into a
  two-finger tap. A configured tap starts only when its two target contacts
  arrive together, so deliberate taps near an edge remain available.
- Apply per-contact arrival tracking to simultaneous multi-finger taps on
  both devices. Hold gestures, swipes, and physical clicks retain their own
  recognition rules because their contacts intentionally arrive or resolve at
  different times.

### Changed

- Group hidden guided hardware tests under a `Gesture testing` Diagnostics
  submenu. It remains absent from normal installs.

This is a backward-compatible patch release. Existing version 3 configuration
files keep working.

## 0.6.0

Released 2026-08-03.

### Changed

- Replace the custom configuration grammar with TOML. Settings now live in
  `~/.config/trickpad/config.toml`; actions, shortcuts, URLs, scripts, and
  exclusions are quoted strings.
- Change application-specific table headings to TOML nested tables such as
  `[TRACKPAD."Final Cut Pro"]`.
- Make duplicate tables, duplicate keys, unquoted strings, and malformed TOML
  reject the reload while preserving the running configuration. Unknown Magic
  Gestures settings and bindings continue to be reported individually.

This changes the alpha configuration interface from version 2 to version 3.
Version 2 files must be converted before updating.

## 0.5.1

Released 2026-08-02.

### Added

- Add **Copy Prompt** under **Manage with Agent**. It gives any chat assistant
  the public configuration reference and asks for a ready-to-paste block without
  copying the user's existing configuration or private values.

### Changed

- Simplify the starter configuration from a compact reference document to a
  short working setup with a separated examples area. Existing user-owned
  configurations are unchanged during updates.
- Keep guided hardware trace capture internal and hidden by default while
  retaining logs and copied debug state in the public Diagnostics menu.

### Fixed

- Allow up to three pixels of incidental Magic Mouse movement during a
  multi-finger physical click. Four pixels of displacement begins a drag and
  cancels the configured action.
- Delay Magic Mouse physical-click actions until mouse-up, preserving the
  native click and preventing an intentional click-and-drag from firing the
  configured action early.
- Scope trace results to the physical-click gesture under test so a configured
  tap action is not reported as a click false positive.
- Make the internal trace window closable after completion, increase its label
  contrast, and prevent execution-quality buttons from truncating.

This is a backward-compatible patch release. Existing version 2 configuration
files keep working. Magic Mouse physical-click bindings remain disabled by
default behind `experimental-mouse-click-gestures` while their behavior is
tested in daily use.

## 0.5.0

Released 2026-08-02.

### Added

- Add optional `left-` and `right-` prefixes for Shift, Control, Option, and
  Command. Unspecified modifiers continue to use the left-side key.
- Add diagnostics for Magic Mouse physical-click correlation to verbose logs.
- Add experimental Magic Mouse two- and three-finger physical-click bindings.
  They are disabled by default and require
  `experimental-mouse-click-gestures = true` under `[general]`.

### Fixed

- Correlate physical clicks with touch frames that arrive before mouse-down,
  after mouse-down, or just after mouse-up.
- Prevent brief contact dropouts, trackpad drags, palms, thumbs, and isolated
  edge contacts from changing or triggering a physical-click binding.
- Allow substantial fingertips near the rear of a Magic Mouse while retaining
  rejection for measured rear-palm and narrow side-edge contacts.
- Give each contact sequence one gesture owner so taps, clicks, holds, and swipes
  cannot dispatch over one another.
- Preserve native scrolling for unbound swipe families and suppress it only
  while a bound swipe owns the active contact sequence.
- Preserve the native trackpad click while adding a configured multi-finger
  click action.
- Correct expanded application bindings that inherit a global action, explicit
  `defer = false`, malformed block recovery, and last-declaration display in
  Current Gestures.
- Report rejected configuration reloads in the menu instead of presenting an
  empty configuration as successful.

This is a backward-compatible minor release. Existing version 2 configuration
files keep working. Magic Mouse physical-click bindings require an explicit
experimental opt-in because their recognition remains sensitive to contact
timing and hand posture.
