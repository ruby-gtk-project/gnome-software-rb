# Component identification — gnome-software-rb vs origin/main

Ran per `.claude/skills/component-identification`. This supersedes the
component census in `component-inventory.md` (written before the current
`lib/` landed) by re-identifying both sides as they exist right now.

## Upstream (origin/main)

80 components enumerated across 10 groups in `component-inventory.md`
(shell/chrome, 10 top-level pages, 12 dialogs, 5 context dialogs/rows, 6
rows, 6 tiles/cards, 15 composite widgets/sections, 6 background/integration
classes, plus the actions/accelerators/preferences/empty-state surface).
That inventory's type/CSS-class/signal/action/owner breakdown is accurate
and is not repeated here. Confirmed still current: `git ls-tree -r
--name-only origin/main | wc -l` → 815 files, `src/gs-*.c` count unchanged.

## Port (`ruby` branch, current `lib/`)

`lib/` now holds 10 files (up from the 3 the stale inventory described):

| File | Upstream source | Component built | Facets present |
|---|---|---|---|
| `lib/common.rb` | `src/gs-common.c/.h` (partial) | utility module | types/logic only — no widget, N/A for CSS/signals |
| `lib/error_dialog.rb` | `src/gs-utils-error-dialog-simple.ui` | dialog | type, CSS (`title-1`, `card`, `flat`, `monospace`, `inline`), 1 signal (`copy_button` `clicked`), owner comment present |
| `lib/page.rb` | `src/gs-page.c/.h` | abstract base | type/lifecycle methods only; no subclass exists yet to exercise it |
| `lib/primary_menu.rb` | `gs-shell.ui` `menu id="primary_menu"` | menu | items + `hidden-when` attribute ported; action targets (`app.sources`, `app.prefs`, `app.shortcuts`, `app.about`) named |
| `lib/settings.rb` | `data/org.gnome.software.gschema.xml` | settings backend | all 35 keys present as a JSON-backed stand-in for GSettings (documented deviation) |
| `lib/shortcuts_dialog.rb` | `src/gs-shortcuts-dialog.ui` | dialog | 4 sections, 10 shortcut rows, accelerators ported |
| `lib/toast.rb` | `src/gs-toast.c/.h` | factory module | button-label table, timeout=0, details precondition ported |
| `lib/gnome_software/application.rb` | `src/gs-application.c/.h` (partial) | application + window chrome | window, header bar, toast overlay, primary-menu button; 3 of ~24 app actions wired (`about`, `shortcuts`, `quit`); `status_page` is an explicit stand-in, not a port of `gs-shell.ui`'s view stack |
| `lib/gnome_software.rb` | `src/gs-main.c` (folded) | entry require graph | — |
| `lib/gnome/software/rb/version.rb` | n/a | gem version | — |

**Not yet identified in the port because the widget does not exist at all:**
all 10 top-level pages, all 12 dialogs other than `error_dialog.rb` and
`shortcuts_dialog.rb`, all 5 context-dialog/row components, all 6 list rows,
all 6 tiles/cards, all 15 composite widgets/sections, and all 6
background/integration classes. `lib/shell.rb` (the view-stack shell itself,
`gs-shell.c/.ui`) does not exist — `application.rb` inlines a placeholder
`status_page` instead of building it.

## Count

- Upstream components: 80.
- Port components identified with a real widget tree: 2 (`error_dialog.rb`,
  `shortcuts_dialog.rb`), plus 1 menu (`primary_menu.rb`) and 1 partial
  application shell. Pure-logic support files (`common.rb`, `settings.rb`,
  `toast.rb`, `page.rb`) back those but are not themselves components with a
  widget tree.
- **8 of 80 upstream components (10%) have any port presence; 72 of 80 (90%)
  do not exist in `lib/` at all.**
