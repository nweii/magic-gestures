<!-- Records user-visible Trickpad releases in reverse chronological order.
     Entries are written in the imperative, following Keep a Changelog: the
     Added/Changed/Fixed heading supplies the tense, so the bullet does not.
     Entries follow ASD-STE100 Simplified Technical English: one idea per
     sentence, sentences under 25 words, no semicolons, and no "should", "may",
     or "might". A reader decides from this file whether an update affects
     them, and many of them do not read English as a first language. -->

# Changelog

## 0.8.1

Released 2026-08-07.

### Fixed

- Report a two-finger trackpad tap as available when tap to click is off. Secondary click answers a two-finger press. It answers a two-finger tap only when tap to click is also on. The error appeared in the reload warning and in the report that agents read.
- Report a conflict only when the macOS settings show one. Trickpad reads a preference that macOS never wrote as unknown. An unknown preference does not add a conflict and does not remove one. Trickpad also reads a preference whose value is a name, not a number, as unknown.

### Changed

- Rewrite the agent guide that Trickpad installs. The guide starts with the contents of the configuration folder and the goal of the user, not with the choice of a gesture. It describes `AGENTS.local.md`, the file that keeps the user's own conventions when Trickpad refreshes the guide. It also explains how to maintain a configuration as it grows.

## 0.8.0

Released 2026-08-07.

### Added

- Warn about gesture conflicts at every configuration load. Trickpad reads the macOS mouse, trackpad, and accessibility gesture settings. It lists each binding whose trigger a built-in gesture already uses, and it names the System Settings pane that holds that gesture. The bindings continue to run, because Trickpad adds to what the hardware does. Agents read the same report from `Contents/Resources/system-gestures.sh` in the app bundle.
- Add the `sound:` and `say:` binding values, which test a gesture. `"sound:Glass"` plays a system sound. `"say:three fingers"` speaks the words you give it. Neither does anything else, so you can prove a gesture before you give it a real action. A gesture that fires during a sound interrupts that sound and starts it again. Silence therefore means that the gesture did not fire.
- Add the `sound` and `say` binding options. They play a system sound or speak words together with the real action of a binding, as in `{ action = "cmd+shift+4", sound = "Glass" }`. Both work on either device. A Magic Mouse has no haptic feedback, so a sound is the way to confirm one of its gestures. Each starts immediately and delays neither the action nor the next gesture. Each interrupts itself when the gesture repeats.
- Show the line comment of each binding from `config.toml` beside it in the Current Gestures menu.
- Add key equivalents that work while the menu is open. `⌘,` opens the settings. `⌘R` reloads them. `⌘C` copies the agent prompt. `⌥⌘C` copies that prompt with `config.toml` attached. `⌘Q` quits.
- Title the gesture list with its binding count. One row now carries the configuration state, and the details of any skipped line open from inside it.
- Open the menu once at first launch. A new installation shows where the app lives, instead of leaving a menu bar icon to be found.
- Expand the agent guide on the design of personal bindings. It covers what earns a gesture, cheap trial and error, the formatting of the file, and the conflict checks that come before a proposal.
- Teach the agent guide to draft a support email to support@thirdwind.fyi. The draft carries the version, the macOS version, the device, and the bindings that bear on the problem. The agent writes the draft and shows it. The user sends it.

### Changed

- Rework the starter configuration for a first reading. It has a header that explains how to comment out a line, two examples for each device, and no catalog of optional bindings.
- Move Open at Login below the separator, with the app-lifecycle rows. The group above it now holds the configuration actions.

### Fixed

- Correct a `script:` example that named a path Trickpad does not ship. The example failed at reload when a user removed the comment.
- Probe installed coding agents in one background shell, not in one shell for each agent. The Manage with Agent submenu opens without delay.
- Require the resting finger of a hold gesture to rest before the second finger lands. Trickpad no longer reads a two-finger tap as a hold-tap. `defer = true` now behaves as documented.
- Keep Magic Mouse taps quiet after a physical click until the clicking fingers lift. A resting hand no longer fires a tap on release.
- Stop counting the index finger of a level three-finger row as a thumb. This error made some three-finger clicks dispatch as two-finger clicks.

This is a backward-compatible minor release. Existing version 3 configuration files keep working.

## 0.7.1

Released 2026-08-05.

### Changed

- Make Copy Prompt use the stable web documentation that an agent can read. The prompt also states that the installed version can differ from the latest reference.
- Rework the agent guide around safe configuration edits and the choice of a gesture. The detailed syntax stays in the canonical reference.
- Document how a macOS shortcut for an existing app menu command can become a Trickpad binding.

This is a backward-compatible patch release. Existing version 3 configuration files keep working.

## 0.7.0

Released 2026-08-05.

### Added

- Add an experimental physical-click binding for two or three fingers on a Magic Mouse. A click that Trickpad recognizes with confidence replaces the normal click. This binding is off by default. Ambiguous clicks and drags keep their native behavior.
- Add universal Intel and Apple silicon builds for macOS 11 and later.
- Add a menu bar icon that you can configure. Use the bundled Trickpad mark, or name an SF Symbol in `config.toml`. Suspended gestures dim either choice.
- Add a Get Latest Version menu item. It opens the stable download page of Trickpad and does not depend on a store.

### Changed

- Establish the Trickpad app bundle, the login item, and the `~/.config/trickpad` configuration folder.
- Ship official builds in a styled disk image. The image carries an Applications link, first-launch guidance, license notices, and an exact corresponding-source link. GitHub releases carry the source and the changelog without a binary.

This changes the alpha installation and configuration location.

## 0.6.1

Released 2026-08-03.

### Fixed

- Prevent a resting edge contact on a Magic Mouse from joining a two-finger tap. A configured tap starts only when its two contacts arrive together. Deliberate taps near an edge remain available.
- Track the arrival of each contact for simultaneous multi-finger taps on both devices. Hold gestures, swipes, and physical clicks keep their own rules, because their contacts arrive or end at different times by design.

### Changed

- Group the hidden guided hardware tests under a `Gesture testing` submenu in Diagnostics. This submenu does not appear in a normal installation.

This is a backward-compatible patch release. Existing version 3 configuration files keep working.

## 0.6.0

Released 2026-08-03.

### Changed

- Replace the custom configuration grammar with TOML. The configuration now lives at `~/.config/trickpad/config.toml`. Actions, shortcuts, URLs, scripts, and exclusions are quoted strings.
- Change application-specific table headings to TOML nested tables, such as `[TRACKPAD."Final Cut Pro"]`.
- Reject the reload when the file has a duplicate table, a duplicate key, an unquoted string, or malformed TOML. The running configuration stays in place. Trickpad continues to report each unknown setting and binding on its own.

This changes the alpha configuration interface from version 2 to version 3. Convert a version 2 file before you update.

## 0.5.1

Released 2026-08-02.

### Added

- Add **Copy Prompt** under **Manage with Agent**. It gives a chat assistant the public configuration reference and asks for a block that the user can paste. It does not copy the user's configuration or any private value.

### Changed

- Simplify the starter configuration. It is now a short working setup with a separate area for examples, not a compact reference document. An update does not change a configuration the user owns.
- Keep the guided hardware trace capture internal and hidden by default. The public Diagnostics menu keeps the logs and the copied debug state.

### Fixed

- Allow up to three pixels of incidental movement on a Magic Mouse during a multi-finger physical click. Four pixels start a drag and cancel the configured action.
- Delay a Magic Mouse physical-click action until mouse-up. The native click stays, and a deliberate click-and-drag no longer fires the configured action early.
- Limit the trace results to the physical-click gesture under test. A configured tap action is no longer reported as a false click.
- Let the user close the internal trace window after it completes. The labels have more contrast, and the execution-quality buttons no longer truncate.

This is a backward-compatible patch release. Existing version 2 configuration files keep working. Magic Mouse physical-click bindings stay disabled by default behind `experimental-mouse-click-gestures`, because their behavior is still under test in daily use.

## 0.5.0

Released 2026-08-02.

### Added

- Add optional `left-` and `right-` prefixes for Shift, Control, Option, and Command. A modifier with no prefix continues to use the left-side key.
- Add diagnostics for Magic Mouse physical-click correlation to the verbose logs.
- Add experimental physical-click bindings for two and three fingers on a Magic Mouse. They are disabled by default and need `experimental-mouse-click-gestures = true` under `[general]`.

### Fixed

- Correlate physical clicks with touch frames that arrive before mouse-down, after mouse-down, or just after mouse-up.
- Prevent a brief contact dropout, a trackpad drag, a palm, a thumb, or an isolated edge contact from changing or triggering a physical-click binding.
- Allow large fingertips near the rear of a Magic Mouse. Trickpad still rejects measured rear-palm contacts and narrow side-edge contacts.
- Give each contact sequence one gesture owner, so taps, clicks, holds, and swipes cannot dispatch over one another.
- Keep native scrolling for a swipe family that has no binding. Trickpad suppresses scrolling only while a bound swipe owns the contact sequence.
- Preserve the native trackpad click, and add the configured multi-finger click action beside it.
- Correct four faults in the configuration parser. An expanded application binding did not inherit a global action. An explicit `defer = false` did not apply. Recovery from a malformed block failed. Current Gestures did not show the last declaration of a gesture.
- Report a rejected configuration reload in the menu. Trickpad no longer presents an empty configuration as a success.

This is a backward-compatible minor release. Existing version 2 configuration files keep working. Magic Mouse physical-click bindings need an explicit experimental opt-in, because their recognition is still sensitive to contact timing and hand posture.
