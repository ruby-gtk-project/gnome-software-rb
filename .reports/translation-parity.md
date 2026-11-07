# Translation parity — gnome-software-rb vs origin/main

Per `.claude/skills/translation-parity`.

## Upstream

`po/LINGUAS` lists 76 locales; `po/POTFILES.in` lists 135 source files
whose `_()`/`N_()`/`C_()`/`ngettext()` call sites feed the `.pot` template
that is compiled into per-locale `.mo` catalogues via gettext, domain
`gnome-software`. The strings covered span the entire UI surface this
audit's other four reports describe as unported: page titles, dialog
labels, button text, toast messages, preference labels, shortcut
descriptions, plural forms (e.g. app-count and update-count strings),
and error messages.

## Port

- No `po/` directory exists anywhere in `gnome-software-rb` on `ruby`.
- No `.pot` or `.po` file exists anywhere in the repository
  (`find . -iname '*.pot' -o -iname '*.po'` → empty, git-tracked files
  excluded).
- No gettext dependency is declared: `gnome-software-rb.gemspec` has no
  `gettext` runtime dependency, and `grep -n -i 'gettext\|i18n\|locale'`
  across the gemspec and `Rakefile` returns nothing.
- No `lib/*.rb` file requires `gettext`, `fast_gettext`, or
  `GLib::I18n`, and none calls a translation function. Every user-facing
  string in the 10 ported/partial files
  (`error_dialog.rb`, `primary_menu.rb`, `settings.rb` [N/A — keys, not UI
  strings], `shortcuts_dialog.rb`, `toast.rb`, `application.rb`) is a bare
  Ruby string literal: `'Error Details'`, `'_Software Repositories'`,
  `'_Preferences'`, `'Just now'`, `'Copy Details'`, `'Software'`, etc.
  Several even keep the upstream `_` mnemonic-underline prefix verbatim
  (`'_Software Repositories'`, `'_Preferences'` in `lib/primary_menu.rb`;
  `'_Automatic'` etc. in the cataloged prefs-dialog rows) — those are
  copied from the upstream label text, not run through any translation
  call. Whether GTK4's menu-model consumer renders that leading
  underscore as a mnemonic or as a literal character was not verified
  here and needs a runtime check; either way, no gettext call processes
  the string, which is the translation-parity gap this report tracks.
- No Rake task extracts strings (`rake pot` is referenced only in a code
  comment inside `flake.nix`, describing `rxgettext` as a *tool the dev
  shell provides*, not a task this repo defines or runs: `grep -n pot
  Rakefile` → nothing).

## Finding

**0 of the upstream catalogue's msgids survive in the port, because there
is no translation mechanism in the port at all — not a partial catalogue,
not an English-only stub, nothing.** Every string the port does emit is
hardcoded English with no extraction path and no locale switching.

## Severity

This is total, not partial, non-parity. It is also compounding: every new
widget file being written right now (`error_dialog.rb`, `primary_menu.rb`,
`shortcuts_dialog.rb`, `application.rb`) is adding more hardcoded strings
with no catalogue to backfill later, so the gap grows with every commit
until gettext is wired in before, not after, the bulk of the UI is ported.

## Required fix

1. Add a gettext dependency (the project's own `ruby-gtk` skill / sibling
   ports should be checked for the house convention — likely `gettext` or
   `GLib::I18n` via gobject-introspection, since the app already loads
   `gtk4`/`adwaita` through GI) and wrap every user-facing string already
   in `lib/` with it, including the ones just listed.
2. Create `po/POTFILES.in` pointing at those `lib/*.rb` files and a `rake
   pot`/`rake po:update`-style task so a template can be generated as
   components land, rather than retrofitted later.
3. Verify how the mnemonic-underscore strings in `primary_menu.rb` render
   today, and fix them if they show as a literal underscore, before more
   files copy the same pattern.
4. Decide and document a locale-copy story for upstream's 76 `po/*.po`
   files (full carry-over, subset, or re-translation) — nothing in
   `PORTING.md` (which does not exist) or `README.md` currently states
   this project's position.
