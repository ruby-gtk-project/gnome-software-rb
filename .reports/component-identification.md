# Component identification — gnome-software-rb vs origin/main

Per `.claude/skills/component-identification`. This round re-identifies both
sides from scratch against the `ruby` branch as it stands after commits
`e3f7a601f`..`3a8f39613` (vendor/language/lozenge, backend gems, drive
script, system_info, progress_button/context_dialog_row/review_bar/
updates_paused_banner/description_box, and the new-widgets drive script).
It supersedes `component-inventory.md` and the prior `component-identification.md`,
both of which were written before several of those commits landed (see
`accountability-ensurance.md` for the staleness finding this causes again).

## Upstream (origin/main)

`git ls-tree -r --name-only origin/main | grep '^src/' | sed -E 's/\.(c|h|ui)$//' | sort -u | grep -c '^src/gs-'`
→ **70 distinct `gs-*` component stems** (each a window, dialog, page, row,
tile, carousel, or composite widget with its own upstream `.c`/`.h` and,
usually, `.ui`). Grouped:

- **Shell/windows (3):** `gs-shell`, `gs-main`, `gs-application`, `gs-info-window`.
- **Pages (10):** overview, installed, updates, search, details,
  app-details, category, extras, loading, os-update.
- **Dialogs (17):** prefs, repos, review, app-reviews, app-version-history,
  app-update-details, app-translation, installed-updates, basic-auth,
  removal, remove-app, dkms, age-rating-context, safety-context,
  hardware-support-context, storage-context, shortcuts.
- **Rows (6):** app-row, app-addon-row, context-dialog-row, origin-popover-row,
  repo-row, review-row, app-version-history-row (7, corrected count).
- **Tiles/cards (5):** app-tile, category-tile, feature-tile, summary-tile,
  license-tile.
- **Composite widgets (≈22):** app-context-bar, featured-carousel,
  screenshot-carousel, screenshot-image, review-bar, review-histogram,
  star-widget, star-image, progress-button, description-box, update-list,
  updates-section, updates-paused-banner, upgrade-banner, repos-section,
  lozenge, toast, vendor, language, layout-manager, common, page (base class).
- **Background/integration (4):** shell-search-provider, dbus-helper,
  software-offline-updates-provider, update-monitor.

Plus non-widget surfaces checked separately: `data/org.gnome.software.gschema.xml`
(35 keys + an `auth` child schema), `src/gs-application.c`'s ~24 `GActionEntry`
rows, `gs-shell.ui`'s `GtkShortcutController` (10 accelerators), and
`po/` (76 `LINGUAS` locales, 135 `POTFILES.in` entries, 1109+ unique msgids
measured off `po/de.po`).

## Port (`ruby` branch, current `lib/`)

`lib/` holds 18 files:

| File | Upstream source | Kind |
|---|---|---|
| `lib/common.rb` | `gs-common.c/.h` (partial) | utility module |
| `lib/context_dialog_row.rb` | `gs-context-dialog-row.c/.h/.ui` | row |
| `lib/description_box.rb` | `gs-description-box.c/.h` | widget |
| `lib/error_dialog.rb` | `gs-utils-error-dialog-simple.ui` | dialog |
| `lib/gnome_software/application.rb` | `gs-application.c/.h` (partial) | app + window chrome |
| `lib/gnome_software.rb` | `gs-main.c` (folded) | entry require graph |
| `lib/gnome/software/rb/version.rb` | n/a | gem version |
| `lib/language.rb` | `gs-language.c/.h` | widget |
| `lib/lozenge.rb` | `gs-lozenge.c/.h/.ui` | widget |
| `lib/page.rb` | `gs-page.c/.h` | abstract base (unsubclassed) |
| `lib/primary_menu.rb` | `gs-shell.ui` `menu id="primary_menu"` | menu |
| `lib/progress_button.rb` | `gs-progress-button.c/.h/.ui` | widget |
| `lib/review_bar.rb` | `gs-review-bar.c/.h` | widget |
| `lib/settings.rb` | `org.gnome.software.gschema.xml` | settings backend (JSON, not GSettings) |
| `lib/shortcuts_dialog.rb` | `gs-shortcuts-dialog.ui` | dialog |
| `lib/system_info.rb` | not upstream (new, for the about dialog's debug info) | widget |
| `lib/toast.rb` | `gs-toast.c/.h` | factory module |
| `lib/updates_paused_banner.rb` | `gs-updates-paused-banner.c/.h` | banner |
| `lib/vendor.rb` | `gs-vendor.c/.h` | widget |

Mapped against the 70-stem upstream count: **15 of 70 stems have any `lib/`
file (21%)**. (`common`, `context_dialog_row`, `description_box`,
`error_dialog`/utils-error-dialog, `application`, `language`, `lozenge`,
`page`, `shortcuts_dialog`, `toast`, `updates_paused_banner`, `vendor`,
`progress_button`, `review_bar`, plus `gs-shell.ui`'s primary-menu fragment.)
`gs-main.c`'s role is folded into the gem's entry point, not counted as a
component. `system_info.rb` is new code with no upstream stem — it does not
add to the 15.

**55 of 70 upstream component stems (79%) have zero `lib/` file at all**,
including every page, 16 of 17 dialogs, 6 of 7 rows, all 5 tiles, and most
composite widgets (`app-context-bar`, carousels, screenshot widgets,
review-histogram, star widgets, license-tile, update-list,
updates-section, upgrade-banner, repos-section, layout-manager), plus all 4
background/integration classes and `gs-shell.c/.ui` itself — the view-stack
shell that every page depends on for navigation.

## Count

- Upstream components: 70 `gs-*` stems, 35 schema keys, ~24 actions, 10
  keyboard shortcuts, 1 prefs surface, 1109+ msgids.
- Port: 15 of 70 stems present (21%), 1 settings surface (partial, JSON not
  GSettings), 3 of ~24 actions wired, 2 of 10 shortcuts wired for real
  behavior, 0 preferences UI, 0 msgids translated.
- **55 of 70 components (79%) do not exist in `lib/` in any form.**

## Round 2 addendum (commit porting lib/shell.rb)

`src/gs-shell.c/h` now has a port, `lib/shell.rb`: the mode enum
(overview/installed/updates), the Adw.ViewStack + view-switcher title,
back-button navigation, the updates-paused banner and toast overlay, and
window-state save/restore (`gs_shell_save_window_state` /
`gs_shell_restore_window_state`), wired into `GnomeSoftware::Application` in
place of the single hardcoded placeholder status page. The per-mode page
*content* is still an `Adw::StatusPage` placeholder, documented in
`lib/shell.rb`'s header comment, because the sub-pages it would host
(overview/installed/updates pages) are not ported yet — those still count
as missing components below. `.reports/component-inventory.md` is deleted
per this file's own note that it superseded that stale snapshot; this file
remains the single source of truth and should be updated again in the same
commit as any future `lib/` addition.

16 of 70 stems now present (23%), one more action closer to full navigation
parity. Everything else in "Still entirely missing" below holds.
