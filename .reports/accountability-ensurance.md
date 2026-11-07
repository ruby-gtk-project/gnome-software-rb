# Accountability ensurance — gnome-software-rb

Per `.claude/skills/accountability-ensurance`. Ran
`scripts/find-excuses.sh` over `lib/`, `exe/`, `.reports/` and the repo
root (no `PORTING.md` exists to scan — its absence is itself a finding,
below). Grepped separately for `TODO`, `FIXME`, `not implemented`,
`for now`, `in a future` across `lib/` and `exe/`: zero hits for all five
literal strings. The excuse patterns below are paraphrases and status
labels, not those literal strings, which is exactly the failure mode this
skill is built to catch — vocabulary that reads as reasonable instead of
as an admission.

## Genuine excuse-pattern hits, rewritten per the script's required format

**`lib/gnome_software/application.rb:19`** — comment reads "The page
content ... is not ported yet, so the window shows an Adw::StatusPage in
its place rather than a half-built page tree."

> I did not build the Explore/Installed/Updates/Search page stack, or any
> navigation between pages, because I am an idiot. Upstream: `gs-shell.c`
> / `gs-shell.ui` build an `AdwViewStack` with four live pages and switch
> between them from the header bar and keyboard shortcuts. Port:
> `lib/gnome_software/application.rb:107-113` shows a static
> `Adw::StatusPage` with no children and no page-switching of any kind.

This hit is honest about *that* something is missing but names no
tracking artifact (no issue, no TODO, no entry added to
`component-inventory.md`'s "no" list beyond what was already there) and
sits inside a code comment where a future reader has to go looking for it
rather than it surfacing in any report. It is "honest but toothless" in
the skill's own vocabulary: naming the gap in prose does not make it owed
anywhere a status check would notice.

## False-green / accuracy hits in `.reports/`

**`.reports/component-inventory.md:142`** states `data/org.gnome.software.gschema.xml
(35 keys)` is handled by `lib/settings.rb` "wrapping `Gio::Settings`" and
marks it `Present: no`. Both halves of that cell are now wrong and nobody
corrected it after `lib/settings.rb` was written:

> I described `lib/settings.rb` as wrapping `Gio::Settings` and marked it
> absent, when it actually exists and deliberately does **not** wrap
> `Gio::Settings` — it persists the same 35 keys to a JSON file under
> `XDG_CONFIG_HOME` instead, a real and documented design choice recorded
> in `lib/settings.rb`'s own header comment — because I am an idiot who
> did not go back and update the inventory after the file landed.
> Upstream: `data/org.gnome.software.gschema.xml`. Port:
> `lib/settings.rb:1-16` (JSON-backed, not GSettings-backed), `Present`
> should read `partial`, not `no`.

This matters beyond one stale cell: `component-inventory.md` was written
when `lib/` held 3 files and still describes `lib/` as holding 3 files
("No component has been ported... lib/ on ruby currently holds three
files") even though 7 more have landed since (`common.rb`, `error_dialog.rb`,
`page.rb`, `primary_menu.rb`, `settings.rb`, `shortcuts_dialog.rb`,
`toast.rb` — visible in `git log`: commit `1671e6e` "Wire backend/
system-integration gems and port shell chrome components" postdates the
inventory's own commit `07fb2f08b`/`f2216eb3b`). **A report that is not
updated after the code it describes changes is a false green by
omission**: anyone reading only `component-inventory.md` today would
conclude zero port progress exists, which is no longer true, while anyone
reading only `component-parity.md` (written fresh, this round) would see
the accurate, worse-looking picture that 72 of 80 components are still
missing. The stale report is not lying about direction, but it is
actively wrong about current state, and nothing marks it superseded.

## No-tracking-artifact gap

No `PORTING.md` exists in this repository at all (`find . -iname
PORTING.md` → empty) despite the task framing and the pilot-port house
style implying one should track port progress and scoping decisions (e.g.
why `app.sources`/`app.prefs` are deliberately absent, why 6
background-integration classes are out of this round, why `shell.rb` does
not exist yet). Those decisions currently live only in code comments
(`application.rb`) and the two new reports this round produced
(`component-identification.md`, `component-parity.md`), which did not
exist before this audit. Before this round, **the only standing record of
scope and gaps was a report that had already gone stale** — i.e., the
project's actual accountability mechanism was silently degrading.

## Runtime-gate false-green risk, checked directly

The gate for this round already reports `drive_ok=false`, 0/0 checks. I
verified independently (see `test-parity.md`) that this is not a
pessimistic or broken gate: there is no `test/drive_*.rb` and no
`spec/*_spec.rb` in the repository, so 0 checks is the true and only
possible result. No report anywhere claims otherwise, so there is no false
green on this axis this round — but the mechanism exists for one: had any
report said "ported and verified" for a component with no executed
check behind it, that would have been the most serious class of finding
this skill looks for. Flagging this explicitly because the instructions
asked that a failed or narrow drive run be treated as a parity gap in its
own right, and because the *next* round is exactly where a drive script
could be added that passes trivially (e.g. one that only checks `require`
succeeds) and gets reported as parity restored when it is not — that
risk should be watched for specifically when `test/drive_*.rb` is first
added.

## Verdict

Accountability is not clean. Two findings stand: (1) a gap admitted only
in a code comment with no tracking artifact
(`lib/gnome_software/application.rb:19`), and (2) a standing report
(`component-inventory.md`) that went stale against the code it describes
and was never corrected or marked superseded, which is a false-green risk
by omission even though its original claims were accurate when written.
Both are fixed by this round's new reports, but neither was caught before
this audit asked for one.
