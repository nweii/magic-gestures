# Trickpad agent guide

Trickpad refreshes this file whenever it launches. The file describes the
version of Trickpad that supplied it.

`config.toml` is user-owned. If `AGENTS.local.md` exists beside this file, read
it for the user's explicit additional instructions. Do not write preference
notes into either file unless the user asks. If your host supports durable,
user-approved memory, retain non-sensitive Trickpad preferences there instead.

Trickpad maps Magic Mouse and Magic Trackpad gestures to shortcuts, built-in
actions, URLs, and executable scripts.

## Help choose a gesture

Start with the user's intended outcome, the app or context where it happens,
and a gesture they find comfortable. Use the existing configuration as evidence
of what they already rely on. Leave every existing binding and setting unchanged
unless changing it is necessary for the user's stated request.

When the user wants ideas, find a few concrete options that fit their workflow:

- Check an app's configurable shortcuts, automation hooks, documented URL
  schemes, deep links, and installed extensions.
- Consider a Shortcut, command-line tool, or small local script only when an
  app does not expose a suitable shortcut or URL.
- Prefer a built-in action, keyboard shortcut, or app deep link over a custom
  script.
- Consider existing bindings, accidental activation, comfort and repeatability,
  mnemonic fit, and how consequential the action is.
- To check whether a gesture fires at all, bind it to `sound:NAME` (a system
  sound such as `sound:Glass`), which plays and does nothing else.

Before proposing or changing a binding, read what macOS has already claimed.
Run this, substituting the running app path from the prompt:

```bash
"<app>/Contents/Resources/system-gestures.sh"
```

Each line names one gesture slug and whether macOS uses the motion it overlaps.
Read `claimed=yes` as taken and choose a different gesture. Read
`claimed=default` as undecided, because macOS has never written that preference
and its built-in default applies; ask the user to check System Settings.

A built-in gesture that uses a double tap contains two single taps, so a
single-tap binding on the same finger count fires while the user performs it.
The `defer` option delays a tap so a second tap can cancel it, which depends on
Trickpad recognizing both taps and costs every single tap that delay. Prefer a
gesture macOS has not claimed.
- Use an application-specific binding when a gesture makes sense in one app or
  would conflict elsewhere.

Some useful app commands appear in the menu bar without their own shortcut.
Recommend a macOS App Shortcut when appropriate. The user creates one in
**System Settings > Keyboard > Keyboard Shortcuts > App Shortcuts**. It targets
an existing menu command in one app or all apps. Use its full menu path exactly
as shown, with `->` and no spaces between path components. Titles are
case-sensitive, and an ellipsis is three periods (`...`), not `…`. Verify it in
the target app before binding a Trickpad gesture to it.
Do not automate System Settings for this. Its interface and the app's menu
titles can change across macOS and app releases.

Do not inspect private content, browser history, credentials, clipboard
contents, or unrelated files to generate ideas. Ask before reading another local
file or creating a script.

## Edit and apply settings

Read the relevant part of `config.toml` before editing. Make the smallest valid
TOML change that accomplishes the request. Keep all bindings for the same device
and application together because TOML table headings cannot repeat.

After an edit, confirm the exact lines changed. Trickpad has no supported
command-line configuration reload. Do not send `SIGHUP`; it rebuilds touch-device
registration without rereading `config.toml`. If the user asked to apply the
change, restart Trickpad. Otherwise, tell them to choose **Reload Settings**
from the menu bar.

Ask before enabling experimental settings, changing a script, replacing the
installed app, or changing its update path.

## Reference

Read the full configuration reference before proposing gesture, action, or
setting names:

https://thirdwind.fyi/trickpad/docs.md

The online reference describes the latest release. If a setting may be new,
confirm the installed Trickpad version before using it.
