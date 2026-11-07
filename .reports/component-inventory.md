# Component inventory — gnome-software-rb (survey)

Upstream: `origin/main` (`git ls-tree -r --name-only origin/main`, 815 files).
Port: `ruby` branch, `lib/` (9 files, 719 lines total).

This is the opening survey of a fresh fork: upstream is a large app (67
`gs-*` widget/page/dialog source files under `src/`, plus plugins, data and
80 translated locales). The totals are the point here, not a per-widget
signal/CSS breakdown — that level of detail (see `component-identification`
skill) belongs to each port unit's own inventory once work starts on it.

## Status of the port today

`lib/` currently has only application-level plumbing:

| `lib/*.rb` | Upstream file it corresponds to | Kind |
|---|---|---|
| `lib/gnome_software/application.rb` | `src/gs-application.c` | application |
| `lib/gnome_software.rb` | (entry point / requires) | — |
| `lib/page.rb` | `src/gs-page.c` | base class |
| `lib/common.rb` | `src/gs-common.c` | utility module |
| `lib/settings.rb` | `data/org.gnome.software.gschema.xml` + `src/gs-common.c` settings helpers | settings wrapper |
| `lib/toast.rb` | `src/gs-toast.c` | utility |
| `lib/error_dialog.rb` | `src/gs-utils-error-dialog-simple.ui` (built by `gs-common.c`) | dialog |
| `lib/shortcuts_dialog.rb` | `src/gs-shortcuts-dialog.ui` / `.c` | dialog |
| `lib/primary_menu.rb` | the primary-menu `<menu>` in `src/gs-shell.ui` | menu |

**Not started: the main window, every page, every list row/tile, and every
context/detail dialog** — i.e. almost the entire visible app. There is no
`lib/shell.rb` / `lib/window.rb` at all, so the app currently has no way to
show a window.

## Full upstream component list (`src/gs-*`)

One row per upstream unit (`.c`+`.h`, and its `.ui` where one exists), the
`lib/*.rb` path it should become under the house one-file-per-unit rule, its
kind, and whether `ruby` has it yet.

### Application / shell

| Upstream file(s) | → `lib/*.rb` | Kind | Exists? |
|---|---|---|---|
| `src/gs-application.c/.h` | `lib/gnome_software/application.rb` | application | **yes** |
| `src/gs-main.c` | (entry point, folds into `exe`/`bin`) | entry point | partial — `bin/`/`exe/` not surveyed here |
| `src/gs-shell.c/.h` + `gs-shell.ui` | `lib/shell.rb` (or `lib/window.rb`) | main window (`AdwApplicationWindow`) — nav view, header bar, search, primary menu host | **no** |
| `src/gs-shell-search-provider.c/.h` | `lib/shell_search_provider.rb` | D-Bus search provider | **no** |
| `src/gs-update-monitor.c/.h` | `lib/update_monitor.rb` | background update-check/notify service | **no** |
| `src/gs-software-offline-updates-provider.c/.h` | `lib/software_offline_updates_provider.rb` | D-Bus helper | **no** |
| `src/gs-dbus-helper.c/.h` | `lib/dbus_helper.rb` | PackageKit D-Bus install helper | **no** |
| `src/gs-vendor.c/.h` | `lib/vendor.rb` | vendor-customisation lookup | **no** |
| `src/gs-language.c/.h` | `lib/language.rb` | locale/language lookup helper | **no** |
| `src/gs-layout-manager.c/.h` | `lib/layout_manager.rb` | custom `GtkLayoutManager` (used by context-dialog rows) | **no** |

### Top-level pages (hosted by the shell's nav view)

| Upstream file(s) | → `lib/*.rb` | Kind | Exists? |
|---|---|---|---|
| `src/gs-page.c/.h` | `lib/page.rb` | abstract page base | **yes** |
| `src/gs-overview-page.c/.h` + `.ui` | `lib/overview_page.rb` | page — featured carousel, category tiles, curated sections | **no** |
| `src/gs-search-page.c/.h` + `.ui` | `lib/search_page.rb` | page — search results list | **no** |
| `src/gs-category-page.c/.h` + `.ui` | `lib/category_page.rb` | page — one category's app list | **no** |
| `src/gs-details-page.c/.h` + `.ui` | `lib/details_page.rb` | page — single app's detail view | **no** |
| `src/gs-app-details-page.c/.h` + `.ui` | `lib/app_details_page.rb` | sub-page — app's permissions/details tab | **no** |
| `src/gs-extras-page.c/.h` + `.ui` | `lib/extras_page.rb` | page — codec/font/mime "search for software that provides X" | **no** |
| `src/gs-installed-page.c/.h` + `.ui` | `lib/installed_page.rb` | page — installed apps list | **no** |
| `src/gs-updates-page.c/.h` + `.ui` | `lib/updates_page.rb` | page — available/history updates | **no** |
| `src/gs-os-update-page.c/.h` + `.ui` | `lib/os_update_page.rb` | page — OS-upgrade progress/details | **no** |
| `src/gs-loading-page.c/.h` + `.ui` | `lib/loading_page.rb` | page — startup loading/empty state | **no** |

### Dialogs

| Upstream file(s) | → `lib/*.rb` | Kind | Exists? |
|---|---|---|---|
| `src/gs-shortcuts-dialog.c/.h` + `.ui` | `lib/shortcuts_dialog.rb` | keyboard-shortcuts dialog | **yes** |
| `src/gs-prefs-dialog.c/.h` + `.ui` | `lib/prefs_dialog.rb` | preferences dialog | **no** |
| `src/gs-repos-dialog.c/.h` + `.ui` | `lib/repos_dialog.rb` | software-repositories dialog | **no** |
| `src/gs-basic-auth-dialog.c/.h` + `.ui` | `lib/basic_auth_dialog.rb` | HTTP basic-auth prompt | **no** |
| `src/gs-review-dialog.c/.h` + `.ui` | `lib/review_dialog.rb` | write/edit a review | **no** |
| `src/gs-app-reviews-dialog.c/.h` + `.ui` | `lib/app_reviews_dialog.rb` | all reviews for an app | **no** |
| `src/gs-app-translation-dialog.c/.h` + `.ui` | `lib/app_translation_dialog.rb` | "help translate this app" dialog | **no** |
| `src/gs-app-update-details-dialog.c/.h` + `.ui` | `lib/app_update_details_dialog.rb` | one update's changelog dialog | **no** |
| `src/gs-app-version-history-dialog.c/.h` + `.ui` | `lib/app_version_history_dialog.rb` | version-history dialog | **no** |
| `src/gs-installed-updates-dialog.c/.h` + `.ui` | `lib/installed_updates_dialog.rb` | "recently installed" updates list dialog | **no** |
| `src/gs-removal-dialog.c/.h` + `.ui` | `lib/removal_dialog.rb` | confirm-uninstall dialog | **no** |
| `src/gs-remove-app-dialog.ui` (no backing `.c`; template loaded by another unit — confirm owner when ported) | `lib/remove_app_dialog.rb` (tentative — may fold into `removal_dialog.rb`) | confirm-uninstall dialog (alternate/newer) | **no** |
| `src/gs-dkms-dialog.c/.h` + `.ui` | `lib/dkms_dialog.rb` | DKMS/third-party-driver consent dialog | **no** |
| `src/gs-info-window.c/.h` + `.ui` | `lib/info_window.rb` | generic info/error window base | **no** |
| `src/gs-age-rating-context-dialog.c/.h` + `.ui` | `lib/age_rating_context_dialog.rb` | app context-info popup: age rating | **no** |
| `src/gs-hardware-support-context-dialog.c/.h` + `.ui` | `lib/hardware_support_context_dialog.rb` | app context-info popup: device support | **no** |
| `src/gs-safety-context-dialog.c/.h` + `.ui` | `lib/safety_context_dialog.rb` | app context-info popup: safety/permissions | **no** |
| `src/gs-storage-context-dialog.c/.h` + `.ui` | `lib/storage_context_dialog.rb` | app context-info popup: storage/size | **no** |
| `src/gs-utils-error-dialog-simple.ui` | `lib/error_dialog.rb` | generic error dialog | **yes** |

### Rows, tiles and other list items

| Upstream file(s) | → `lib/*.rb` | Kind | Exists? |
|---|---|---|---|
| `src/gs-app-row.c/.h` + `.ui` | `lib/app_row.rb` | row — one app in a list (installed/updates/search) | **no** |
| `src/gs-app-addon-row.c/.h` + `.ui` | `lib/app_addon_row.rb` | row — one add-on for an app | **no** |
| `src/gs-app-version-history-row.c/.h` + `.ui` | `lib/app_version_history_row.rb` | row — one version-history entry | **no** |
| `src/gs-context-dialog-row.c/.h` + `.ui` | `lib/context_dialog_row.rb` | row — one fact row inside a context dialog | **no** |
| `src/gs-origin-popover-row.c/.h` + `.ui` | `lib/origin_popover_row.rb` | row — one source/origin choice in the origin popover | **no** |
| `src/gs-repo-row.c/.h` + `.ui` | `lib/repo_row.rb` | row — one repo in the repos dialog | **no** |
| `src/gs-review-row.c/.h` + `.ui` | `lib/review_row.rb` | row — one user review | **no** |
| `src/gs-app-tile.c/.h` + `.ui` | `lib/app_tile.rb` | tile — app grid item (abstract base of feature/category/summary tiles) | **no** |
| `src/gs-feature-tile.c/.h` + `.ui` | `lib/feature_tile.rb` | tile — featured-carousel item | **no** |
| `src/gs-category-tile.c/.h` + `.ui` | `lib/category_tile.rb` | tile — overview-page category item | **no** |
| `src/gs-summary-tile.c/.h` | `lib/summary_tile.rb` | tile — compact app summary item | **no** |
| `src/gs-updates-section.c/.h` + `.ui` | `lib/updates_section.rb` | grouped section of update rows | **no** |
| `src/gs-repos-section.c/.h` | `lib/repos_section.rb` | grouped section of repo rows | **no** |
| `src/gs-update-list.c/.h` | `lib/update_list.rb` | list container for update rows | **no** |

### Stand-alone / supporting widgets

| Upstream file(s) | → `lib/*.rb` | Kind | Exists? |
|---|---|---|---|
| `src/gs-app-context-bar.c/.h` + `.ui` | `lib/app_context_bar.rb` | widget — row of context-info pills on the details page | **no** |
| `src/gs-featured-carousel.c/.h` + `.ui` | `lib/featured_carousel.rb` | widget — overview-page carousel | **no** |
| `src/gs-screenshot-carousel.c/.h` + `.ui` | `lib/screenshot_carousel.rb` | widget — details-page screenshot carousel | **no** |
| `src/gs-screenshot-image.c/.h` + `.ui` | `lib/screenshot_image.rb` | widget — one lazily-loaded screenshot | **no** |
| `src/gs-description-box.c/.h` | `lib/description_box.rb` | widget — expandable app description | **no** |
| `src/gs-license-tile.c/.h` + `.ui` | `lib/license_tile.rb` | widget — license/FOSS-status summary on details page | **no** |
| `src/gs-lozenge.c/.h` + `.ui` | `lib/lozenge.rb` | widget — rounded icon/badge | **no** |
| `src/gs-progress-button.c/.h` + `.ui` | `lib/progress_button.rb` | widget — install/update button with inline progress | **no** |
| `src/gs-review-bar.c/.h` | `lib/review_bar.rb` | widget — one star-rating bar in the histogram | **no** |
| `src/gs-review-histogram.c/.h` + `.ui` | `lib/review_histogram.rb` | widget — 5-star rating histogram | **no** |
| `src/gs-star-widget.c/.h` + `.ui` | `lib/star_widget.rb` | widget — editable/display star rating | **no** |
| `src/gs-star-image.c/.h` | `lib/star_image.rb` | widget — single star icon | **no** |
| `src/gs-toast.c/.h` | `lib/toast.rb` | toast builder | **yes** |
| `src/gs-updates-paused-banner.c/.h` | `lib/updates_paused_banner.rb` | widget — "updates paused" inline banner | **no** |
| `src/gs-upgrade-banner.c/.h` + `.ui` | `lib/upgrade_banner.rb` | widget — OS-upgrade-available banner | **no** |
| `src/gs-common.c/.h` | `lib/common.rb` | utility module (dialogs, helpers, formatting) | **yes** (partial — only the pieces already ported; re-check against upstream's full `gs-common.c` before calling it done) |

### Menus

| Upstream source | → `lib/*.rb` | Kind | Exists? |
|---|---|---|---|
| Primary menu `<menu>` in `src/gs-shell.ui` | `lib/primary_menu.rb` | menu | **yes** |
| Any other `<menu>`/popover models in `gs-app-row.ui`, `gs-repo-row.ui`, `gs-origin-popover-row.ui`, `gs-details-page.ui` (origin-picker popover, row context menus) | fold into their owning row/page file | menu (nested) | **no** — not yet surveyed at the `<menu>` level; re-check each `.ui` once that unit is ported |

### Data files (not Ruby, but required for parity)

| Upstream file | Port equivalent | Kind | Exists? |
|---|---|---|---|
| `data/org.gnome.software.gschema.xml` (35 keys: `allow-updates`, `download-updates`, `first-run`, `show-ratings`, `show-only-free-apps`, `show-only-verified-apps`, etc.) | `lib/settings.rb` + a GSettings schema file in the port's `data/` | GSettings schema | **partial** — `lib/settings.rb` exists but needs checking key-by-key against this list |
| `src/gnome-software.gresource.xml` | the port's own resource bundling (however the Ruby port packages `.ui`/icons, if at all — house style has no `.ui` files) | GResource manifest | **n/a for Ruby port** — note only |
| `src/org.gnome.Software.desktop.in` + `gnome-software-local-file-*.desktop.in` (5 file-type launchers) | app desktop files | desktop launchers | **no** |
| `data/metainfo/org.gnome.Software.metainfo.xml.in` | app metainfo | metainfo | **no** |
| `po/` — 80 locale `.po` files + `po/LINGUAS` | translation catalogue | i18n | **no** — out of scope for this survey; see `translation-parity` skill before claiming any strings are translated |

## Totals

- Upstream `src/gs-*` units: 67 `.c` files (+ matching `.h`), 50 `.ui` templates.
- Upstream also ships `plugins/` (PackageKit, Flatpak, fwupd, snap, epiphany,
  etc.) which are backend data sources, not UI components, and are out of
  scope for a *component* inventory — call them out separately if/when the
  port needs backend parity.
- Port `lib/`: 9 files / 719 lines, covering **4 of ~67** upstream units
  (`gs-application`, `gs-page`, `gs-common` partial, `gs-shortcuts-dialog`)
  plus two extras with no single upstream unit (`settings.rb` wraps the
  gschema, `toast.rb` wraps `gs-toast.c`).
- Not started: the main window/shell, all 10 pages, all 18 dialogs, all 13
  rows/tiles/sections, and all 16 stand-alone widgets. That is the bulk of
  the visible app.

## Open items for whoever picks up the next unit

1. `src/gs-remove-app-dialog.ui` has no backing `.c` file in `origin/main` —
   find its owner (likely built dynamically from `gs-removal-dialog.c` or a
   newer in-flight redesign) before deciding whether it is one dialog or two.
2. `lib/common.rb` (132 lines) is already non-trivial; confirm which of
   upstream `gs-common.c`'s functions it actually covers before assuming the
   file is "done" just because it exists.
3. `lib/settings.rb` needs a key-by-key diff against the 35 keys in
   `data/org.gnome.software.gschema.xml` — this survey only confirms the file
   exists, not that it is complete.
