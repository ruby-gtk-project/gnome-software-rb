# Test parity — gnome-software-rb vs origin/main

Per `.claude/skills/test-parity`.

## Upstream tests (origin/main)

`git ls-tree -r --name-only origin/main | grep -i test` finds a substantial
upstream test surface: `lib/gs-test.c/.h` (shared test harness),
`lib/tests/{app-permissions,css,utils}.c`, `plugins/core/tests/core.c`,
and a `tests/` C test per plugin (dpkg, dummy, eos-updater, epiphany,
fedora-langpacks, flatpak [plus a large fixture tree], fwupd, modalias,
packagekit, repos, rpm-ostree, snap, systemd-sysupdate), plus
`tests/actions.py`, `tests/basic.py` and `tests/template.test.in` at the
top level, run through `.gitlab-ci/run-tests.sh`.

## Port tests

`find spec -type f` → `spec/README.md`, `spec/spec_helper.rb`. **Zero spec
files exist.** `spec/README.md` documents the `kettle-test` harness helpers
available *to future specs* but contains no examples itself. `find test
-type f` → nothing; there is no `test/` directory at all.

`grep -rn 'drive_\|test/drive' .` and a direct `find . -iname 'drive*'`
both return nothing outside the nix flake's own echoed instructions
(`flake.nix` prints `"drive the app: xvfb-run ruby test/drive_*.rb"` as
*guidance for a file that does not exist yet*).

## Runtime gate cross-check

This round's gate: `drive_ok=false`, 0 checks passed, 0 failed, 0
components covered. That is not a flaky or partial run — it is the
necessary result of there being no `test/drive_*.rb` file and no
`spec/*_spec.rb` file in the repository at all. There is nothing to
execute. I confirmed this directly rather than taking the gate's number on
faith: `find spec test -type f` and the `drive*` search above both came up
empty, and `ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(...)'`
(the exact command the dev-shell banner names) would run RSpec against an
empty `spec/` with no examples — a green exit with 0 examples, which is the
textbook false-positive this skill exists to catch.

## Finding

**0 of the upstream test files have a Ruby equivalent. 0% test parity.**
This is not "the suite needs work" — there is no suite. No `lib/*.rb` file
in the port has ever been exercised by an automated check: not
`common.rb`'s date/size formatting, not `settings.rb`'s JSON persistence
and generated accessor methods, not `error_dialog.rb`'s clipboard copy, not
`primary_menu.rb`'s menu structure, not `application.rb`'s action wiring.
Every one of those is unverified-by-construction, independent of whether
the code is correct.

## Severity

This is the single largest gap of the five reports. A component can be
"ported" in the sense of existing as a `.rb` file and still be completely
unverified; `component-parity.md` already flags behavioral gaps by reading
the code, but reading code is not testing it, and nothing here lets any
future agent trust that `lib/settings.rb`'s generated `DEFAULTS.each_key`
accessor methods, for one concrete example, actually produce the right
method names for every key (`'auth.account-id'` → `auth_account_id` is
exercised nowhere).

## Required fix

1. Port at minimum `lib/tests/utils.c`'s equivalent assertions (time
   formatting, size formatting) as `spec/common_spec.rb`.
2. Add `spec/settings_spec.rb` covering persistence round-trip and the
   generated accessor methods, including the boolean `?` predicates.
3. Add a `test/drive_gnome_software.rb` that launches the app under
   `xvfb-run` and asserts the window/menu/shortcuts-dialog build without
   raising, so the runtime gate has something to execute at all.
4. Re-run the gate after (3) exists; until then, `drive_ok=false` is
   correct and must not be reported as anything else.
