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
- Consider existing bindings, comfort and repeatability, mnemonic fit, and how
  consequential the action is.
- Use an application-specific binding when a gesture makes sense in one app or
  would conflict elsewhere.
- To check whether a gesture fires at all, bind it to `sound:NAME` (a system
  sound such as `sound:Glass`) or `say:WORDS`, which play or speak and do
  nothing else. Speech can name the gesture, so several test bindings stay
  distinguishable by ear.

## Design bindings this person will keep

A good configuration is personal: it reflects one person's apps, habits, and
taste, and it usually gets there through revision rather than in one pass.

**A binding earns its place in one of a few ways.** Any one of these can
justify it, and the mix differs per person and per app:

- Frequency. Something done many times an hour is worth a gesture; something
  rare rarely is.
- Flow. The strongest case is a hand already on the mouse or trackpad doing
  continuous work — dragging, scrubbing, navigating — where the action
  interleaves with that work. A gesture that saves an easy shortcut can still
  be a big win if it keeps the hand in place mid-flow.
- Ergonomics. A genuinely awkward chord, three or four modifiers or a long
  reach, benefits even when it is less frequent.
- No keyboard equivalent. Opening a URL or deep link, running a script, or a
  middle click has no keystroke to save, so a gesture is a natural fit.

Ask about the person's actual day — the apps they live in, what they do while
the hand is already on the device — and propose bindings they would plausibly
try, not a showcase of what the app can do.

**Treat the configuration as a draft, always.** Trying, disliking, and
rebinding is the normal path, not a failure of planning. The loop is cheap:
edit, Reload Settings, try it in real work. Offer `sound:NAME` or `say:WORDS`
when the person wants to feel a gesture out before giving it a real action.
Suggest revisiting a binding after a few days of real use rather than
defending the first draft.

**Tend the file the way its owner keeps it.** The configuration is a
plain-text file the person lives in, so its readability is part of the
product. Offer, when it would help, to tidy section dividers, comments,
ordering, and spacing — and match the conventions already in the file rather
than imposing new ones. If the person has their own formatting rules, treat
them as the file's lint and keep every edit consistent with them.
`AGENTS.local.md` beside this file is the durable home for those conventions
if they want them written down. A comment on a binding's own line appears in
the menu bar item's Current Gestures list, so a well-commented file documents
itself in the app.

## Recommend gestures that avoid conflicts

If a recommendation carries a risk, tell the user plainly what could collide
and when, in terms of what their hand does.

**Many gestures overlap with simpler variants.** A double tap contains a
single tap, and a three-finger gesture could pass through a two-finger moment
as fingers land and lift. When one binding sits inside another this way, the
simpler one might fire during the fuller one. Trickpad works to tell such
intentions apart, but bindings that cannot overlap in the first place beat any
amount of filtering, so we prefer them at the planning stage.

**The device counts contacts, not fingers.** A resting finger can add one to
the count. A light touch or an edge contact can drop one. That makes gestures
at neighboring finger counts easy to mistake for each other now and then. When
two actions must never substitute for each other, give them gestures that
differ in kind — a hold against a tap, a swipe against a click — rather than
by one finger.

**Conflicts usually come from three places. Check each.**

- Triggers macOS has claimed. Run the claims report, substituting the running
  app path from the prompt:

  ```bash
  "<app>/Contents/Resources/system-gestures.sh"
  ```

  `claimed=yes` means macOS acts on that trigger: prefer a different gesture,
  or tell the user what would double-fire. `claimed=default` means macOS has
  never written the preference, so ask the user to check System Settings.
- The configuration itself. Read the user's other bindings on the same device
  for anything the proposal contains, sits inside, or neighbors by one finger.
- The output. The keystroke a binding sends can collide with app or global
  hotkeys nothing here can see. A Caps Lock remapped to a modifier chord is
  common; ask.

**Judge a gesture against the hand at rest.** Between gestures a hand is often
already on or over the device — resting, clicking, scrolling. A good gesture
is one that background is unlikely to produce by accident, so weigh a proposal
against the contacts and motions ordinary use of that surface involves. The
less it resembles them, the more the binding can safely carry.

**Work with the user's associations.** People remember gesture bindings as
meaning attached to motion, so bindings that share structure are cheaper to
learn and harder to mix up. Paired actions sit well on paired gestures, the
way the defaults put escape and return on mirrored hold-taps. A gesture
rebound per application holds up best when its action stays the same kind of
thing in each. When the user offers their own mnemonic, build on it rather
than replacing it.

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
