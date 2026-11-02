# gnome-software — upstream component inventory

Survey of `origin/main` (C + GtkBuilder `.ui`) against `lib/` on the `ruby`
branch. Written with the `component-identification` skill; house shape from the
`gnome-contacts-rb` pilot (one upstream unit → one `lib/<thing>.rb`, `gs-`
prefix dropped, kebab → snake).

## Totals

| | Upstream | Port (`ruby`) |
|---|---:|---:|
| source files under `src/` | 202 (71 `.c`, 51 `.ui`) | — |
| library/model files under `lib/` | 123 | — |
| plugins | 19 backends | 0 |
| `.ui` templates / standalone roots | 48 templates + 3 standalone | 0 (`.ui` never used by design) |
| distinct GTK/Adw widget types in `.ui` | 48 | 6 |
| distinct CSS classes in `.ui` + `style.css` | 108 | 0 |
| `GAction`s installed | 25 (`app.*`) | 0 |
| keyboard shortcuts | 9 (4 sections) | 0 |
| GSettings keys | 36 | 0 |
| `po/` catalogues | 76 languages | 0 |
| Ruby files in `lib/` | — | 3 |

The port is a placeholder: `lib/gnome_software/application.rb` is a
`Gtk::Application` + one `Adwaita::StatusPage` reading "The Ruby port has not
been written yet." **No user-facing component below exists yet.** Every
`present` column is therefore `no`; the column is kept so later runs can diff.

## Shell and application

### `src/gs-application.c` → `lib/gnome_software/application.rb` — application, actions, CLI
Exists as a stub (window + status page only); none of the below is ported.

25 `app.*` actions: `about`, `quit`, `verbose`, `nop`, `reboot-and-install`,
`reboot`, `restart`, `shutdown`, `launch(ss)`, `show-offline-update-error`,
`autoupdate`, `sources`, `prefs`, `set-mode(s)`, `search(s)`, `details(ss)`,
`details-pkg(ss)`, `details-url(s)`, `install(su)`, `uninstall(s)`,
`filename(s)`, `install-resources(sassss)`, `show-metainfo(ay)`,
`refresh-updates`, plus `shortcuts` (menu target). CLI options: `--mode`,
`--search`, `--details`, `--details-pkg`, `--install`, `--uninstall`,
`--local-filename`, `--interaction`, `--show-metainfo`, `--verbose`,
`--autoupdate`, `--refresh-updates`, `--prefs`, `--quit`, `--prefer-local`,
`--version`. Also owns the About dialog.

### `src/gs-main.c` → `lib/main.rb` — entry point (`GnomeSoftware::Application.new.build.run`)

### `src/gs-shell.c` + `src/gs-shell.ui` → `lib/shell.rb` — the main window

| Widget | × | CSS | Signals / notes |
|---|---:|---|---|
| `Adw.ApplicationWindow` (template) | 1 | — | `close-request` → `main_window_closed_cb`, `map`, `realize` |
| `Adw.ViewStack` + 8 `Adw.ViewStackPage` | 1 | — | `notify::visible-child`; pages: overview, installed, updates, search, details, category, extras, loading |
| `Adw.Leaflet` + 4 `Adw.LeafletPage` | 1 | — | sub-page/back navigation |
| `Adw.ToolbarView` | 4 | — | one per page group |
| `Gtk.SearchBar` + `Gtk.SearchEntry` | 1 + 1 | — | `notify::search-mode-enabled`, `search-changed` |
| `Gtk.ToggleButton` `search_button` | 1 | `image-button` | toggles the search bar |
| `Gtk.MenuButton` `menu_button` | 1 | — | hosts `primary_menu` |
| `Gtk.Button` `button_back`, `button_back2` | 2 | `image-button` | `gs_shell_back_button_cb`, `gs_shell_details_back_button_cb` |
| `Gtk.Label` `sub_page_header_title` | 1 | `title` | |
| `Gtk.WindowHandle` | 1 | — | |
| `Gtk.ShortcutController` + 5 `Gtk.Shortcut` | 1 | — | the accelerators below |
| 2 `Gtk.EventControllerKey`, 1 `Gtk.GestureClick` | 3 | — | `window_key_pressed_cb`, `window_keypress_handler`, `window_button_pressed_cb` (mouse back) |
| embedded pages | 9 | — | `GsOverviewPage`, `GsInstalledPage`, `GsUpdatesPage`, `GsSearchPage`, `GsDetailsPage`, `GsCategoryPage`, `GsExtrasPage`, `GsLoadingPage`, `GsUpdatesPausedBanner` |

Menu model `primary_menu` (2 sections, 4 items): `_Software Repositories`
(`app.sources`, `hidden-when=action-disabled`), `_Preferences` (`app.prefs`),
`_Keyboard Shortcuts` (`app.shortcuts`), `_About Software` (`app.about`).

### `src/gs-shortcuts-dialog.ui` → `lib/shortcuts_dialog.rb` — standalone `Adw.ShortcutsDialog`, no backing `.c`
4 `Adw.ShortcutsSection`, 10 `Adw.ShortcutsItem`:
Navigation — `<Alt>1` Explore, `<Alt>2` Installed, `<Alt>3` Updates, `<Control>F` search bar, `F10` main menu.
Windows — `<Control>comma` Preferences, `<Control>period` Software Repositories, `<Alt>F4`/`<Control>Q` close.
Updates Page — `F5`/`<Control>r` check for updates.
Help — `<Control>question` this dialog.

### `src/gs-page.c` → `lib/page.rb` — abstract page base
No `.ui`. Holds the install/remove/launch flows every page shares, including
the confirmation dialogs, the "needs reboot" path and the odrs review plumbing.

## Pages

| Upstream | → | Component | Key widgets / CSS / behaviour |
|---|---|---|---|
| `gs-overview-page.c` + `.ui` | `lib/overview_page.rb` | Explore page (`GsPage`) | `GsFeaturedCarousel`, 6 `Gtk.FlowBox` (curated, recent, deployment-featured, all-apps, categories, iconless categories), 5 heading `Gtk.Label` (`heading`), `Adw.StatusPage` `noresults_grid_overview`, `Gtk.Stack` + 2 pages, `Adw.Clamp`; `app-clicked`, 2× `child-activated` (`app_activated_cb`, `category_activated_cb`) |
| `gs-installed-page.c` + `.ui` | `lib/installed_page.rb` | Installed page | 5 `Gtk.ListBox` + 5 `Adw.PreferencesGroup` (apps, in-progress, system apps, addons, web apps), `Adw.Spinner`, `Gtk.Stack`; css `boxed-list`, `list-page`, `section`; `row-activated` |
| `gs-updates-page.c` + `.ui` | `lib/updates_page.rb` | Updates page | `Gtk.Stack` + 7 pages, 4 `Adw.StatusPage` (incl. `updates_failed_page`), 2 `GsUpgradeBanner`, `button_refresh`/`button_stop`/`button_updates_offline`/`button_updates_mobile`, `label_last_checked`, `GtkSpinner` + `AdwSpinnerPaintable`, 2 `Gtk.ShortcutController` + 3 `Gtk.Shortcut` (F5/`<Control>r`); css `pill`, `suggested-action`, `fake-adw-status-page`, `list-page`, `title-1`; targets `app.set-mode` |
| `gs-search-page.c` + `.ui` | `lib/search_page.rb` | Search results | `list_box_search`, 2 `Adw.StatusPage` (no results, error), `Adw.Spinner`, `Gtk.Stack` + 4 pages; css `boxed-list`, `list-page`, `section` |
| `gs-details-page.c` + `.ui` | `lib/details_page.rb` | App details — the largest unit | 17 `Adw.Clamp`, origin `Gtk.MenuButton` + `Gtk.Popover` + `origin_popover_list_box`, `links_stack`, addon/version-history/review list boxes, histogram row, `Gtk.ShortcutController`; 12 signals (install/remove/update/launch/cancel/clear-data buttons, star `pressed`, license-tile `get-involved-activated`, translation banner, link rows, origin rows); css `app-title`, `app-developer`, `details-page`, `origin-button`, `install-progress-label`, `infobox`, `list-button`, `title-1`, `title-2`, `warning`, `info`, `menu`, `card`, `boxed-list`, `icon-dropshadow`, `dim-label`, `flat`, `heading`, `suggested-action` |
| `gs-category-page.c` + `.ui` | `lib/category_page.rb` | One category's apps | `GsFeaturedCarousel` `top_carousel`, 4 `Gtk.FlowBox` (featured, recently updated, other, web apps) + 4 headings, `Adw.Clamp`; `app-clicked`, `child-activated` |
| `gs-extras-page.c` + `.ui` | `lib/extras_page.rb` | Codec/font/driver install page | `list_box_results`, `Adw.StatusPage` `no_results_page` + `failed_page`, `Adw.Spinner`, `Gtk.Stack` + 4 pages; css `boxed-list`, `list-page`, `dim-label` |
| `gs-loading-page.c` + `.ui` | `lib/loading_page.rb` | First-run loading page | `Adw.StatusPage` + `Gtk.ProgressBar`; css `upgrade-progressbar`, `icon-dropshadow` |
| `gs-app-details-page.c` + `.ui` | `lib/app_details_page.rb` | One update's changelog (`Adw.NavigationPage`) | `Gtk.Stack` + 2 pages, `label_details`, `permissions_section` (`Adw.PreferencesGroup` + `Gtk.ListBox`), `Adw.StatusPage`, `Adw.Spinner`, `Adw.ToolbarView` + `Adw.HeaderBar`; css `boxed-list`, `compact` |
| `gs-os-update-page.c` + `.ui` | `lib/os_update_page.rb` | OS update detail (`Adw.NavigationPage`) | `Adw.PreferencesPage` filled at runtime (repeater over update sections) |

## Rows, tiles and inline widgets

| Upstream | → | Component | Key widgets / CSS / behaviour |
|---|---|---|---|
| `gs-app-row.c` + `.ui` | `lib/app_row.rb` | One app in a list (`Gtk.ListBoxRow`) | 11 labels, 3 images, 10 boxes, `Gtk.Revealer` `button_revealer`; css `app`, `header`, `title`, `subtitle`, `caption`, `dim-label`, `icon-dropshadow`, `list-button`, `success`, `warning`, `app-row-origin-text`, `version-arrow-label`; buttons and size label built in `.c` |
| `gs-app-addon-row.c` + `.ui` | `lib/app_addon_row.rb` | Addon row (`Adw.ActionRow`) | `buttons_stack` + 2 `GsProgressButton` (install/remove) |
| `gs-app-version-history-row.c` + `.ui` | `lib/app_version_history_row.rb` | One release | `GsDescriptionBox`, version/date/installed labels; css `history-row-header`, `installed-badge`, `dim-label` |
| `gs-origin-popover-row.c` + `.ui` | `lib/origin_popover_row.rb` | Packaging-source row | 5 labels + 5 images + 7 boxes; css `origin-beta`, `origin-rounded-box`, `app-row-origin-text`, `success`, `dim-label` |
| `gs-repo-row.c` + `.ui` | `lib/repo_row.rb` | One repository | `Gtk.Grid`, `disable_switch`, `remove_button`, name/hostname/comment labels; css `dim-label` |
| `gs-review-row.c` + `.ui` | `lib/review_row.rb` | One user review | `GsStarWidget`, `button_like`/`button_dislike`/`button_report`/`button_remove`, 2 `Gtk.SizeGroup`; css `review-row`, `vote-buttons`, `installed-badge`, `destructive-action`, `flat`, `heading`, `dim-label` |
| `gs-context-dialog-row.c` + `.ui` | `lib/context_dialog_row.rb` | Row inside a context dialog (`Adw.ActionRow`) | `GsLozenge`; css `grey` (+ `green`/`yellow`/`red` set dynamically by importance) |
| `gs-app-tile.c` | `lib/app_tile.rb` | Abstract tile base (`Gtk.FlowBoxChild`), `refresh` vfunc | css `card`, `activatable` |
| `gs-summary-tile.c` + `.ui` | `lib/summary_tile.rb` | Grid tile (`GsAppTile`) | 2 `Gtk.Stack` + 4 pages, `Gtk.Overlay` ×2, `Gtk.Grid`, installed/hardware icons; css `icon-dropshadow`, `loading-icon`, `dim-label`, `success`, `installed-overlay-box` |
| `gs-feature-tile.c` + `.ui` | `lib/feature_tile.rb` | Carousel banner tile (`Gtk.Button`) | `Gtk.Stack` + 2 pages, title/subtitle, `Adw.Clamp`; css `featured-tile`, `title-1`, `caption`, `icon-dropshadow`; key colours computed from the app icon (`lib/gs-key-colors.c`, `gs-css.c`) |
| `gs-category-tile.c` + `.ui` | `lib/category_tile.rb` | Category tile (`Gtk.FlowBoxChild`) | image + label; css `card`, `activatable`, `category-tile`, `icon-dropshadow` |
| `gs-license-tile.c` + `.ui` | `lib/license_tile.rb` | Licence summary tile | 3 `GsLozenge`, `Gtk.ListBox`, `get_involved_button_row` (`Adw.ButtonRow`); `row-activated`; css `boxed-list`, `green` |
| `gs-lozenge.c` + `.ui` | `lib/lozenge.rb` | Pill badge (`Gtk.Box`) | image + label; css `context-tile-lozenge` (+ `grey`/`green`/`yellow`/`red`/`blue`, `large`, `wide-image`) |
| `gs-star-widget.c` + `.ui` | `lib/star_widget.rb` | Interactive star rating | `box1` filled with `GsStarImage`; css `star`; `pressed` |
| `gs-star-image.c` | `lib/star_image.rb` | One star (`Gtk.Widget`, custom snapshot) | css `starred`, `non-starred` |
| `gs-review-bar.c` | `lib/review_bar.rb` | Histogram bar (`Gtk.Widget`, custom snapshot) | — |
| `gs-review-histogram.c` + `.ui` | `lib/review_histogram.rb` | 5-star histogram | 2 `Gtk.Grid`, 15+ `GsStarImage`, `GsReviewBar` rows built in `.c`; css `review-histogram`, `reviewstarvalue` |
| `gs-app-context-bar.c` + `.ui` | `lib/app_context_bar.rb` | The four details-page context tiles | 4 `Gtk.Button` + 4 `GsLozenge` + 8 labels + `Gtk.SizeGroup`; `clicked` → opens the matching context dialog; css `context-tile`, `card`, `flat`, `heading`, `caption`, `grey`/`green`, `details-rating-*`, `wide-image` |
| `gs-screenshot-carousel.c` + `.ui` | `lib/screenshot_carousel.rb` | Screenshot pager | `Adw.Carousel` + `Adw.CarouselIndicatorDots`, 2 `Gtk.Revealer` + prev/next buttons, `Gtk.Stack` + 2 pages; 4 signals; css `osd`, `circular`, `image-button`, `frame`, `view`, `screenshot-image`, `title-2` |
| `gs-screenshot-image.c` + `.ui` | `lib/screenshot_image.rb` | One screenshot or video | `Gtk.Stack` + 4 pages, 2 `Gtk.Picture`, `Gtk.Video`, error box, `Adw.Spinner`; css `screenshot-image`, `image1`, `image2`, `video`, `screenshot-image-main` |
| `gs-featured-carousel.c` + `.ui` | `lib/featured_carousel.rb` | Editor's-choice carousel | `Adw.Carousel` + dots, prev/next, `Gtk.EventControllerKey`, 5s rotation timer; css `featured-carousel`, `card`, `circular`, `flat`, `image-button` |
| `gs-progress-button.c` + `.ui` | `lib/progress_button.rb` | Button with install progress (`Gtk.Button`) | `Gtk.Stack` + 2 pages (label/image); css `install-progress` applied via a CSS provider |
| `gs-description-box.c` | `lib/description_box.rb` | Expandable description (`Gtk.Widget`, custom layout) | css `application-details-description`, `button`, `circular`, `label` |
| `gs-updates-section.c` + `.ui` | `lib/updates_section.rb` | One update group on the Updates page | `listbox`, `section_header`, `button_stack` + 3 `GsProgressButton` (update/download/cancel); `row-activated`, `keynav-failed`; css `boxed-list`, `section`, `heading`, `install-progress`, `suggested-action`, `dim-label`; targets `app.set-mode` |
| `gs-update-list.c` | `lib/update_list.rb` | Sorted list of update rows (`Gtk.Widget`) | css `boxed-list`; repeater over `GsAppList` |
| `gs-upgrade-banner.c` + `.ui` | `lib/upgrade_banner.rb` | Distro-upgrade banner (`Adw.Bin`) | 4 buttons (download/install/cancel ×2), `Gtk.ProgressBar`, 6 labels, `Gtk.SizeGroup`; css `upgrade-banner`, `upgrade-banner-background`, `upgrade-buttons`, `upgrade-progressbar`, `card`, `circular`, `suggested-action` |
| `gs-updates-paused-banner.c` | `lib/updates_paused_banner.rb` | "Updates paused" banner (`Adw.Bin`) | reasons: metered / battery / power-saver |
| `gs-repos-section.c` | `lib/repos_section.rb` | One backend's repo group (`Adw.PreferencesGroup`) | css `boxed-list`; repeater over `GsRepoRow` |
| `gs-layout-manager.c` | `lib/layout_manager.rb` | `Gtk.LayoutManager` subclass used by the custom widgets | not a widget; needed by description box / license tile |

## Dialogs

| Upstream | → | Component | Key widgets / behaviour |
|---|---|---|---|
| `gs-info-window.c` + `.ui` | `lib/info_window.rb` | Base info dialog (`Adw.Dialog`) — parent of all four context dialogs | `Adw.ToolbarView` + `Adw.HeaderBar` + `Adw.WindowTitle`; css `info` |
| `gs-safety-context-dialog.c` + `.ui` | `lib/safety_context_dialog.rb` | Safety context (`GsInfoWindow`) | `permissions_list`, `source_row`/`sdk_row`/`packagename_row`/`license_row`, `sdk_eol_button` + popover, `Adw.ButtonRow` contribute-info; `activated`; css `grey`, `error`, `property`, `large`, `title-2`, `boxed-list`, `flat` |
| `gs-storage-context-dialog.c` + `.ui` | `lib/storage_context_dialog.rb` | Storage breakdown | `sizes_list`, `manage_storage_label` (`activate-link`), lozenge + size group |
| `gs-hardware-support-context-dialog.c` + `.ui` | `lib/hardware_support_context_dialog.rb` | Device support | `relations_list`, lozenge, contribute-info `Adw.ButtonRow` |
| `gs-age-rating-context-dialog.c` + `.ui` | `lib/age_rating_context_dialog.rb` | OARS age rating | `attributes_list` (repeater over ~30 OARS attributes), lozenge, contribute-info row |
| `gs-app-translation-dialog.c` + `.ui` | `lib/app_translation_dialog.rb` | "Help translate" (`GsInfoWindow`) | lozenge, description, `Gtk.Button` (`pill`, `suggested-action`) → `button_clicked_cb` |
| `gs-app-version-history-dialog.c` + `.ui` | `lib/app_version_history_dialog.rb` | Version history (`Adw.Dialog`) | `listbox` of `GsAppVersionHistoryRow`; css `boxed-list` |
| `gs-app-update-details-dialog.c` + `.ui` | `lib/app_update_details_dialog.rb` | Update details (`Adw.Dialog`) | `Adw.NavigationView` hosting `GsAppDetailsPage`/`GsOsUpdatePage` |
| `gs-app-reviews-dialog.c` + `.ui` | `lib/app_reviews_dialog.rb` | All reviews (`Adw.Dialog`) | `listbox` of `GsReviewRow`, `Adw.ToastOverlay`, `Adw.StatusPage` empty state, `Gtk.Stack` |
| `gs-review-dialog.c` + `.ui` | `lib/review_dialog.rb` | Write a review (`Adw.Dialog`) | `GsStarWidget`, `summary_entry` (`Adw.EntryRow`), `text_view`, post/cancel buttons, `Adw.ToastOverlay`, rating-description label; css `review-row`, `review-textbox`, `edit-icon`, `entry`, `smaller` |
| `gs-prefs-dialog.c` + `.ui` | `lib/prefs_dialog.rb` | Preferences (`Adw.PreferencesDialog`) | `automatic_updates_row`/`manual_updates_row` + 2 `Gtk.CheckButton` radios, `automatic_update_notifications_row`, `show_only_free_apps_row`, `show_only_verified_apps_row` (all `Adw.SwitchRow`), `updates_info_button` + popover (`show` → `popover_show_cb`); bound to the GSettings keys below |
| `gs-repos-dialog.c` + `.ui` | `lib/repos_dialog.rb` | Software Repositories (`Adw.Dialog`) | `content_page` filled with `GsReposSection`, `Adw.StatusPage` `status_empty`, `Adw.Spinner`, `Adw.ToastOverlay`, `Gtk.Stack` + 3 pages |
| `gs-removal-dialog.c` + `.ui` | `lib/removal_dialog.rb` | Distro-upgrade removals (`Adw.Dialog`) | `listbox` of apps to be removed, continue (`destructive-action`) / cancel |
| `gs-remove-app-dialog.ui` | `lib/remove_app_dialog.rb` | Uninstall confirmation — standalone `Adw.AlertDialog`, no backing `.c` | `check_keep` / `check_delete` radios in an `Adw.PreferencesGroup`; owned by `gs-page.c` |
| `gs-basic-auth-dialog.c` + `.ui` | `lib/basic_auth_dialog.rb` | HTTP basic auth (`Adw.Dialog`) | `user_entry`, `password_entry`, login (`suggested-action`) / cancel; `changed`/`entry-activated` → `dialog_validate`, `closed` → `close_cb` |
| `gs-dkms-dialog.c` + `.ui` | `lib/dkms_dialog.rb` | DKMS / Secure Boot key enrolment (`Adw.Dialog`) | `Adw.NavigationView` + 2 `Adw.NavigationPage`, `password_label`, `i_have_made_a_note_check`, next / apply (`destructive-action`) / cancel; css `card`, `dim-label` |
| `gs-installed-updates-dialog.c` + `.ui` | `lib/installed_updates_dialog.rb` | Update history (`Adw.Dialog`) | `GsUpdateList`, `Adw.NavigationView`, `Adw.StatusPage` empty state, `Adw.Spinner`, `Gtk.Stack` + 3 pages |
| `gs-utils-error-dialog-simple.ui` | `lib/error_dialog.rb` | Error report dialog — standalone `Adw.Dialog`, no backing `.c` | `label`, `text_view` (`monospace`, in a `card`), copy `button`, `Adw.ToastOverlay`; owned by `gs-common.c` (`gs_utils_show_error_dialog`, `..._simple`, `gs_utils_ask_user_accepts`) |

## Cross-cutting non-widget units that user-facing behaviour depends on

| Upstream | → | Kind | Why it is in scope |
|---|---|---|---|
| `src/gs-common.c` | `lib/common.rb` | helpers | error dialogs, `gs_app_notify_installed`/`unavailable` notifications, reboot notification, size/date formatting, `gs_utils_widget_set_css`, launches `app.details`/`app.launch`/`app.reboot`/`app.set-mode` |
| `src/gs-toast.c` | `lib/toast.rb` | helper | `GsToast` wraps `Adw.Toast` with a button enum (details / show-updates …) used by every toast overlay |
| `src/gs-update-monitor.c` | `lib/update_monitor.rb` | background service | all update/upgrade **notifications** and the offline-update error path; triggers `app.refresh-updates`, `app.set-mode`, `app.show-offline-update-error` |
| `src/gs-shell-search-provider.c` | `lib/shell_search_provider.rb` | D-Bus | GNOME Shell search results (contacts-rb has the same file) |
| `src/gs-dbus-helper.c` | `lib/dbus_helper.rb` | D-Bus | PackageKit `Modify2` "install this codec" entry point → `app.install-resources` |
| `src/gs-software-offline-updates-provider.c` | `lib/offline_updates_provider.rb` | D-Bus | offline-update state exposed to the session |
| `src/gs-language.c`, `src/gs-vendor.c` | `lib/language.rb`, `lib/vendor.rb` | helpers | language names in the translation dialog; vendor URL overrides |
| `lib/gs-desktop-data.c` | `lib/desktop_data.rb` | data | **the category list and all category/subcategory titles** shown on Explore |
| `lib/gs-category.c`, `gs-category-manager.c` | `lib/category.rb`, `lib/category_manager.rb` | model | backs the category page and tiles |
| `lib/gs-app.c`, `gs-app-list.c`, `gs-app-query.c`, `gs-app-permissions.c`, `gs-app-collation.h` | `lib/app.rb`, `lib/app_list.rb`, `lib/app_query.rb`, `lib/app_permissions.rb` | model | every row, tile and page renders a `GsApp`; permissions drive the safety dialog |
| `lib/gs-odrs-provider.c` | `lib/odrs_provider.rb` | service | reviews, ratings, histogram, vote/report |
| `lib/gs-plugin-event.c` | `lib/plugin_event.rb` | model | **error states**: every error banner/toast/dialog is a plugin event |
| `lib/gs-plugin-loader.c` + 18 `gs-plugin-job-*.c` | `lib/plugin_loader.rb`, `lib/plugin_jobs/*.rb` | service | install / remove / update / refine / search / list-apps / file-to-app / manage-repository / offline-update jobs |
| `lib/gs-key-colors.c`, `gs-css.c` | `lib/key_colors.rb`, `lib/css.rb` | helpers | feature-tile background colours and runtime CSS |
| `lib/gs-icon.c`, `gs-icon-downloader.c` | `lib/icon.rb`, `lib/icon_downloader.rb` | helpers | app icons in rows and tiles |
| `lib/gs-job-manager.c`, `gs-metered.c`, `gs-os-release.c`, `gs-download-utils.c`, `gs-fedora-third-party.c`, `gs-dkms-private.c`, `gs-external-appstream-utils.c`, `gs-appstream.c` | `lib/*.rb` | services | progress state, metered-connection pausing, OS name in banners, downloads, third-party repo prompt, DKMS, appstream parsing |
| `src/style.css` | `lib/style.css` (a resource, not a class) | stylesheet | 39 selectors; **the port has none of them**, and ~70 classes used in `.ui` come from libadwaita |
| `data/org.gnome.software.gschema.xml` | `lib/settings.rb` | schema | 36 keys; the ones with UI are `download-updates`, `download-updates-notify`, `show-only-free-apps`, `show-only-verified-apps`, `allow-updates`, `show-ratings`, `enable-repos-dialog`, `installed-page-show-size`, `prompt-for-nonfree`, `first-run`, `packaging-format-preference` |
| `src/gnome-software.gresource.xml` | — | manifest | 51 `.ui`, `style.css`, `up-to-date.svg`, 7 category SVGs and ~70 symbolic icons. The port needs the **icons**; the `.ui` files are replaced by Ruby |
| `po/` (76 languages, `POTFILES.in`) | `po/` | translations | nothing extracted on the port yet |
| `plugins/` (19: core, packagekit, flatpak, snap, fwupd, dkms, dpkg, rpm-ostree, epiphany, malcontent, modalias, repos, systemd-sysupdate, eos-updater, fedora-langpacks, fedora-pkgdb-collections, opensuse-distro-upgrade, …) + `dummy` | `lib/plugins/*.rb` | backends | the `dummy` plugin is what makes the port runnable without a package manager |
| `help/C/*.page` | — | user help | 5 Mallard pages + figures |

## Blockers

1. **Nothing is ported.** `lib/` has 3 files; 51 `.ui` templates, 71 `.c` units
   and 123 model files are outstanding. This is a multi-month port, not a unit.
2. **No `Adwaita::Application`.** The Ruby bindings break it, so `GsShell`
   cannot be an `Adw.ApplicationWindow` subclass the way upstream is; the port
   uses `Gtk::Application` + `Gtk::ApplicationWindow` (already the case in the
   stub) and loses `Adw.ApplicationWindow`'s breakpoint handling.
3. **The whole plugin layer has no Ruby equivalent.** PackageKit, Flatpak,
   fwupd and snap are C libraries with no ruby-gnome bindings. Every page is
   driven by `GsPluginLoader` results, so a `dummy`-plugin-shaped fake backend
   has to come first or no page can be exercised.
4. **Three custom-drawn widgets** (`GsStarImage`, `GsReviewBar`,
   `GsDescriptionBox`) and `GsLayoutManager` need `snapshot`/`measure`/
   `allocate` overrides; `Gtk::LayoutManager` subclassing in Ruby is unverified
   and must be prototyped before `lib/details_page.rb` is attempted.
5. **`.ui` → memoized methods for `gs-details-page.ui` is a 700-line unit.**
   It should be split into several Ruby classes (links section, origin popover,
   addons section, reviews section) rather than one file, which breaks the
   one-file-per-upstream-file rule deliberately.
6. **GtkBuilder templates with app-class parents** (`GsPage`, `GsInfoWindow`,
   `GsAppTile`) mean inheritance has to be reproduced in Ruby before the
   subclasses can be written: `lib/page.rb`, `lib/info_window.rb` and
   `lib/app_tile.rb` are prerequisites for 14 other files.
7. **No `.pot`/`po` pipeline on the port** — 76 catalogues exist upstream and
   `translation-parity` has nothing to compare against yet.
