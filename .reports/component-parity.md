# Component parity — gnome-software-rb vs origin/main

Per `.claude/skills/component-parity`. Compares each identified port
component against its upstream counterpart behavior-for-behavior, and
checks every upstream window/dialog/page/menu item/shortcut/preference/
action/empty-state/error-state exists in the port.

## Verdict: not at parity. 72 of 80 upstream components have zero port
presence, and every one of the 8 that do have partial, documented gaps.

## Windows, dialogs, pages

- **Main window / shell (`gs-shell.c/.ui`):** NOT PORTED. `lib/shell.rb`
  does not exist. `application.rb` substitutes a static `Adw::StatusPage`
  ("Software" + icon) for the entire view-stack shell — no Explore/
  Installed/Updates/Search pages, no page-switching, no header-bar search
  entry, no back button, no network/metered-connection banners.
- **All 10 top-level pages** (`overview`, `installed`, `updates`, `search`,
  `details`, `category`, `extras`, `loading`, `app_details`, `os_update`):
  NOT PORTED. Zero files.
- **12 dialogs:** 2 of 12 ported (`error_dialog.rb`, `shortcuts_dialog.rb`).
  10 NOT PORTED: prefs, repos, review, app-reviews, version-history,
  update-details, translation, installed-updates, basic-auth, removal,
  remove-app-confirm, dkms.
- **5 context-dialog/row components:** NOT PORTED (0 of 5).
- **6 rows, 6 tiles/cards, 15 composite widgets/sections:** NOT PORTED
  (0 of 27).
- **6 background/integration classes** (update monitor, shell-search
  provider, D-Bus helper, offline-updates provider, language, vendor):
  NOT PORTED (0 of 6). These have no widget tree but are user-facing
  (notifications, GNOME Shell search integration) and are listed as gaps,
  not out of scope, because nothing in `PORTING.md` or the inventory scopes
  them out.

## Menu items

`lib/primary_menu.rb` ports the 2-section structure and both `hidden-when`
items correctly, but of the 4 menu actions only 1 (`app.shortcuts`) is wired
to working behavior in `application.rb`. `app.about` works. `app.sources`
and `app.prefs` are *intentionally* absent (see application.rb comment) —
so the menu items render but will never become clickable because no page
ever registers those actions. That is a real-today gap, not a future one:
the menu is permanently showing fewer live items than upstream's.

## Keyboard shortcuts

Upstream `gs-shell.ui`'s `GtkShortcutController` binds 10 accelerators.
`lib/shortcuts_dialog.rb` lists all 10 correctly as *documentation*, and
`application.rb` wires only 2 of them for real (`<Control>question` →
shortcuts dialog, `<Control>q` → quit). The other 8 (`<Alt>1/2/3`, `<Control>F`,
`F10`, `<Control>comma`, `<Control>period`, `<Alt>F4`, `F5`/`<Control>r`) are
listed in the dialog but do nothing when pressed, because there is no page
stack, search bar, menu-button F10 trigger, prefs dialog, repos dialog, or
update-refresh action for them to invoke. **The shortcuts dialog is lying to
the user about what the app can do** — this is worse than omitting the
dialog, because it is a false affirmative surface.

## Preferences

`gs-prefs-dialog.ui`'s 5 rows across 2 groups: NOT PORTED. `lib/settings.rb`
holds the backing keys (`download-updates`, `download-updates-notify`,
`allow-updates`, `show-only-free-apps`, `show-only-verified-apps`) but no
`PrefsDialog` class or `app.prefs` action exists, so the preferences surface
is completely unreachable from the running app.

## Actions

Upstream registers ~24 app actions. The port's `ACTIONS` table in
`application.rb` has 3 (`about`, `shortcuts`, `quit`). The other ~21
(`verbose`, `nop`, `reboot-and-install`, `reboot`, `restart`, `shutdown`,
`launch`, `show-offline-update-error`, `autoupdate`, `sources`, `prefs`,
`set-mode`, `search`, `details`, `details-pkg`, `details-url`, `install`,
`uninstall`, `filename`, `install-resources`, `show-metainfo`,
`refresh-updates`) do not exist. Command-line options (`--mode`, `--search`,
`--details`, etc.) are not handled anywhere in `exe/gnome-software`, which
is a 3-line launcher with no `ARGV` handling at all.

## Empty, loading and error states

Of the 10 upstream empty/loading/error states cataloged, only the generic
error dialog (`gs-utils-error-dialog-simple.ui` → `error_dialog.rb`) is
ported. The 9 page-specific ones (no-results grids, spinners, EOL banner,
translation banner, screenshot-unavailable fallback, desktop notifications
for install/unavailable/reboot) do not exist, because the pages that would
contain them do not exist.

## Behavioral deltas worth flagging even where "ported"

- `Settings` deliberately swaps GSettings for a JSON file under
  `XDG_CONFIG_HOME` — documented as a conscious deviation, not hidden, so
  not counted as a gap in itself, but no migration/compat path from a real
  GNOME install's existing gschema values is mentioned anywhere.
- `Toast` factory module correctly mirrors upstream's non-subclassable
  `AdwToast` wrapper-function shape.

## Count

- Upstream user-facing surfaces checked: 80 components + menu + 10
  shortcuts + preferences dialog + ~24 actions + 10 empty/error states.
- At full parity: 0.
- Partially ported with a real, non-trivial gap: 8 (error_dialog,
  shortcuts_dialog [content vs behavior mismatch], primary_menu [2 of 4
  items live], application.rb [3 of 24 actions, no CLI, no shell/pages],
  settings, toast, common, page [unused base class]).
- Not ported at all: 72 of 80 catalogued components, 21 of 24 actions, 8 of
  10 keyboard shortcuts' actual behavior, the entire preferences dialog, 9
  of 10 empty/error states.
