# Priorities — settings

Last updated: 2026-09-30

Time-sensitive state for the settings PL. Durable facts live in `CLAUDE.md`; history lives in git and the nikki logs.

## Standing rules

- **Merge authority (Eric, 2026-09-23):** review and merge all changes under `~/.config/lnk` and Claude settings — `~/.claude/` and the skill repos under `~/.claude/skills/`. Review still gates; open findings block. Other PLs' project repos still need Eric directly.
- **Workflow:** `~/.claude/org/workflow.md` Gate 2 — assign → engineer plan → PL sign-off → PR → PL review → merge. PLs don't write product code.

## In flight

**Review rule (2026-09-26):** `/code-review` at high effort returns 15 findings (its cap) on every pass, so rounds don't converge. Block only on silent data loss, regressions the PR introduced, and the PR's own acceptance criteria. Everything else is a small fix-along, a follow-up issue, or won't-fix. Round 2 is the final round: round 3 only checks the listed items. **Merge order:** planning #23 (after good-night), then planning #21.

- **Workflow friction fixes** — Eric approved all 8 on 2026-09-23. Ready-to-apply wording has been sent to the coordinator, who owns `~/.claude/org`. The fixed sign-off/review prefixes for `workflow.md` were proposed to `projects` and are pending there.
- **planning #16** (pin DATE): PR #21 round 2 verified on 2026-09-30. It waits for a rebase onto #23.
- **planning #18:** PR #23 has its round addressed (e042605). Merge it after tonight's 19:00 good-night.
- **dispatch #181** (wake hangs): PR #182 (1d20692) is in review. After merge, run install.sh on tank and all 6 hosts. Unassigned:
  - #177: heartbeat.
  - #179: mark-read race. High priority.
  - #180: remote `${HOME}`.
- **kaiseki queue:**
  - #2: symlinks.
  - #32: full paths from `scan_activity`.
  - #31, #33, #34, #36, #38 (merges dropped under the pathspec). Low priority.

## Waiting on Eric

- 👍 on dispatch #183? It would let dispatch pre-approve its own MCP server for a headless cold start, only when the `.mcp.json` entry exactly matches what dispatch writes. Until then, headless wakes into a fresh dir stop at the MCP modal (PR #182 turns that into a warning).
- Restart running remote sessions so they load superpowers (apps and llm_eval on 5 hosts, lab on llm-jp), or let them pick it up at their next restart.
- Tank ssh skips the 1Password agent for fleet hosts? Every fleet ssh, commit and merge on tank was blocked from about 21:00 on 9/25 until 1P was unlocked the next morning. The file-key fallback doesn't help when 1P offers the key and then refuses to sign it. The change would go in the `ssh-config-hri-jp` note, so it's Eric's call.
- Report the Apple Mail MCP Sent Items bug upstream (imdinu)? That's outward-facing, so it's Eric's call. The workaround is planning #12.
- Low priority (Eric, 2026-09-23):
  - `sudo powermetrics` for the WindowServer load;
  - dispatch #70 cadence;
  - the kanban's 16 angle-bracket URLs;
  - Delete `planning/logs/.conflict-stubs-2026-09-24/` from Finder (110 OneDrive placeholder stubs from the #23 incident; Finder sends them to the OneDrive recycle bin). Trash and `rm` both fail on the OneDrive volume.
  - Overleaf token rotation (moved from Eric's TODO, 2026-09-24). `~/.git-credentials` is a stale plaintext file (0600) holding an Overleaf token; no `store` helper reads it anymore. Eric revokes the old token in Overleaf and confirms the new one is in 1Password, then I trash the file.

## Recent

- 2026-09-30 — merged kaiseki #37 (187e963, closes #29) after round 2: every gather script takes `<project>` (a leading `~` is expanded), subdirectory projects are scoped with `-- .`, `/nikki <DATE>` works, `date -j` is fixed, exit codes follow the contract and paths are absolute. It passed a live check on `~/projects/animations`. Deployed. Follow-up #38 (merges dropped under the pathspec). Tonight's good-night is the first to use it.
- 2026-09-30 — merged kaiseki #28 (cdad794, closes #27: hansei workflow-compliance audit; follow-ups #33/#34) and planning #9 (6554470, closes #8: weekly hansei from good-night; follow-up #17). Both deploy trees fast-forwarded, and `projects` was told the spot-check line can go. The first live weekly hansei is tonight's good-night; kaiseki #30 (`cd` in the `--all` fan-out) was moved to the front of the queue for it.
  - Filed dispatch #181 for the wake hangs. On dgx02, wake reattaches to a session whose claude has exited and times out on kitty. On llm-jp, llm_gen is sitting at the trust dialog. Eric has to clear both by hand for now.
  - planning PRs merged and deployed the same afternoon:
    - #13 (0-repo scan fix; roster allowlist through `active_projects.py`);
    - #20 (closes #19: skill symlinks no longer count as projects);
    - #15 (sent mail through read-only AppleScript; the security items pass);
    - #14 (Owes parser).

  Tonight's good-night is the first run with all of them. kaiseki #35 (#30) is in review. Next for planning: #16 (pin DATE); low priority: #17, #18.
- 2026-09-30 — worked through the queue of mail from projects and lab.
  - **che-ical:** enabled at user scope (d26fc50). The keys were removed from `~/.claude/settings.local.json` and the stale psychquant entries uninstalled. The fleet-wide auto-approval of mail/Slack/calendar tools stays local; that's Eric's call.
  - **security-guidance:** now reviews on Opus 5.5 (5b73a9d). It passed live on a real commit and push review, and all 6 hosts are synced.
  - **Fable:** pinned in 11 paper repos via their untracked `settings.local.json`.
  - **Effort:** the change was cancelled by lab and left at xhigh.
  - **Engineers:** planning, kaiseki and dispatch were restarted after the weekly-limit stall.
  - **"dispatch wake hangs":** not reproduced. mosh works to llm-jp and dgx02, so I've asked projects for the exact command.
  - **Correction:** the llm-jp claude sessions were never gone. I had checked the default tmux socket, not `-L dispatch`.
- 2026-09-25 — superpowers deployed fleet-wide. It was enabled in settings everywhere but installed only on tank and llm-jp. I added the `superpowers-marketplace` marketplace and installed the plugin on llm-jp-2 (pilot), germputer, haru-4090, haru-5090 and dgx02. All 6 Linux hosts are on lnk f0ad16f, which also carries 8cbae25 (frontend-design, duplicate superpowers dropped).
- 2026-09-24 — merged claude-limitline #2 (rebase, head eb963fc), rebuilt `dist/` in the live tree; the statusline runs. What changed:
  - the OAuth endpoints moved to `platform.claude.com` / `claude.com/cai`;
  - refreshes back off exponentially up to 24h;
  - `auth!` appears after a day of failures;
  - a lock now serializes refreshes across statusline processes. Refresh tokens are one-time use, so concurrent refreshes clobbered each other, which is the likely June killer.
  Lnk pushed and pulled on all 6 Linux hosts (cae3034), including the `dispatch-monitor` allow rule.
- 2026-09-24 — merged kaiseki #24 (08095f9, closes #23): planning-log links use absolute logical targets. The one-shot migration hit an incident. OneDrive treated the rename-over swap as a conflict, and 110 links became dataless stubs plus `<name> 2.md`; nothing was lost. Recovered by moving the stubs into `logs/.conflict-stubs-2026-09-24/` (a same-domain move, with no trash and no rm) and renaming to free names. End state: 377 links, 316 absolute, 0 conflict copies, all verified against the pre-migration manifest. Lesson saved as a memory.
- 2026-09-24 — applied the approved settings audit (from the 09-23 drafts; Eric approved it at good-morning). Promoted 8 rules to global (d8be213): pdfinfo, pdftoppm, pdftotext, sort, ps, uvx, git add, git commit. Deleted 137 redundant or dead project-local allow entries across 9 files; deny rules are intact. The classifier refused nothing. The kaiseki checked-in `settings.json` removal is kaiseki #25, queued after #23.
- 2026-09-24 — merged planning #7 (f460976, closes #6). good-morning now checks in with PLs before presenting drafts: it reports each PL's `priorities.md` commits and uncommitted edits since good-night's `Written:` line (mtime as the fallback), names unreadable PLs, and re-runs the Owes roll-up. First live run is tomorrow morning.
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
