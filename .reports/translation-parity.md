# Translation parity — gnome-software-rb vs origin/main

Per `.claude/skills/translation-parity`. Re-checked fresh this round
against the current `lib/` (18 files, up from 10 last round); the
underlying finding is unchanged and, if anything, has grown.

## Upstream

`po/LINGUAS` lists 76 locales. `po/POTFILES.in` lists 135 source files
whose `_()`/`N_()`/`C_()`/`ngettext()` call sites feed the `.pot`
template, gettext domain `gnome-software`. Measured directly off
`po/de.po` this round: **1109 unique `msgid`s** (`grep '^msgid ' po/de.po
| sort -u | wc -l`). The gschema itself adds no translatable strings
(`summary`/`description` tags are build-time comments, not `_()`-wrapped
at the GSettings layer); the UI strings are the 1109.

## Port

- No `po/` directory exists anywhere on `ruby`. No `.pot`/`.po` file
  exists anywhere in the repository.
- No gettext dependency is declared in `gnome-software-rb.gemspec`; no
  `gettext`/`fast_gettext`/`GLib::I18n` reference anywhere in `lib/`,
  `exe/`, `Gemfile`, or `Rakefile`.
- Checked every file added since the last round
  (`progress_button.rb`, `context_dialog_row.rb`, `review_bar.rb`,
  `description_box.rb`, `updates_paused_banner.rb`, `language.rb`,
  `vendor.rb`, `system_info.rb`) in addition to the 10 already flagged:
  **zero** of them calls a translation function either. User-facing
  strings keep arriving as bare Ruby literals (`'Show _More'`/
  `'Show _Less'` in `description_box.rb`, the paused-reasons title
  strings in `updates_paused_banner.rb`, etc.), continuing the pattern
  called out last round in `primary_menu.rb`/`error_dialog.rb`.
- `description_box.rb`'s `'Show _More'`/`'Show _Less'` keep the upstream
  mnemonic-underscore convention verbatim, same unresolved risk flagged
  last round for `primary_menu.rb`: whether GTK4 renders that leading
  underscore as a mnemonic or a literal character was not verified
  either round, and it is now present in a second file.
- No Rake task, script, or CI step extracts strings. `grep -rn
  'gettext\|xgettext\|\.pot' Rakefile gemfiles/ 2>/dev/null` → nothing.

## Finding

**0 of the upstream catalogue's 1109 msgids survive in the port.** Not a
partial catalogue, not an English-only stub with extraction wired for
later — there is no translation mechanism at all, and the gap has grown
by 5 more hardcoded-string files since the last audit with no
countervailing progress on gettext wiring in between.

## Severity

Unchanged verdict, worse trend: every round that ports more UI without
first wiring gettext makes the eventual retrofit larger. 5 new files
landed this round, all adding more hardcoded English strings
(`updates_paused_banner.rb`'s dynamic "Updates have been paused for N
reasons"-shaped title included, which is also unported for the pluralized
`ngettext` form upstream uses for its 1-vs-N-reasons case — see
`component-parity.md`'s note on that banner's title logic; the Ruby port
builds this string without any plural-form awareness, English or
otherwise).

## Required fix (unchanged from last round, still outstanding)

1. Add a gettext dependency and wrap every user-facing string already in
   `lib/` — now 15 files' worth, up from 10.
2. Create `po/POTFILES.in` and a `rake pot`/`rake po:update` task before,
   not after, the remaining 55 unported components are written.
3. Verify the mnemonic-underscore rendering for both
   `primary_menu.rb` and `description_box.rb` in one pass.
4. Decide and document a locale-copy story for upstream's 76 `po/*.po`
   files; `PORTING.md` still does not exist to hold that decision.
