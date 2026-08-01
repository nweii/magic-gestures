# magic-gestures

Maps Magic Mouse and Magic Trackpad multi-touch gestures to keystrokes, built-in
actions, or custom URLs on macOS. Runs as a background agent with a menu bar item
and no window.

`CLAUDE.md` is a symlink to this file. Edit this one.

Shell scripts live in `scripts/` and resolve paths from the project root, two
levels up from themselves.

## Vendored engine, local config layer

Recognition is [Jitouch](https://github.com/JitouchApp/Jitouch), vendored under
`src/jitouch/` by way of a fork. The `upstream` remote points at that fork.

Jitouch is a gesture app with a catalog of built-in actions and a preference
pane for choosing among them. This project keeps its recognizers and drops the
rest, so a gesture sends whatever keyboard shortcut the configuration names.
Prefer that shape when adding anything: the built-in actions still work and are
worth using where they fit, but the catalog is not the point.

`src/main.m` is 26 lines. `Gesture.m` is roughly 4,800 lines of recognizers.
Changes belong in `src/Config.m` unless the engine is demonstrably wrong.

Jitouch reads the private `MultitouchSupport.framework`, which is undocumented
and free to change across macOS releases. Upstream has had no code commits since
January 2023, so breakage is ours to fix.

## Build and run

```bash
./scripts/build.sh             # single clang call, no Xcode project
./scripts/check.sh             # configuration parser checks
./scripts/stop.sh && ./scripts/start.sh
./scripts/update.sh            # preview and install a source update
```

`start.sh` builds when the bundle is missing, seeds the configuration folder,
and launches the app.

Configuration changes skip the build. Apply them from the menu bar item's Reload
Settings, or restart with `scripts/start.sh`. SIGHUP re-registers the
multi-touch devices without rereading the file, so it does not apply a binding
change on its own.

`update.sh` requires a clean checkout, fetches public `origin/main`, previews the
incoming commits, and asks before a fast-forward update. After approval it runs
the checks, rebuilds, and restarts. `--yes` skips only the prompt and is for an
agent to use after the user has approved the displayed update.

The Accessibility grant binds to the bundle path plus the designated requirement
that `scripts/build.sh` pins. Keep both stable and the grant survives every rebuild.

## Menu bar item

About opens a submenu carrying the version, read from the running bundle, and
a link to the repository.

`showIcon` in `JitouchAppDelegate.m` builds it. Top to bottom:

- Turn Magic Gestures Off, which suspends recognition without quitting.
- The Accessibility status, which opens the Privacy pane when access is missing.
- Current Gestures, a submenu listing the live bindings by device, each phrased
  through `humanNameForGesture:`.
- Manage with Agent, a submenu of the coding agents found through the
  user's login shell. Picking one writes
  `~/.config/magic-gestures/manage-with-agent.command` and opens it, starting
  that agent in the configuration folder with the running app path and a prompt
  pointing at the installed instructions.
- Edit Settings, which opens `config.txt` in the user's editor.
- Reload Settings, which rereads the file into the running engine.
- Open at Login, a checkbox running `install-login-agent.sh` or
  `uninstall-login-agent.sh` with `PLIST_ONLY` set, so the file changes without
  launchd terminating the running process.
- About Magic Gestures and Quit Magic Gestures.

## Releasing

The version lives in one place: `CFBundleShortVersionString` in
`scripts/build.sh`. The menu bar header reads it from the running bundle, so it
cannot drift from what is installed.

Semantic versioning, read against the configuration file rather than the code,
because the config is the only interface anyone depends on:

- **Patch** — a fix that leaves every existing `config.txt` working.
- **Minor** — new gestures, keys, actions, or settings. An existing config keeps
  working, since unknown names are reported and skipped rather than failing.
- **Major** — a rename or removal that makes an existing `config.txt` behave
  differently. The positional gesture rename would have been one.

To cut a release:

```bash
# bump CFBundleShortVersionString and CFBundleVersion in scripts/build.sh
./scripts/build.sh && ./scripts/check.sh
./scripts/package.sh
git commit -am "Release X.Y.Z"
git tag -a vX.Y.Z -m "X.Y.Z"
git push origin main --tags
gh release create vX.Y.Z --title "X.Y.Z" --notes "..." build/MagicGestures-X.Y.Z.zip
```

Every release carries the zip that `scripts/package.sh` produces, attached to
the GitHub release. That zip is the install path the README leads with:
download, unzip, drag the app anywhere, clear Gatekeeper once through System
Settings > Privacy & Security > Open Anyway.

The release title is the bare version. The repository name sits above it on
every page that shows a release, so repeating it adds nothing.

`gh release create` has been seen to report a missing `workflow` scope that the
token already holds. Creating it through `gh api repos/OWNER/REPO/releases`
works. Pass `--repo` to any `gh release` or `gh repo` command here, or it
resolves to the `upstream` remote and reports the fork's releases instead.

The app is ad-hoc signed rather than notarized, so anyone installing from the
zip has to clear Gatekeeper by hand once. Notarizing would need a paid Apple
Developer account. Building from source stays supported and skips that step.

A rename or removal of a configuration name is the one change that needs a
migration note in the release, because an existing file will silently stop
matching. `scripts/check.sh` catches a name that exists in code but not the
docs; it cannot catch a name that used to exist.

## Configuration model

`src/Config.m` reads `~/.config/magic-gestures/config.txt` and returns the
settings dictionary the engine consumed when it was a plist, so nothing
downstream knows the format changed. `MAGICGESTURES_CONFIG` overrides the path.
`resolvedPath` returns nil when no file exists.

The folder is seeded from two files at the project root: `config.default.txt`
becomes the user-owned `config.txt`, and `config-notes.default.md` becomes the
app-managed `AGENTS.md`. `start.sh`, `install-login-agent.sh`, and the app create
`config.txt` only when missing and atomically refresh `AGENTS.md` from the running
version. An optional user-owned `AGENTS.local.md` survives updates.

Lines are `key = value`. A `#` at the start of a line or after whitespace starts
a comment. `[mouse]` and `[trackpad]` are the normal form for hand-edited binding
groups. A `mouse.` or `trackpad.` prefix overrides the section, making one
appended binding safe for an agent or script. General settings belong in
`[general]`; there is no `general.` prefix.

A tap gesture may end in `.defer`, as in `two-finger-tap.defer` or
`mouse.two-finger-tap.defer`. Its action waits through the Mac's double-click
interval and is canceled by a second matching tap on the same device. Use it
when preserving an overlapping double-tap gesture is worth adding latency to
the single tap. The parser accepts it only on gesture names ending in `-tap`.

`config-version` identifies the file format and is currently `1`. A missing
version is format 1. An unsupported value rejects the entire reload so a newer
file cannot be partially reinterpreted.

Three value forms:

- A keystroke: any modifiers plus one key. Separators may be `+`, `-`, or a
  space, and modifier symbols may run together with no separator at all.
- A built-in action. `actionNames` maps each slug to the exact string
  `dispatchCommand` in `Gesture.m` compares against.
- A custom URL prefixed with `url:`. The parser validates its scheme, whitespace,
  and percent escapes while preserving the payload's case. `NSWorkspace` resolves
  the installed handler when the gesture fires.

A **substitution** is a named expression in a URL binding that resolves when its
gesture fires. Use this term in code and documentation; avoid snippet, variable,
and token. The supported forms are `{{clipboard}}`,
`{{clipboard|urlencode}}`, and `{{datetime:FORMAT}}`. URL encoding treats the
clipboard as one component. Date formats use `NSDateFormatter`, the POSIX locale,
and the Mac's local time zone.

Reload validates substitution names, filters, braces, empty date formats,
unmatched date-format quotes, and the URL with safe placeholder values. Dispatch
reads the clipboard, resolves the current date and time, and validates the
expanded URL. Logs may include the configured binding but never expanded
clipboard contents.

Use **URL binding** for the configuration capability. An **app deep link** is a
URL binding that opens a specific place or action in an app. A **URL scheme** is
the protocol name at the start, such as `raycast`, `obsidian`, or `things`. Do
not use URI in user-facing copy; it adds no useful distinction here.

An unparseable line is skipped rather than failing the file.

`mouseGestureSlugs` and `trackpadGestureSlugs` hold the gesture vocabulary. One
slug may bind several engine names that differ only by how far apart two fingers
land. The two devices keep separate tables, enable flags, and vocabularies, so a
binding on one does not reach the other.

Every engine name a slug reaches needs a phrase in `humanNameForGesture:`, or
Current Gestures falls back to the engine's internal name.

Shift, Control, Option, and Command are the available modifiers. Fn is a HID
usage rather than a key event and cannot be synthesized.

The `appID` CFPreferences domain in `Settings.h` is vestigial — only the removed
preference pane wrote to it.

`GESTURES.md` is the user-facing reference for every slug, key, action, and
setting.

## Checks

`./scripts/check.sh` compiles `src/Config.m` with `src/ConfigCheck.m` and runs
the result against the parser. No framework, no fixtures.

It asserts keystroke parsing, action and deferred dispatch, URL substitution
parsing and resolution, section and inline-prefix handling, skipped bad lines,
boolean spellings, and comment stripping. It also asserts that every slug
appears in both `GESTURES.md` and
`config-notes.default.md`, and that every engine name reachable from a slug has
a menu phrase. Adding a gesture without documenting it fails the check.

## Login item

`./scripts/install-login-agent.sh` writes a launchd plist to
`~/Library/LaunchAgents/fyi.nathancheng.magic-gestures.agent.plist`, which
starts the agent at login and restarts it if it exits. The generated plist
opens with a comment naming what it does and pointing back here, since a bare
launchd label is easy to find and hard to identify.

`./scripts/uninstall-login-agent.sh` removes it. Deleting the plist by hand has
the same effect and leaves the project alone.

`./scripts/uninstall.sh` removes the login item, the running app, and the build.
It keeps the settings folder unless called with `--all`, and prints the two
steps that cannot be scripted.

The project writes two things outside its own directory: the launchd plist, and
`~/.config/magic-gestures/`, which holds `config.txt`, `AGENTS.md`, and
`manage-with-agent.command`.

## Logging

Set `verbose-logging = true` in `config.txt` for per-gesture and per-keystroke
logging:

```bash
/usr/bin/log show --style compact --last 5m --predicate 'process == "MagicGestures"'
```

## Standing constraints

- **Add, never replace.** A binding extends what the hardware does. Anything
  System Settings owns — tap-to-click, secondary click, the built-in swipes —
  keeps behaving as the user configured it. `middle-click` is fair game on a
  Magic Mouse, which has no middle button to override.
- **Check both conflict surfaces before binding.** macOS claims some motions,
  listed in `GESTURES.md`. The user's own hotkeys claim some chords, and a
  Caps Lock remapped to Cmd+Alt+Ctrl is a common one worth asking about.
- **Hold gestures carry anything consequential.** Holding one finger still while
  another taps or slides is unreachable by a resting hand, and macOS uses that
  shape nowhere.

## Hotkey compatibility

Some applications watch the keyboard through a CGEventTap and require explicit
modifier transitions instead of reading only the flags on one key event. Magic
Gestures sends modifier key-down events, the key down and up with complete
modifier flags, then modifier key-up events. Aqua Voice and Wispr Flow accept
this sequence. System Events may produce a different sequence, so its result
does not predict whether a Magic Gestures binding will work. Test the actual
gesture in the target application.

## Local modifications to the vendored engine

These changes are deliberate and are not present upstream. Reverting them can
silently regress the configuration contract.

`KeyUtility.m`, `simulateKeyCode:` posts a hardware-shaped sequence through
`CGEventCreateKeyboardEvent`: modifier presses, the key press and release, then
modifier releases. The key events retain the full modifier flags conventional
hotkey APIs inspect. Each modifier also sets its device-dependent left-side bit
(`NX_DEVICELSHIFTKEYMASK` and kin), since an application can register a
side-specific hotkey that the generic masks cannot satisfy. Modifiers already
held by the user are neither pressed nor released by the sequence.

`Gesture.m`, `gestureMagicMouseOneFingerSwipe` returns early when nothing is
bound to a one-finger swipe. The suppression below that point disables
horizontal scrolling on any one-finger horizontal movement, and upstream runs it
whether or not a swipe is bound, degrading ordinary scrolling in an unbound
configuration.

`TrackpadInteraction.m` classifies each trackpad contact sequence before the tap
recognizers claim it. Broad palm contacts and physical clicks reject tap-only
gestures, one recognizer may claim a sequence, and full lift resets the state.
Keep gesture-specific geometry and timing in `Gesture.m`; shared eligibility and
inter-gesture arbitration belong in this module.
