# Priorities — settings

Last updated: 2026-09-24

Time-sensitive state for the settings PL. Durable facts live in `CLAUDE.md`; history lives in git and the nikki logs.

## Standing rules

- **Merge authority (Eric, 2026-09-23):** review and merge all changes under `~/.config/lnk` and Claude settings — `~/.claude/` and the skill repos under `~/.claude/skills/`. Review still gates; open findings block. Other PLs' project repos still need Eric directly.
- **Workflow:** `~/.claude/org/workflow.md` Gate 2 — assign → engineer plan → PL sign-off → PR → PL review → merge. PLs don't write product code.

## In flight

- **planning #6** — good-morning checks in with PLs for updates before presenting last night's drafts (Eric's rule via the coordinator, 2026-09-24). Assigned; waiting for the plan.
- **kaiseki #23** — `link_to_planning.sh` writes absolute symlink targets; today's relative ones climb 8 levels out of the OneDrive mount. Moved from Eric's TODO. Assigned; waiting for the plan.
- **claude-limitline #1** — the statusline's own OAuth credential hasn't refreshed since 2026-06-14, most likely because Claude Code moved its endpoints to `platform.claude.com`, and the failure was silent. Issues are enabled on the fork. Eric picks how to route it: an engineer seat (needs a folder-trust click) or a one-off fix from this seat. Either way, Eric re-runs `limitline-auth.mjs` afterwards.
- **Workflow friction fixes** — Eric approved all 8 on 2026-09-23. Ready-to-apply wording has been sent to the coordinator, who owns `~/.claude/org`.

## Waiting on Eric

- Low priority (Eric, 2026-09-23):
  - `sudo powermetrics` for the WindowServer load;
  - dispatch #70 cadence;
  - the kanban's 16 angle-bracket URLs;
  - Overleaf token rotation (moved from Eric's TODO, 2026-09-24). `~/.git-credentials` is a stale plaintext file (0600) holding an Overleaf token; no `store` helper reads it anymore. Eric revokes the old token in Overleaf and confirms the new one is in 1Password, then I trash the file.

## Recent

- 2026-09-23 — merged dispatch #175 (bc6a542, closes #172) and deployed it to tank plus all 6 Linux hosts.
  - A seat started or restarted with unread mail or a monitor sentinel now gets a kickoff prompt and acts without anyone typing. The E2E proved it with zero keystrokes.
  - Known limit: a never-trusted dir still stalls on first-launch modals (the trust prompt, then MCP-server approval) before the kickoff runs.
- 2026-09-23 — merged dispatch #173 (c5135b1, closes #171) and #174 (954aeb5, closes #169), and deployed both to tank plus all 6 Linux hosts. Every host is in sync, and dgx02 adopted its bus. What changed:
  - `monitor` warns instead of aborting when the bus is down;
  - `dispatch version` compares deployed bytes, not commits, so a tests-only merge no longer reads as drift;
  - both #134 reversals are accepted and recorded at D13.
- 2026-09-23 — kaiseki follow-ups closed:
  - #18 (#20): tool caches no longer count as changed files; on lnk they were 71 of 78.
  - #15 (#21): hansei's transcript window is bounded, and its 9h UTC skew is fixed.
  - #14 (#22, plus planning #5): same-basename projects keep separate planning-log names. The lost May links are restored, and planning.md → the coordinator on 41/41 days.
  - Known limit: two same-basename nikki runs finishing at the same instant could still race; recorded on #14.
- 2026-09-23 — merged kaiseki #16 (d76e3ae, closes #13): nikki and hansei on a skill deploy tree now write outside it. The migration moved 31 stray files out of the skill trees and removed 10 planning symlinks into them; `--doctor` is all clean. Merged kaiseki #17 (e79d790) and #19 (5506b8a), which close #12: every kaiseki date window is now whole local days, `scan_activity` takes a range, and its sections are bounded, with transcripts matched by overlap. Low-priority follow-ups filed and unassigned: kaiseki #14 (`planning` name clash), #15 (no end date in `analyze_conversations.py`), plus a travel issue and a `.rumdl_cache` issue.
- 2026-09-23 — merged planning #3 (9df6713, closes #2), which delivered my Owes line to the coordinator a week early. good-night now writes `## Owed across PLs` into drafts.md every night, and good-morning shows it. Most live Owes lines use free-text dates and show as undated, so I asked the coordinator to enforce `(due YYYY-MM-DD)`.
- 2026-09-23 — fleet deploy: all six Linux hosts are on lnk f44206d plus the private `underspecified/org` repo (a182833, cloned at `~/.claude/org`, never folded into the public lnk). All 10 old stashes were reviewed with Eric and dropped. The Linux docker config is no longer managed by lnk: a ghcr.io token had been written into the public-tracked file. Every host now has haru-4090's config as a per-host 0600 file.
- 2026-09-23 — merged research #29 (closes #28, rebase-merged: ca99d82 format + 2a5dd00 behavior): `queue_manager add` now reports "already in library/queue" as `Skipped:` with exit 0.
- 2026-09-23 — default effort is now really xhigh, via `env.CLAUDE_CODE_EFFORT_LEVEL` (32e8915). The saved `effortLevel` was being overridden by the Opus 5.5 launch pin, so fresh sessions ran at medium. Also restored `settings.json` after a stale session wrote back an old snapshot, and dropped the obsolete 2026-04 stash.
- 2026-09-23 — che-ical-mcp was stuck at 1.12.0 because upstream moved it out of `psychquant-claude-plugins` to its own marketplace on 2026-07-07. Reinstalled as `che-ical-mcp@che-ical-mcp` 1.18.0. Tank-only, so it is enabled in `~/.claude/settings.local.json`, not the shared settings (f205412). superpowers is global (Eric).
- 2026-09-23 — committed the superpowers marketplace registration (4835cca). The good-night re-arm is handed to the coordinator (projects).
- 2026-09-23 — merged paper #2 (6a0c402, closes #1): new paper repos get `**Seat role:** paper` on line 3.
- 2026-09-23 — merged kaiseki #11 (e1ae5ba, closes #9): the git window starts at midnight. It also fixed `git_file_churn.sh` emitting `[]\n[]`, plus a silent `[]` on 5000+-file windows. This was the first full Gate 2 run.
- 2026-09-23 — merged dispatch #166/#167/#170 (positional-dir guard, #168 doctrine) and kaiseki #8 (no-sender mail) + #10 (superpowers pilot); fixed md_format hook distribution (f803bb6); triaged the April research plans.
