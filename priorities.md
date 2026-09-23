# Priorities — settings

Last updated: 2026-09-23

Time-sensitive state for the settings PL. Durable facts live in `CLAUDE.md`; history lives in git and the nikki logs.

## Standing rules

- **Merge authority (Eric, 2026-09-23):** review and merge all changes under `~/.config/lnk` and Claude settings — `~/.claude/` and the skill repos under `~/.claude/skills/`. Review still gates; open findings block. Other PLs' project repos still need Eric directly.
- **Workflow:** `~/.claude/org/workflow.md` Gate 2 — assign → engineer plan → PL sign-off → PR → PL review → merge. PLs don't write product code.

## In flight

- **kaiseki #11** (fix for #9, git `--since` bare date) — changes requested: 7 blocking items (hermetic test env, check scan rc, pin the `~/projects` call site, discriminating asserts, single `[]` from `git_file_churn.sh`, hansei claim, CLAUDE.md layout). Engineer: kaiseki.
- **paper #1** — `**Seat role:** paper` on line 3 of the paper-from-overleaf CLAUDE.md template. Engineer seat cold-started 2026-09-23; awaiting its implementation plan.
- **Workflow pilot feedback (for Eric)** — the first live Gate 2 run (kaiseki #9) turned up 7 friction points:
  1. Gate 1 is undefined for bugs.
  2. "PLs never run code" contradicts verification — and the prescribed `/code-review` runs code itself. Suggest "never _write_ product code".
  3. A 👍 reaction notifies nobody — sign-off needs 👍 **plus** a dispatch.
  4. Seat setup (plugins) must precede assignment — superpowers reached kaiseki after #9 started.
  5. No fast lane for one-line changes.
  6. `engineer.md` requires superpowers, but it is enabled only in kaiseki.
  7. `/code-review` output needs an explicit PL triage step (blocking vs follow-up issue).

## Queued (filed, unassigned)

- **kaiseki #12** — follow-ups from the #11 review: multi-day `scan_activity`, unbounded mtime/transcript windows, `set -e` crash on fresh/Linux boxes, hansei relative periods, date normalization inside the `git_*.sh` helpers.
- **research #28** — `queue_manager.py add` exits 1 for "already in library/queue" (11 of 32 calls on 2026-09-18).
- **dispatch #169** (version drift is commit-based; a re-stamp install recreates the docker bus) and **#171** (V20d flaky on Linux) — dispatch seat, low priority.

## Waiting on Eric

- **good-night is unarmed** — `com.eric.good-night-nightly` is not loaded (one-shot agent consumed 2026-09-22); re-armed by `/good-morning` or `setup_good_night_automation.sh`.
- **Uncommitted `.claude/settings.json`** — adds `extraKnownMarketplaces.superpowers-marketplace`; committing it propagates the marketplace fleet-wide.
- `/mcp` reconnect for CheICalMCP 1.18.0; `sudo powermetrics` for the WindowServer load; dispatch #70 cadence; whether the kanban's 16 angle-bracket URLs are formatter residue.

## Recent

- 2026-09-23 — merged dispatch #166/#167/#170 (positional-dir guard, #168 doctrine) and kaiseki #8 (no-sender mail) + #10 (superpowers pilot); fixed md_format hook distribution (f803bb6); triaged the April research plans.
