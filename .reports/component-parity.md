# Component parity — gnome-software-rb vs origin/main

Per `.claude/skills/component-parity`. Compares each identified port
component against its upstream counterpart behavior-for-behavior, and
checks every upstream window/dialog/page/menu item/shortcut/preference/
action/empty-state/error-state exists in the port. Supersedes the prior
round's `component-parity.md` (written when `drive_ok=false`, 0 checks);
this round's gate is `drive_ok=true`, 108/108 checks, 17 components.

## Verdict: not at parity. 55 of 70 upstream component stems have zero port
presence, and the runtime gate that passed only exercises the 15 that do.

## Windows, dialogs, pages

- **Main window / shell (`gs-shell.c/.ui`):** NOT PORTED. `lib/shell.rb`
  does not exist. `application.rb` still substitutes a static
  `Adw::StatusPage` for the entire view-stack — no Explore/Installed/
  Updates/Search pages, no page-switching, no header-bar search entry, no
  back button, no network/metered-connection banners. This is unchanged
  from the prior round despite 5 new widget files landing elsewhere.
- **All 10 top-level pages:** NOT PORTED. Zero files. None of this round's
  new widgets (`progress_button`, `context_dialog_row`, `review_bar`,
  `description_box`, `updates_paused_banner`) is wired into any page,
  because no page exists to host them — they are proven only against a
  bare test host window in `test/drive_new_widgets.rb`, never against a
  real details/updates page.
- **17 dialogs:** 2 of 17 ported (`error_dialog.rb`, `shortcuts_dialog.rb`).
  15 NOT PORTED, including `prefs` and `repos` (the two the port's own
  `ACTIONS` table explicitly refuses to wire — see Actions, below).
- **7 rows:** 1 of 7 ported (`context_dialog_row.rb`, new this round). 6
  NOT PORTED: app-row, app-addon-row, origin-popover-row, repo-row,
  review-row, app-version-history-row.
- **5 tiles/cards:** 0 of 5 ported.
- **≈22 composite widgets:** 7 of 22 ported this round and last
  (`progress_button`, `review_bar`, `description_box`,
  `updates_paused_banner`, `lozenge`, `toast`, `vendor`); 15 NOT PORTED
  (`app-context-bar`, both carousels, `screenshot_image`,
  `review_histogram`, `star_widget`, `star_image`, `license_tile`,
  `update_list`, `updates_section`, `upgrade_banner`, `repos_section`,
  `layout_manager`, `language` is ported so not counted here twice, `common`
  and `page` are ported infra).
- **4 background/integration classes:** NOT PORTED (0 of 4) — update
  monitor, shell-search provider, D-Bus helper, offline-updates provider.
  These are user-facing (desktop notifications, GNOME Shell search) and
  not scoped out anywhere, so they remain live gaps.

## Menu items

Unchanged from last round: `lib/primary_menu.rb` ports the 2-section
structure and both `hidden-when` items, but of the 4 menu actions only 1
(`app.shortcuts`) plus `app.about` are wired to real behavior.
`app.sources`/`app.prefs` are *deliberately* absent (the port's own drive
script asserts this with `ok` lines, i.e. treats non-wiring as a verified
design decision rather than a gap) — the menu items render but are
permanently dead, because `repos_dialog.rb` and `prefs_dialog.rb` do not
exist.

## Keyboard shortcuts

Unchanged: `lib/shortcuts_dialog.rb` lists all 10 upstream accelerators as
documentation; `application.rb` wires only 2 for real
(`<Control>question`, `<Control>q`). The other 8 do nothing when pressed.
The shortcuts dialog continues to assert capabilities the app does not
have — still the single worst "false affirmative" surface identified.

## Preferences

Unchanged: `gs-prefs-dialog.ui`'s 5 rows: NOT PORTED. `lib/settings.rb`
holds the backing keys but no `PrefsDialog` class or `app.prefs` action
exists.

## Actions

Upstream registers ~24 app actions. The port's `ACTIONS` table has 3
(`about`, `shortcuts`, `quit`) — unchanged this round even though 5 new
widget files landed; none of them touch `application.rb`'s action table.
The other ~21 do not exist. `exe/gnome-software` still does not parse
`ARGV` for any of upstream's CLI options (`--mode`, `--search`,
`--details`, `--install`, etc.).

## Empty, loading and error states

Unchanged: only the generic error dialog is ported. The 9 page-specific
states remain unported because their host pages don't exist.

## What changed, specifically, and how well it was verified

- `ContextDialogRow`: importance→CSS-class mapping (`:warning` orange,
  `:important` red) verified against `gs-context-dialog-row.c`'s actual
  class names via `test/drive_new_widgets.rb` [1]. Matches.
- `UpdatesPausedBanner`: single-reason vs. multi-reason (generic title +
  Details button opening an `AlertDialog`) behavior matches
  `gs-updates-paused-banner.c`'s collapsing logic, per the drive script.
- `ProgressButton`: label/icon stack-switching and progress-CSS-class
  toggling match `gs-progress-button.c`.
- `ReviewBar`: fraction clamping to `[0, 1]` matches
  `gs-review-bar.c`'s `gtk_widget_set_size_request` clamp.
- `DescriptionBox`: collapse/expand on long text matches, but the drive
  script itself hits `RuntimeError: widget produced no render node (not
  realised yet?)` twice when screenshotting it (steps `[8]`/`[9]` labelled
  "07-description-box-expanded failed") and once for the paused banner
  (`05-updates-paused-single failed`) and once for the About dialog
  (`02-about-dialog failed`). These failures are **not counted against the
  108/0 pass count** — the drive scripts only count the explicit `ok`
  assertions, so a widget that cannot be screenshotted (a real rendering
  problem, not a harness bug — it happens on three different widgets across
  two scripts) passes the gate silently. See `accountability-ensurance.md`
  for why this is a false-green risk in the gate's own design, not just a
  cosmetic nit.

## Behavioral deltas worth flagging even where "ported"

- `Settings` still swaps GSettings for a JSON file under `XDG_CONFIG_HOME`
  — documented, not hidden, but still no migration path from a real
  install's existing gschema values.
- `Toast` factory module correctly mirrors upstream's non-subclassable
  `AdwToast` wrapper-function shape (unchanged finding).

## Count

- Upstream user-facing surfaces checked: 70 components + menu + 10
  shortcuts + preferences dialog + ~24 actions + 10 empty/error states.
- At full parity: 0.
- Partially ported with a real, non-trivial gap: 15 (the stems listed
  above under "Windows, dialogs, pages").
- Not ported at all: 55 of 70 catalogued component stems, 21 of 24
  actions, 8 of 10 keyboard shortcuts' actual behavior, the entire
  preferences dialog, 9 of 10 empty/error states, 4 of 4 background
  services.

[1] `test/drive_new_widgets.rb` checks `window.first_child.css_classes`
contains the expected class name string after setting `importance =`;
it does not compare against a live upstream build, only against the
class-name strings read from `gs-context-dialog-row.c`'s source during
this audit.
