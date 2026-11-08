# Test parity — gnome-software-rb vs origin/main

Per `.claude/skills/test-parity`. Supersedes the prior round's
`test-parity.md`, written when `drive_ok=false` and no `test/` directory
existed. This round's gate: `drive_ok=true`, 108/108 checks, 17
components.

## Upstream tests (origin/main)

`git ls-tree -r --name-only origin/main | grep -i test` finds
`lib/gs-test.c/.h` (shared test harness), `lib/tests/{app-permissions,css,
utils}.c`, `plugins/core/tests/core.c`, a per-plugin `tests/` C test
(dpkg, dummy, eos-updater, epiphany, fedora-langpacks, flatpak [plus a
large fixture tree], fwupd, modalias, packagekit, repos, rpm-ostree, snap,
systemd-sysupdate), and `tests/actions.py`, `tests/basic.py`,
`tests/template.test.in` at top level, run through
`.gitlab-ci/run-tests.sh`.

## Port tests — two separate surfaces, checked independently

### 1. `test/drive_*.rb` — exists now, runs, passes

`test/drive_gnome_software.rb` (283 lines) and `test/drive_new_widgets.rb`
(184 lines) exist and were run directly this round under
`nix develop --command xvfb-run -a ruby test/drive_*.rb`:

- `drive_gnome_software.rb`: **75 of 75 checks passed**, covering the
  window, header bar, primary menu, `app.about`/`app.shortcuts`/`app.quit`
  wiring, the About dialog (incl. every `system_info.rb` backend line),
  the Shortcuts dialog's 4 sections, `Lozenge`'s icon/text-face switching,
  and `ErrorDialog`'s copy-button wiring.
- `drive_new_widgets.rb`: **33 of 33 checks passed**, covering
  `ProgressButton`, `ContextDialogRow`, `UpdatesPausedBanner`, `ReviewBar`,
  `DescriptionBox`.
- Combined: **108 of 108, 0 failed** — matches the round's stated gate
  exactly; I reproduced it independently rather than trusting the number.
- **But**: both scripts print `RuntimeError: widget produced no render
  node (not realised yet?)` at 4 separate screenshot steps (`02-about-dialog`,
  `05-updates-paused-single`, `07-description-box-expanded`, and one more
  implicit in the stderr) and continue past them without incrementing the
  failure count. These are real runtime errors against real widgets, not
  script bugs — see `accountability-ensurance.md`. The "0 failed" headline
  is accurate for what the scripts count as a check, but a widget that
  cannot be rendered to a screenshot is evidence of a GTK-realization bug
  the gate is structurally unable to report as a failure.
- Coverage: 108 checks cover exactly the **17 files** that exist in `lib/`
  (18 minus the version file) — i.e. 100% of what's ported is driven, 0%
  of what isn't ported (55 of 70 upstream components) has any check,
  because there is no code for a check to exercise. A "component covered"
  count of 17 is therefore not evidence the app works; it's evidence the
  app's unported 79% majority is, trivially, untested by omission.

### 2. `spec/*_spec.rb` — RSpec harness, still completely absent and non-functional

`find spec -type f` → only `spec/README.md` and `spec/spec_helper.rb`.
**Zero `_spec.rb` files exist.** Worse than "empty": I ran the exact
command the dev-shell banner prescribes —

```
ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format","progress","--require","spec_helper","spec"])'
```

— inside `nix develop` (plain and via `bundle exec`) and both fail before
reaching "no examples":

```
Failure/Error: require "kettle/test/rspec"
LoadError:
  cannot load such file -- kettle/test/rspec
...
0 examples, 0 failures, 2 errors occurred outside of examples
```

`spec/spec_helper.rb` requires a gem (`kettle-test`, declared only as a
development dependency in the gemspec) that is not resolvable in the dev
shell as configured. This is a second, independent gap from "no spec
files exist": even an agent who wrote specs today could not run them with
the commands this repo documents, because the harness itself does not
load. Neither `test-parity.md` nor any other report before this round
flagged that the *documented* run command is broken, only that no specs
exist — that is itself a finding (see `accountability-ensurance.md`).

## Finding

- **0 of the upstream C/Python test files have a Ruby equivalent.**
  `common.rb`'s date/size formatting, `settings.rb`'s JSON persistence and
  generated accessor methods, and every piece of pure logic in `lib/` has
  no unit-level spec.
- The 108 `drive_*.rb` checks are real, executed, and passing — this is
  genuine progress over the prior round's `drive_ok=false` and should be
  credited as such — but they are integration/smoke checks for widgets in
  isolation, not unit tests, and they cover only the 21% of upstream
  components that have been ported.
- The RSpec harness (`spec/`) remains unusable, and is now additionally
  confirmed *broken*, not just empty.

## Severity

Two gaps, different shapes:
1. **Breadth gap** — the drive scripts can only ever cover what is
   ported; 79% of upstream components (55 of 70 stems) have zero
   automated coverage of any kind, by construction, until they are
   written.
2. **Harness gap** — even for code that is ported, the unit-test path
   (`spec/`) does not run at all right now, for a reason (`LoadError`)
   nobody has recorded anywhere in `.reports/` before this round.

## Required fix

1. Fix `spec/spec_helper.rb`'s `kettle/test/rspec` load path, or document
   in `spec/README.md` that the harness is currently broken and how to
   restore it (`bundle install` with a lockfile that resolves `kettle-test`,
   if that's the actual missing step — not verified here, only that the
   documented command fails as given).
2. Once loadable, add unit specs for `common.rb` and `settings.rb` before
   adding more `lib/` files, so pure logic stops being proven only by
   integration smoke tests.
3. Make the drive scripts fail (increment the failure counter, not just
   print to stderr) when a screenshot step raises, so a real render bug
   cannot pass the gate silently — see the 4 `RuntimeError`s noted above.
4. Continue extending `test/drive_*.rb` alongside each new `lib/` file, as
   happened correctly this round for the 5 new widgets.
