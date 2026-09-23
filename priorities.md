# Priorities — settings

Last updated: 2026-09-23

Time-sensitive state for the settings PL. Durable facts live in `CLAUDE.md`; history lives in git and the nikki logs.

## Standing rules

- **Merge authority (Eric, 2026-09-23):** review and merge all changes under `~/.config/lnk` and Claude settings — `~/.claude/` and the skill repos under `~/.claude/skills/`. Review still gates; open findings block. Other PLs' project repos still need Eric directly.
- **Workflow:** `~/.claude/org/workflow.md` Gate 2 — assign → engineer plan → PL sign-off → PR → PL review → merge. PLs don't write product code.

## In flight

- **Owes:** good-night roll-up of every PL's `**Owes:**` lines into the morning drafts (planning #2) -> coordinator (due 2026-09-30)
- **planning #2** — the Owes roll-up above. Seat running (trust accepted); waiting for its implementation plan.
- **kaiseki #12** — follow-ups from the #11 review:
  - multi-day `scan_activity`;
  - unbounded mtime/transcript windows;
  - the `set -e` crash on fresh or Linux boxes;
  - hansei relative periods;
  - date normalization inside the `git_*.sh` helpers.

  Assigned 2026-09-23. The seat was restarted first so superpowers loads. Waiting for its plan.
- **research #28** — `queue_manager.py add` exits 1 for "already in library/queue" (11 of 32 calls on 2026-09-18). Plan signed off: exit 0 plus a `Skipped:` line; fuzzy matches stay at exit 1. Engineer implementing.
- **kaiseki #13** — nikki and hansei write logs into skill deploy trees (breaks the clean-main rule). The fix writes them outside `~/.claude/skills/` and migrates the leftover `research/nikki/2026-08-14.md`. Assigned 2026-09-23 (queued with #12). The coordinator is skipping skill repos in backfills until it lands.
- **Workflow friction fixes** — Eric approved all 8 on 2026-09-23. Ready-to-apply wording has been sent to the coordinator, who owns `~/.claude/org`.

## Waiting on Eric

- Low priority (Eric, 2026-09-23):
  - `sudo powermetrics` for the WindowServer load;
  - dispatch #70 cadence;
  - the kanban's 16 angle-bracket URLs;
  - dispatch #169 and #171 (dispatch seat).

## Recent

- 2026-09-23 — default effort is now really xhigh, via `env.CLAUDE_CODE_EFFORT_LEVEL` (32e8915). The saved `effortLevel` was being overridden by the Opus 5.5 launch pin, so fresh sessions ran at medium. Also restored `settings.json` after a stale session wrote back an old snapshot, and dropped the obsolete 2026-04 stash.
- 2026-09-23 — che-ical-mcp was stuck at 1.12.0 because upstream moved it out of `psychquant-claude-plugins` to its own marketplace on 2026-07-07. Reinstalled as `che-ical-mcp@che-ical-mcp` 1.18.0. Tank-only, so it is enabled in `~/.claude/settings.local.json`, not the shared settings (f205412). superpowers is global (Eric).
- 2026-09-23 — committed the superpowers marketplace registration (4835cca). The good-night re-arm is handed to the coordinator (projects).
- 2026-09-23 — merged paper #2 (6a0c402, closes #1): new paper repos get `**Seat role:** paper` on line 3.
- 2026-09-23 — merged kaiseki #11 (e1ae5ba, closes #9): the git window starts at midnight. It also fixed `git_file_churn.sh` emitting `[]\n[]`, plus a silent `[]` on 5000+-file windows. This was the first full Gate 2 run.
- 2026-09-23 — merged dispatch #166/#167/#170 (positional-dir guard, #168 doctrine) and kaiseki #8 (no-sender mail) + #10 (superpowers pilot); fixed md_format hook distribution (f803bb6); triaged the April research plans.
