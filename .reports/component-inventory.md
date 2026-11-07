# Component inventory — gnome-software-rb

Surveyed against `origin/main` (upstream C/GTK4) vs. the `ruby` branch's `lib/`.
Scope: every user-facing window, page, dialog, row, tile, menu, banner,
keyboard-shortcut surface, GSettings schema and GResource/po asset that
upstream ships, mapped to the `lib/*.rb` file it should become (house style:
one upstream file-set → one port file). No app code was written for this
survey.

Legend: kind = `app` (application/shell), `window`, `page`, `dialog`,
`row`, `tile`, `widget` (freestanding non-row/tile widget), `banner`,
`menu`, `data` (schema/resource/i18n, not a widget file).

## Already ported (11 of ~70 component files)

| Upstream file(s) | `lib/` path | Kind | Notes |
|---|---|---|---|
| `src/gs-application.c/h` | `lib/gnome_software/application.rb` | app | Gtk::Application + window chrome (header bar, primary menu, toast overlay) + app.about/app.shortcuts/app.quit actions. Page content is **not** wired — window shows a placeholder `Adw::StatusPage` where `GsShell`'s view stack belongs. |
| `src/gs-main.c` | `exe/gnome-software` + `lib/gnome_software.rb` | app | Entry point / require aggregator |
| `src/gs-common.c/h` (partial) | `lib/common.rb` | widget | Only the pure, framework-agnostic helpers ported; app-data-dir, reboot plumbing, bus-policy formatting explicitly deferred (see file header) |
| `src/gs-utils-error-dialog-simple.ui` + error helper in `gs-common.c` | `lib/error_dialog.rb` | dialog | |
| `src/gs-language.c/h` | `lib/language.rb` | widget | iso_639.xml → language-name lookup |
| `src/gs-lozenge.c/h/.ui` | `lib/lozenge.rb` | widget | |
| `src/gs-page.c/h` | `lib/page.rb` | widget | Abstract base class only; no concrete page extends it yet |
| top `menu id="primary_menu"` in `src/gs-shell.ui` | `lib/primary_menu.rb` | menu | |
| `data/org.gnome.software.gschema.xml` (+ its `auth` child schema) | `lib/settings.rb` | data | |
| `src/gs-shortcuts-dialog.ui` | `lib/shortcuts_dialog.rb` | dialog | |
| `src/gs-toast.c/h` | `lib/toast.rb` | widget | |
| `src/gs-vendor.c/h` | `lib/vendor.rb` | widget | |
| (new, not upstream) backend diagnostics for the about dialog's debug info | `lib/system_info.rb` | widget | Exercises `appstream`/`flatpak`/`gudev`/`packagekit-glib`/`polkit`/`soup3`/`malcontent` |

## Not yet ported — shell, pages, background services

| Upstream file(s) | Target `lib/` path | Kind | Present |
|---|---|---|---|
| `src/gs-shell.c/h`, `src/gs-shell.ui` | `lib/shell.rb` | window | No — the view-stack, back/forward nav, search bar, and page-switching that `GnomeSoftware::Application` stubs out with a status page |
| `src/gs-shell-search-provider.c/h` + `src/shell-search-provider-dbus-interfaces.xml` | `lib/shell_search_provider.rb` | app | No — GNOME Shell search provider D-Bus service |
| `src/gs-dbus-helper.c/h` + `src/org.freedesktop.PackageKit.Modify2.xml` + `src/org.freedesktop.PackageKit.service.in` | `lib/dbus_helper.rb` | app | No — PackageKit Modify2 compat D-Bus service |
| `src/gs-software-offline-updates-provider.c/h` + `src/org.gnome.Software.OfflineUpdates.xml` | `lib/software_offline_updates_provider.rb` | app | No |
| `src/gs-update-monitor.c/h` | `lib/update_monitor.rb` | app | No — background update checks + desktop notifications |
| `src/gs-layout-manager.c/h` | `lib/layout_manager.rb` | widget | No — custom `Gtk::LayoutManager` used by context-dialog rows |
| `src/gs-loading-page.c/h/.ui` | `lib/loading_page.rb` | page | No — first-run plugin-loader splash |
| `src/gs-overview-page.c/h/.ui` | `lib/overview_page.rb` | page | No — "Explore" page: featured carousel, category tiles, curated lists |
| `src/gs-installed-page.c/h/.ui` | `lib/installed_page.rb` | page | No |
| `src/gs-updates-page.c/h/.ui` | `lib/updates_page.rb` | page | No |
| `src/gs-search-page.c/h/.ui` | `lib/search_page.rb` | page | No |
| `src/gs-details-page.c/h/.ui` | `lib/details_page.rb` | page | No — per-app detail view; largest page, owns install/remove flow |
| `src/gs-category-page.c/h/.ui` | `lib/category_page.rb` | page | No |
| `src/gs-extras-page.c/h/.ui` | `lib/extras_page.rb` | page | No — codec/font/mime-handler search ("extras") |
| `src/gs-os-update-page.c/h/.ui` | `lib/os_update_page.rb` | page | No — distro-upgrade progress page |

## Not yet ported — dialogs

| Upstream file(s) | Target `lib/` path | Kind | Present |
|---|---|---|---|
| `src/gs-prefs-dialog.c/h/.ui` | `lib/prefs_dialog.rb` | dialog | No |
| `src/gs-repos-dialog.c/h/.ui` | `lib/repos_dialog.rb` | dialog | No |
| `src/gs-removal-dialog.c/h/.ui` | `lib/removal_dialog.rb` | dialog | No |
| `src/gs-remove-app-dialog.ui` (no backing `.c`; built inline by details page) | `lib/remove_app_dialog.rb` | dialog | No |
| `src/gs-review-dialog.c/h/.ui` | `lib/review_dialog.rb` | dialog | No |
| `src/gs-app-reviews-dialog.c/h/.ui` | `lib/app_reviews_dialog.rb` | dialog | No |
| `src/gs-app-translation-dialog.c/h/.ui` | `lib/app_translation_dialog.rb` | dialog | No |
| `src/gs-app-update-details-dialog.c/h/.ui` | `lib/app_update_details_dialog.rb` | dialog | No |
| `src/gs-app-version-history-dialog.c/h/.ui` | `lib/app_version_history_dialog.rb` | dialog | No |
| `src/gs-installed-updates-dialog.c/h/.ui` | `lib/installed_updates_dialog.rb` | dialog | No |
| `src/gs-basic-auth-dialog.c/h/.ui` | `lib/basic_auth_dialog.rb` | dialog | No |
| `src/gs-dkms-dialog.c/h/.ui` | `lib/dkms_dialog.rb` | dialog | No |
| `src/gs-info-window.c/h/.ui` | `lib/info_window.rb` | window | No |
| `src/gs-age-rating-context-dialog.c/h/.ui` | `lib/age_rating_context_dialog.rb` | dialog | No |
| `src/gs-safety-context-dialog.c/h/.ui` | `lib/safety_context_dialog.rb` | dialog | No |
| `src/gs-hardware-support-context-dialog.c/h/.ui` | `lib/hardware_support_context_dialog.rb` | dialog | No |
| `src/gs-storage-context-dialog.c/h/.ui` | `lib/storage_context_dialog.rb` | dialog | No |
| `src/gs-context-dialog-row.c/h/.ui` | `lib/context_dialog_row.rb` | row | No — shared row type used by the four context dialogs above |

## Not yet ported — rows, tiles, carousels, banners, misc widgets

| Upstream file(s) | Target `lib/` path | Kind | Present |
|---|---|---|---|
| `src/gs-app-row.c/h/.ui` | `lib/app_row.rb` | row | No — generic app list row (Installed/Updates/search results) |
| `src/gs-app-addon-row.c/h/.ui` | `lib/app_addon_row.rb` | row | No |
| `src/gs-app-context-bar.c/h/.ui` | `lib/app_context_bar.rb` | widget | No — the storage/safety/age/hardware pill row on the details page |
| `src/gs-app-tile.c/h` (no `.ui`) | `lib/app_tile.rb` | tile | No |
| `src/gs-category-tile.c/h/.ui` | `lib/category_tile.rb` | tile | No |
| `src/gs-feature-tile.c/h/.ui` | `lib/feature_tile.rb` | tile | No |
| `src/gs-summary-tile.c/h/.ui` | `lib/summary_tile.rb` | tile | No |
| `src/gs-featured-carousel.c/h/.ui` | `lib/featured_carousel.rb` | widget | No — overview-page banner carousel |
| `src/gs-screenshot-carousel.c/h/.ui` | `lib/screenshot_carousel.rb` | widget | No |
| `src/gs-screenshot-image.c/h` | `lib/screenshot_image.rb` | widget | No |
| `src/gs-origin-popover-row.c/h/.ui` | `lib/origin_popover_row.rb` | row | No — package-source picker popover row |
| `src/gs-repo-row.c/h/.ui` | `lib/repo_row.rb` | row | No |
| `src/gs-repos-section.c/h` (no `.ui`) | `lib/repos_section.rb` | widget | No |
| `src/gs-review-row.c/h/.ui` | `lib/review_row.rb` | row | No |
| `src/gs-review-bar.c/h` (no `.ui`) | `lib/review_bar.rb` | widget | No — rating-histogram bar |
| `src/gs-review-histogram.c/h/.ui` | `lib/review_histogram.rb` | widget | No |
| `src/gs-star-widget.c/h/.ui` | `lib/star_widget.rb` | widget | No |
| `src/gs-star-image.c/h` (no `.ui`) | `lib/star_image.rb` | widget | No |
| `src/gs-license-tile.c/h/.ui` | `lib/license_tile.rb` | widget | No |
| `src/gs-progress-button.c/h/.ui` | `lib/progress_button.rb` | widget | No |
| `src/gs-description-box.c/h` (no `.ui`) | `lib/description_box.rb` | widget | No — expandable app-description text |
| `src/gs-update-list.c/h` (no `.ui`) | `lib/update_list.rb` | widget | No |
| `src/gs-updates-section.c/h/.ui` | `lib/updates_section.rb` | widget | No |
| `src/gs-updates-paused-banner.c/h` (no `.ui`) | `lib/updates_paused_banner.rb` | banner | No |
| `src/gs-app-version-history-row.c/h/.ui` | `lib/app_version_history_row.rb` | row | No |

## Not widgets — data, resources, i18n

| Upstream file(s) | Where it lands | Notes |
|---|---|---|
| `data/metainfo/org.gnome.Software.metainfo.xml.in` | app packaging, not `lib/` | AppStream metainfo; needed for the port's own `data/` once packaged |
| `data/org.gnome.software.dkms-helper.policy.in.in`, `data/org.gnome.software.external-appstream.policy.in.in` | polkit policy files | Back the (unported) DKMS dialog and external-appstream refresh; no `lib/` file yet depends on them |
| `src/gnome-software.gresource.xml` | N/A for the port | GResource bundles the `.ui` templates upstream compiles in; the Ruby house style builds widgets in code, so there is no equivalent manifest to port |
| `src/style.css` | not yet reflected anywhere in `lib/` | Upstream's custom CSS classes (`icon-dropshadow`, lozenge styling, etc.); several are already referenced ad hoc (e.g. `application.rb`'s `icon-dropshadow`) but no central stylesheet/loader exists |
| `po/*.po` (76 locales) + `po/LINGUAS`, `po/POTFILES.in` | translation-parity concern, not `lib/` | No `po/` directory exists yet on `ruby`; out of scope for this component survey (see the `translation-parity` skill) |
| `src/org.gnome.Software.desktop.in` + `src/gnome-software-local-file-*.desktop.in` | app packaging | Desktop launcher + file-association stubs for Flatpak/fwupd/metainfo/PackageKit/snap local-file handling; no `lib/` equivalent needed, but the actions they invoke (`--local-filename`) are unimplemented in `gs-main.c`'s port |

## Totals

- Upstream component-bearing files (`.c`/`.h`/`.ui` pairs, counted once per
  component): **53** distinct components across shell/pages/dialogs/rows/tiles/widgets.
- Ported on `ruby`: **11** (all infrastructure/chrome — no page, dialog, row,
  tile or carousel has a `lib/` file yet).
- Not ported: **42** components, including every page in the main view
  stack, every dialog, and all app-list/review/context-dialog rows and tiles.
- The application window (`lib/gnome_software/application.rb`) currently
  presents a placeholder status page in place of the entire page/navigation
  tree (`GsShell`) — porting `lib/shell.rb` is the natural next unit, since
  every page above depends on it for navigation.
