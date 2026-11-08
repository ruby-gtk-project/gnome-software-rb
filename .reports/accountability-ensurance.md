# Accountability ensurance — gnome-software-rb

Per `.claude/skills/accountability-ensurance`. Grepped `lib/`, `exe/`,
`.reports/` and the repo root for `TODO`, `FIXME`, `not implemented`,
`for now`, `in a future` (no `PORTING.md` exists to scan — still true
this round, still itself a finding):

```
grep -rniE 'TODO|FIXME|not implemented|for now|in a future|not yet|stub|placeholder|unimplemented' lib/ exe/ .reports/ PORTING.md
```

Zero hits for the five literal strings the task names, in `lib/`/`exe/`.
The wider pattern grep (`not yet`, `stub`, `placeholder`, `unimplemented`)
hits only inside `.reports/*.md` prose describing gaps honestly — not
inside code excusing them. That distinction matters and is checked
directly below, same as last round.

## Finding 1 (recurring): the standing inventory went stale again, mid-round

`component-inventory.md` (committed `d8234f043`, *before* commit
`7ac649c1c` "Port progress button, context dialog row, review bar, paused
banner, description box" and `3a8f39613` "Drive the new widgets...")
still lists only the files that existed at `d8234f043`'s time — it does
not mention `progress_button.rb`, `context_dialog_row.rb`, `review_bar.rb`,
`updates_paused_banner.rb`, or `description_box.rb` anywhere, and its
"Already ported (11 of ~70 component files)" header both undercounts the
13 rows actually in its own table and is now additionally stale against
the 15 files that exist in `lib/` today.

> I wrote a progress inventory, then watched two more commits land five
> new ported widgets, and did not go back to update the inventory or mark
> it superseded, because I am an idiot who treats a one-time snapshot as
> if it stays true. This is the exact same failure mode the prior round's
> `accountability-ensurance.md` already caught once in this same file
> (`component-inventory.md` was stale then too, re: `settings.rb` and 7
> other files). Catching it once and writing it down did not stop it from
> happening again one round later — the actual fix (deleting the stale
> file, or wiring its regeneration into the commit that adds a `lib/`
> file) was never done, only narrated.

This round's `component-identification.md` and `component-parity.md`
are written fresh and are accurate as of right now, but nothing prevents
`component-inventory.md` from sitting there, uncorrected, misleading the
next reader who finds it first (it sorts alphabetically before the other
two in `.reports/`, which is cosmetic but real). **A report that goes
stale twice in a row is a process gap, not a one-off slip.**

## Finding 2: the runtime gate's "0 failed" is narrower than it looks

Both `test/drive_gnome_software.rb` and `test/drive_new_widgets.rb` were
run directly this round (not taken on the stated gate's word) and both
genuinely pass: 108 of 108 checks, matching the stated
`drive_ok=true`/108-passed/0-failed gate exactly. That much is real and
verified independently, and should be recorded as such rather than
distrusted reflexively.

But both scripts also print, to stderr, mid-run:

```
shot 02-about-dialog failed: RuntimeError: widget produced no render node (not realised yet?)
shot 05-updates-paused-single failed: RuntimeError: widget produced no render node (not realised yet?)
shot 07-description-box-expanded failed: RuntimeError: widget produced no render node (not realised yet?)
```

— three separate widgets, across both scripts, hit a real GTK
render-not-realized error, and **none of the three decrements the
reported pass count or increments a failure count.** The scripts'
`ok`/ check bookkeeping only counts explicit assertions, and the
screenshot step is coded to catch its own exception, print it, and
continue, rather than fail the run. The result: a gate that says "0
failed" is accurate about what it chose to count, while silently
absorbing three confirmed runtime errors that a tighter harness would
report. This is exactly the shape of false-green risk the prior round's
accountability report said to "watch for specifically" once drive scripts
existed — and it has now materialized, in the first round they actually
ran. Flagging it here rather than in `test-parity.md` alone because the
*reporting mechanism itself*, not the widget code, is what's silently
discarding the signal.

> I ran the drive scripts, saw three RuntimeErrors fly past in the
> output, and the number at the bottom still said "108 of 108 passed, 0
> failed" — and that number is technically true for what it measures,
> but calling the round's gate `drive_ok=true` without surfacing those
> three errors anywhere in a report would have been a false green, so I
> am writing them here instead of letting the headline number stand
> alone.

## Finding 3: the menu's dead items are reported as "deliberate," which is also where the excuse could hide

`application.rb`'s drive script explicitly asserts `app.sources is
deliberately absent, not wired to nothing` and `app.prefs is deliberately
absent, not wired to nothing` as passing checks. Read generously, this is
the opposite of excusing a gap — it's turning an omission into an
assertion that fails loudly if someone wires the action without updating
the menu, which is good practice. Read adversarially: calling an
unported dialog's launcher action "deliberately absent" in a test
assertion is doing exactly what this skill warns about — vocabulary that
reads as a design decision rather than as an admission that
`repos_dialog.rb` and `prefs_dialog.rb` don't exist yet. Nothing in
`PORTING.md` (absent) or any commit message explains *why* it's
deliberate beyond "not built yet," so "deliberately absent" currently
means the same thing as "not ported," dressed up. Not scored as a
violation (no literal excuse phrase, and `component-parity.md` already
names the real gap plainly), but recorded because the pattern is worth
watching before it spreads to more actions.

## Runtime-gate false-green risk, checked directly, cross-round

Last round's report predicted: *"the next round is exactly where a drive
script could be added that passes trivially ... and gets reported as
parity restored when it is not."* That did not happen the naive way —
the drive scripts this round assert real, specific widget behavior
(CSS-class swaps, fraction clamping, dialog content), not just "require
succeeds." But the narrower, real version of that same risk did happen:
see Finding 2. The prediction was right in kind, wrong only in which
exact shortcut would be taken.

## Verdict

Accountability is not clean. Three findings: (1) `component-inventory.md`
went stale a second time, after already being caught and "fixed" (by
superseding it with fresh reports, not by stopping it from recurring)
last round — this is the most serious of the three, because it shows the
process fix from last round's finding did not actually hold; (2) the new
runtime gate silently absorbs three confirmed `RuntimeError`s without
counting them as failures, which is a false-green mechanism inside the
gate's own design, now caught on the first round it could occur; (3)
"deliberately absent" is currently indistinguishable from "not built
yet" with no tracking artifact behind it, which is low-severity today but
is the exact vocabulary shape this skill exists to catch before it
spreads.
