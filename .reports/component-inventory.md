# gnome-software — upstream component inventory

Survey of the user-facing components on `origin/main` (GNOME Software, C +
GtkBuilder `.ui`), mapped onto the Ruby port's `lib/*.rb` house shape.

Read with `git show origin/main:<path>`. Upstream splits most components across
three files — `gs-foo.c`, `gs-foo.h` and `gs-foo.ui` — and the component is the
set, not the file. The `.ui` carries the widget tree, the CSS classes and the
signal handler names; the `.c` carries the callbacks, the properties and the
actions. Both halves collapse into one `lib/<thing>.rb`.

## Status summary

`lib/` on `ruby` currently holds three files:

| Path | What it is |
|---|---|
| `lib/gnome_software.rb` | entry point, requires `gnome_software/application` |
| `lib/gnome_software/application.rb` | scaffold `Gtk::Application` + `Adwaita::StatusPage` placeholder |
| `lib/gnome/software/rb/version.rb` | gem version constant |

**No component has been ported.** Every row below is `present: no`. The
scaffold `application.rb` is the only thing that will be rewritten rather than
created.

## Shell, application and chrome

| Upstream | Port path | Kind | Present |
|---|---|---|---|
| `src/gs-application.c`, `src/gs-application.h` | `lib/gnome_software/application.rb` | application | scaffold only |
| `src/gs-shell.c`, `src/gs-shell.h`, `src/gs-shell.ui` | `lib/shell.rb` | window | no |
| `src/gs-shell.ui` (`menu id="primary_menu"`) | `lib/primary_menu.rb` | menu | no |
| `src/gs-shortcuts-dialog.ui` | `lib/shortcuts_dialog.rb` | dialog (keyboard shortcuts) | no |
| `src/gs-page.c`, `src/gs-page.h` | `lib/page.rb` | abstract base (install/remove/launch flows) | no |
| `src/gs-main.c` | folded into `exe/` launcher | entry point | no |
| `src/gs-common.c`, `src/gs-common.h` | `lib/common.rb` | utility + error dialogs + notifications | no |
| `src/gs-utils-error-dialog-simple.ui` | `lib/error_dialog.rb` | error state (`AdwDialog`) | no |
| `src/gs-toast.c`, `src/gs-toast.h` | `lib/toast.rb` | transient feedback (`AdwToast` factory) | no |
| `src/gs-info-window.c/.h/.ui` | `lib/info_window.rb` | dialog base (`AdwDialog` subclass) | no |
| `src/gs-layout-manager.c/.h` | `lib/layout_manager.rb` | layout manager base | no |

## Top-level pages (children of the view stack)

| Upstream | Port path | Kind | Present |
|---|---|---|---|
| `src/gs-overview-page.c/.h/.ui` | `lib/overview_page.rb` | page (Explore) + empty state `noresults_grid_overview` | no |
| `src/gs-installed-page.c/.h/.ui` | `lib/installed_page.rb` | page (Installed) | no |
| `src/gs-updates-page.c/.h/.ui` | `lib/updates_page.rb` | page (Updates) + EOL banner | no |
| `src/gs-search-page.c/.h/.ui` | `lib/search_page.rb` | page (Search results) | no |
| `src/gs-details-page.c/.h/.ui` | `lib/details_page.rb` | page (app details) + translation banner | no |
| `src/gs-category-page.c/.h/.ui` | `lib/category_page.rb` | sub-page (category browse) | no |
| `src/gs-extras-page.c/.h/.ui` | `lib/extras_page.rb` | sub-page (codec/font/driver search) | no |
| `src/gs-loading-page.c/.h/.ui` | `lib/loading_page.rb` | page (first-run loading status page) | no |
| `src/gs-app-details-page.c/.h/.ui` | `lib/app_details_page.rb` | navigation page (update details body) | no |
| `src/gs-os-update-page.c/.h/.ui` | `lib/os_update_page.rb` | navigation page (OS update breakdown) | no |

## Dialogs

| Upstream | Port path | Kind | Present |
|---|---|---|---|
| `src/gs-prefs-dialog.c/.h/.ui` | `lib/prefs_dialog.rb` | preferences (`AdwPreferencesDialog`) | no |
| `src/gs-repos-dialog.c/.h/.ui` | `lib/repos_dialog.rb` | dialog (Software Repositories) | no |
| `src/gs-review-dialog.c/.h/.ui` | `lib/review_dialog.rb` | dialog (write a review) | no |
| `src/gs-app-reviews-dialog.c/.h/.ui` | `lib/app_reviews_dialog.rb` | dialog (all reviews) | no |
| `src/gs-app-version-history-dialog.c/.h/.ui` | `lib/app_version_history_dialog.rb` | dialog (version history) | no |
| `src/gs-app-update-details-dialog.c/.h/.ui` | `lib/app_update_details_dialog.rb` | dialog (what's new) | no |
| `src/gs-app-translation-dialog.c/.h/.ui` | `lib/app_translation_dialog.rb` | dialog (help translate) | no |
| `src/gs-installed-updates-dialog.c/.h/.ui` | `lib/installed_updates_dialog.rb` | dialog (recently installed updates) | no |
| `src/gs-basic-auth-dialog.c/.h/.ui` | `lib/basic_auth_dialog.rb` | dialog (HTTP basic auth prompt) | no |
| `src/gs-removal-dialog.c/.h/.ui` | `lib/removal_dialog.rb` | dialog (apps removed by an upgrade) | no |
| `src/gs-remove-app-dialog.ui` | `lib/remove_app_dialog.rb` | alert dialog (`AdwAlertDialog`, uninstall confirm) | no |
| `src/gs-dkms-dialog.c/.h/.ui` | `lib/dkms_dialog.rb` | dialog (DKMS / secure boot key enrolment) | no |

### Context dialogs (details-page "lozenge" drill-downs, all `GsInfoWindow`)

| Upstream | Port path | Kind | Present |
|---|---|---|---|
| `src/gs-safety-context-dialog.c/.h/.ui` | `lib/safety_context_dialog.rb` | dialog | no |
| `src/gs-storage-context-dialog.c/.h/.ui` | `lib/storage_context_dialog.rb` | dialog | no |
| `src/gs-hardware-support-context-dialog.c/.h/.ui` | `lib/hardware_support_context_dialog.rb` | dialog | no |
| `src/gs-age-rating-context-dialog.c/.h/.ui` | `lib/age_rating_context_dialog.rb` | dialog | no |
| `src/gs-context-dialog-row.c/.h/.ui` | `lib/context_dialog_row.rb` | row (`AdwActionRow`, shared by the four above) | no |

## Rows

| Upstream | Port path | Kind | Present |
|---|---|---|---|
| `src/gs-app-row.c/.h/.ui` | `lib/app_row.rb` | row (`GtkListBoxRow`, the app list workhorse) | no |
| `src/gs-app-addon-row.c/.h/.ui` | `lib/app_addon_row.rb` | row (`AdwActionRow`, addon with checkbox) | no |
| `src/gs-app-version-history-row.c/.h/.ui` | `lib/app_version_history_row.rb` | row | no |
| `src/gs-review-row.c/.h/.ui` | `lib/review_row.rb` | row (review with vote/report actions) | no |
| `src/gs-repo-row.c/.h/.ui` | `lib/repo_row.rb` | row (repository, enable/disable/remove) | no |
| `src/gs-origin-popover-row.c/.h/.ui` | `lib/origin_popover_row.rb` | row (package source picker) | no |

## Tiles and cards

| Upstream | Port path | Kind | Present |
|---|---|---|---|
| `src/gs-app-tile.c/.h` | `lib/app_tile.rb` | abstract tile base | no |
| `src/gs-summary-tile.c/.h/.ui` | `lib/summary_tile.rb` | tile (`GsAppTile` subclass) | no |
| `src/gs-feature-tile.c/.h/.ui` | `lib/feature_tile.rb` | tile (large featured card) | no |
| `src/gs-category-tile.c/.h/.ui` | `lib/category_tile.rb` | tile (`GtkFlowBoxChild`) | no |
| `src/gs-license-tile.c/.h/.ui` | `lib/license_tile.rb` | card (license + get-involved) | no |
| `src/gs-lozenge.c/.h/.ui` | `lib/lozenge.rb` | widget (context-bar pill) | no |

## Composite widgets and sections

| Upstream | Port path | Kind | Present |
|---|---|---|---|
| `src/gs-app-context-bar.c/.h/.ui` | `lib/app_context_bar.rb` | widget (the four lozenge tiles) | no |
| `src/gs-featured-carousel.c/.h/.ui` | `lib/featured_carousel.rb` | widget (`AdwCarousel` of feature tiles) | no |
| `src/gs-screenshot-carousel.c/.h/.ui` | `lib/screenshot_carousel.rb` | widget | no |
| `src/gs-screenshot-image.c/.h/.ui` | `lib/screenshot_image.rb` | widget (loading + error states) | no |
| `src/gs-description-box.c/.h` | `lib/description_box.rb` | widget (expandable description) | no |
| `src/gs-star-widget.c/.h/.ui` | `lib/star_widget.rb` | widget (rating stars) | no |
| `src/gs-star-image.c/.h` | `lib/star_image.rb` | widget (one star, partial fill) | no |
| `src/gs-review-histogram.c/.h/.ui` | `lib/review_histogram.rb` | widget | no |
| `src/gs-review-bar.c/.h` | `lib/review_bar.rb` | widget (one histogram bar) | no |
| `src/gs-progress-button.c/.h/.ui` | `lib/progress_button.rb` | widget (install button with progress) | no |
| `src/gs-update-list.c/.h` | `lib/update_list.rb` | widget (`GtkListBox` of app rows) | no |
| `src/gs-updates-section.c/.h/.ui` | `lib/updates_section.rb` | section (one update group + header) | no |
| `src/gs-updates-paused-banner.c/.h` | `lib/updates_paused_banner.rb` | banner / status widget | no |
| `src/gs-upgrade-banner.c/.h/.ui` | `lib/upgrade_banner.rb` | banner (distro upgrade available) | no |
| `src/gs-repos-section.c/.h` | `lib/repos_section.rb` | section (repo group in repos dialog) | no |

## Background and integration (no widget tree, but user-facing behaviour)

| Upstream | Port path | Kind | Present |
|---|---|---|---|
| `src/gs-update-monitor.c/.h` | `lib/update_monitor.rb` | notifications + periodic update checks | no |
| `src/gs-shell-search-provider.c/.h` | `lib/shell_search_provider.rb` | D-Bus search provider (GNOME Shell) | no |
| `src/gs-dbus-helper.c/.h` | `lib/dbus_helper.rb` | PackageKit `Modify2` session service | no |
| `src/gs-software-offline-updates-provider.c/.h` | `lib/offline_updates_provider.rb` | D-Bus offline-updates provider | no |
| `src/gs-language.c/.h` | `lib/language.rb` | locale name lookup for the translation dialog | no |
| `src/gs-vendor.c/.h` | `lib/vendor.rb` | vendor override lookup | no |

## Non-source assets

| Upstream | Port handling | Present |
|---|---|---|
| `src/style.css` | `data/style.css`, loaded via `Gtk::CssProvider` | no |
| `src/gnome-software.gresource.xml` | no GResource in the port; `.ui` files are not ported (widgets are memoized methods), icons load from a `data/icons` path prepended to `Gtk::IconTheme` | n/a |
| `data/org.gnome.software.gschema.xml` (35 keys) | `lib/settings.rb` wrapping `Gio::Settings` | no |
| `data/assets/org.gnome.Software.Featured.xml`, `...Curated.xml` | featured/curated app lists read by the overview page | no |
| `data/icons/symbolic/**` (incl. `ratings/`) | copied into the port's `data/icons` | no |
| `src/org.gnome.Software.desktop.in`, `src/gnome-software-local-file-*.desktop.in` | desktop entries + MIME handlers | no |
| `src/*.xml` D-Bus interfaces (`org.freedesktop.PackageKit`, `shell-search-provider`, `org.gnome.Software.OfflineUpdates`) | consumed by the integration classes above | no |
| `po/` — 76 locales (`po/LINGUAS`), 135 entries in `po/POTFILES.in` | gettext via `GLib::I18n` / `_()`; catalogues copied over | no |

## Actions and accelerators to install

Application actions (`src/gs-application.c`), split across the pre-startup and
post-startup tables:

`about`, `quit`, `verbose`, `nop`, `reboot-and-install`, `reboot`, `restart`,
`shutdown`, `launch("(ss)")`, `show-offline-update-error`, `autoupdate`,
`sources`, `prefs`, `set-mode("s")`, `search("s")`, `details("(ss)")`,
`details-pkg("(ss)")`, `details-url("(s)")`, `install("(su)")`,
`uninstall("s")`, `filename("(s)")`, `install-resources("(sassss)")`,
`show-metainfo("(ay)")`, `refresh-updates`, plus `app.shortcuts` targeted by
the primary menu.

Keyboard shortcuts (`src/gs-shortcuts-dialog.ui` and the `GtkShortcutController`
in `src/gs-shell.ui`):

| Accelerator | Action |
|---|---|
| `<Alt>1` | Navigate to Explore page |
| `<Alt>2` | Navigate to Installed page |
| `<Alt>3` | Navigate to Updates page |
| `<Control>F` | Open search bar |
| `F10` | Open main menu |
| `<Control>comma` | Open Preferences |
| `<Control>period` | Open Software Repositories |
| `<Alt>F4`, `<Control>Q` | Close main window |
| `F5`, `<Control>r` | Check for updates |
| `<Control>question` | Open keyboard shortcuts |

Command-line options handled by the application: `--mode`, `--search`,
`--details`, `--details-pkg`, `--install`, `--uninstall`, `--local-filename`,
`--interaction`, `--show-metainfo`, `--verbose`, `--autoupdate`,
`--refresh-updates`, `--prefs`, `--quit`, `--prefer-local`, `--version`.

## Preferences surface

`src/gs-prefs-dialog.ui` — `AdwPreferencesDialog` titled "Preferences":

- group **Software Updates**, with a `GtkMenuButton` info popover
  (`updates_info_button` / `updates_info_label`)
  - `automatic_updates_row` (`AdwActionRow` + `GtkCheckButton` radio) —
    "_Automatic" / "Automatically check for and download updates"
  - `manual_updates_row` (`AdwActionRow` + `GtkCheckButton` radio) —
    "_Manual" / "Checking for and downloading updates must be done manually"
  - `automatic_update_notifications_row` (`AdwSwitchRow`) —
    "Automatic Update _Notifications"
- group **Content Filters**
  - `show_only_free_apps_row` (`AdwSwitchRow`) — "Only Show _Free Software"
  - `show_only_verified_apps_row` (`AdwSwitchRow`) — "Only Show _Verified Developers"

Backed by the gschema keys `download-updates`, `download-updates-notify`,
`allow-updates`, `show-only-free-apps`, `show-only-verified-apps`.

## Empty, loading and error states

| Where | What |
|---|---|
| `src/gs-overview-page.ui` | `AdwStatusPage noresults_grid_overview` — no apps found |
| `src/gs-search-page.ui` | `AdwSpinner spinner_search` + no-results state |
| `src/gs-installed-page.ui` | `AdwSpinner spinner_install` |
| `src/gs-extras-page.ui` | `AdwSpinner spinner` + per-app failure messages |
| `src/gs-loading-page.ui` | `AdwStatusPage` — first-run metadata download |
| `src/gs-app-details-page.ui` | `AdwStatusPage` |
| `src/gs-screenshot-image.ui` | `AdwSpinner` + screenshot-unavailable fallback |
| `src/gs-updates-page.ui` | `AdwBanner banner_end_of_life`, up-to-date state (`data/assets/up-to-date.svg`) |
| `src/gs-details-page.ui` | `AdwBanner translation_banner` |
| `src/gs-utils-error-dialog-simple.ui`, `gs_utils_show_error_dialog*` | error dialogs |
| `src/gs-common.c` (`gs_app_notify_installed`, `gs_app_notify_unavailable`, `gs_utils_reboot_notify`) | desktop notifications |

## Port ordering

1. `lib/common.rb`, `lib/settings.rb`, `lib/toast.rb`, `lib/info_window.rb` —
   the shared base everything else calls.
2. `lib/page.rb`, `lib/shell.rb`, `lib/primary_menu.rb`,
   `lib/shortcuts_dialog.rb`, rewritten `application.rb` — the frame, with the
   four stack pages stubbed.
3. `lib/app_row.rb`, `lib/app_tile.rb`, `lib/summary_tile.rb`,
   `lib/feature_tile.rb`, `lib/category_tile.rb`, `lib/progress_button.rb` —
   the repeating elements every page needs.
4. `lib/overview_page.rb`, `lib/installed_page.rb`, `lib/updates_page.rb`,
   `lib/search_page.rb` — the four real pages, plus
   `lib/featured_carousel.rb`, `lib/update_list.rb`, `lib/updates_section.rb`.
5. `lib/details_page.rb` and its subtree — `app_context_bar`, `lozenge`,
   `license_tile`, `description_box`, `screenshot_carousel`,
   `screenshot_image`, `star_widget`, `star_image`, `review_histogram`,
   `review_bar`, `review_row`, `origin_popover_row`, `app_addon_row`.
6. The dialogs — prefs, repos, reviews, version history, update details,
   translation, context dialogs, removal, basic auth, DKMS.
7. `lib/category_page.rb`, `lib/extras_page.rb`, `lib/os_update_page.rb`,
   `lib/app_details_page.rb`, `lib/loading_page.rb`, `lib/upgrade_banner.rb`,
   `lib/updates_paused_banner.rb`.
8. Background integration — `update_monitor`, `shell_search_provider`,
   `dbus_helper`, `offline_updates_provider`, `language`, `vendor`.
9. `po/` catalogues and `data/style.css`.

## Count

80 components across 10 groups; 0 ported, 1 (`application.rb`) present as a
scaffold to be replaced.
