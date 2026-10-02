# Priorities — settings

Last updated: 2026-09-30

Time-sensitive state for the settings PL. Durable facts live in `CLAUDE.md`; history lives in git and the nikki logs.

## Standing rules

- **Merge authority (Eric, 2026-09-23):** review and merge all changes under `~/.config/lnk` and Claude settings — `~/.claude/` and the skill repos under `~/.claude/skills/`. Review still gates; open findings block. Other PLs' project repos still need Eric directly.
- **Workflow:** `~/.claude/org/workflow.md` Gate 2 — assign → engineer plan → PL sign-off → PR → PL review → merge. PLs don't write product code.

## In flight

**Review rule (2026-09-26):** `/code-review` at high effort returns 15 findings (its cap) on every pass, so rounds don't converge. Block only on silent data loss, regressions the PR introduced, and the PR's own acceptance criteria. Everything else is a small fix-along, a follow-up issue, or won't-fix. Round 2 is the final round: round 3 only checks the listed items. **Merge order:** none pending.

- **Workflow friction fixes** — Eric approved all 8 on 2026-09-23. Ready-to-apply wording has been sent to the coordinator, who owns `~/.claude/org`. The fixed sign-off/review prefixes for `workflow.md` were proposed to `projects` and are pending there.
- **planning:** #16 merged (9f6914f, PR #21); tonight's good-night is the first with DATE pinning. #24 (meetings) waits on Eric.
- **dispatch queue:** #189 in PR #192 (Eric 👍 2026-10-01). An `asyncRewake` waiter replaces the Monitor re-arm loop, saving about 4,400 idle calls a week.
  - Phase A is measured.
  - PR #192 round 1 (2026-10-01) has six blockers. B1, the most serious: a merge would arm every seat. It needs a per-seat opt-in that defaults to off.
  - After round 2: merge with no seat changed, then Phase B on the dispatch seat with the Monitor still armed.
  - Fleet rollout waits on `unread-age` being wired into good-night (planning).
  - After #189: #180 (remote `${HOME}`), #177 (heartbeat) and #187 (dir_phys quoting, low priority). #183 waits on Eric.
- **kaiseki:**
  - #2 (symlinks): merged (8983b6f, PR #41); cambridge is followed. #36 closed (already fixed by #37). #31 merged (54cb813, PR #43): live local branches show as labeled unmerged work, so merged branches must be deleted.
  - #38: merged (33e40ee, PR #42).
  - Queue empty: #33 merged (a28203c, PR #44), #34 closed as not occurring. The fast-lane and plan labels now exist on all 13 skill repos.
- **admin** (new private repo underspecified/admin, 2026-10-02; engineer seat at `~/.claude/skills/admin`): 10/1 receipt-run lessons from `projects`.
  - #1 merged (abcac18, PR #4); deploy links repointed. #5 merged (2c9fa85, PR #7); `admin` is in bootstrap `COMPOSITES` (f1a06f9), and doctor reports ok.
  - #2 merged (24c8239, PR #8, after 2 rounds). #6 assigned (fast-lane), then #9 (`.gitignore` PII guard + trim). #10 holds the robustness follow-ups. #3 `/admin-expense-reimburse`: Eric's comments are folded into the body; it still needs his 👍.
  - lnk backlog: bootstrap never prunes sub-skill links whose target has vanished (PR #4 review item 6).
  - The reimburse-trip domestic variant gets filed as #4 when the coordinator's addendum arrives.

## Waiting on Eric

- 👍 on admin #3 (Gate 1, body revised with your comments).
- ppm-application PDF attach (Eric, via `projects`): the auto-mode classifier blocked my edit as self-modification. It adds `file_upload` and `cp` to the allowed-tools and drops the "can't attach" hard rule. The full change is in this session's scratchpad `ppm_attach_pdf_proposal.md`. Eric applies it himself, or OKs it here.
- 👍 on planning #24? good-night would run `/meeting --headless` on the day's recordings and route each overview to its PL. Three decisions: speaker tagging, the nightly cap, and mail vs. auto-edit. It splits across meeting, `projects` (the columns in `meetings.md`) and planning.
- 👍 on dispatch #183? It would let dispatch pre-approve its own MCP server for a headless cold start, only when the `.mcp.json` entry exactly matches what dispatch writes. Until then, headless wakes into a fresh dir stop at the MCP modal (PR #182 turns that into a warning).
- Restart running remote sessions so they load superpowers (apps and llm_eval on 5 hosts, lab on llm-jp), or let them pick it up at their next restart.
- Report the Apple Mail MCP Sent Items bug upstream (imdinu)? That's outward-facing, so it's Eric's call. The workaround is planning #12.
- Low priority (Eric, 2026-09-23):
  - `sudo powermetrics` for the WindowServer load;
  - the kanban's 16 angle-bracket URLs;
  - Delete `planning/logs/.conflict-stubs-2026-09-24/` from Finder (110 OneDrive placeholder stubs from the #23 incident; Finder sends them to the OneDrive recycle bin). Trash and `rm` both fail on the OneDrive volume.
  - Overleaf token rotation (moved from Eric's TODO, 2026-09-24). `~/.git-credentials` is a stale plaintext file (0600) holding an Overleaf token; no `store` helper reads it anymore. Eric revokes the old token in Overleaf and confirms the new one is in 1Password, then I trash the file.

## Recent

- 2026-10-01 — merged dispatch #186 (b99f3ba, closes #184) and #190 (d478dfd, closes #188), and ran install.sh on tank and all 6 hosts; main CI is green.
  - Remote `wake` now detects a dead claude and respawns it. Every non-answer, multi-pane session or pgrep error counts as ALIVE.
  - tmux targets are exact-matched with `=`; checked live on dgx02 tmux 3.2a.
  - The post-respawn modal check now polls, which fixes #181's local gap too. That was my verification miss, saved as a memory.
  - The `monitor-start` banner goes to stderr, about 12% fewer idle wakes, confirmed live on this seat.
- 2026-10-01 — Eric approved the DOTS version of hansei recommendations 2 and 4, applied in `~/.claude/CLAUDE.md` (80696e2, all hosts):
  - signing refused → leave the work staged, tell Eric once, don't retry. 1Password stays on-demand by design, which settles the old tank-ssh question.
  - `git add` before `git commit -- <new file>`;
  - the Grep/Glob preferences are dropped.

  The hooks are untouched. Recommendation 3 (the hansei analyzer) is skipped. Recommendation 1 became dispatch #188/#189.
- 2026-10-01 — 1Password was locked from about 20:30 on 9/30 until the morning. That held up every commit and push overnight; the hansei digest's item 2 proposes a fix. After the unlock:
  - merged planning #21 (9f6914f, closes #16), so DATE is pinned from tonight;
  - merged dispatch #185 (1be7c37, closes #179) and ran install.sh on tank and all 6 hosts. The mark-read race is gone: the drain prints before it acks and fails closed.
- 2026-09-30 — the 22:00 good-night ran cleanly: daily log at 22:07, drafts at 22:19.
  - It produced the first weekly hansei digest. The five proposals, three of them owned by settings (the idle monitor cost, 1Password signing, the hansei analyzer), are in drafts.md for good-morning.
  - `cambridge` was logged through its symlink (kaiseki #2), and the open PRs showed as "unmerged, on <branch>" (kaiseki #31).
  - Then merged planning #23 (1958af9, closes #18) and deployed it. The 1Password agent was locked, so the planning pull went through `IdentityAgent=none`.
- 2026-09-30 — merged dispatch #182 (b835620, closes #181) after round 2. `wake` now:
  - respawns a dead claude in a live session (a shell in the pane **and** no child process);
  - bounds the kitty probe, which the headless path never touches;
  - never calls a modal-blocked pane alive, and gives correct local and remote remedies.

  Checked live: idle panes have no children on tank, dgx02 and llm-jp. Deployed with install.sh to tank and all 6 hosts. Follow-ups: #183 and #184.
- 2026-09-30 — merged planning #26 (8bfbac6, closes #25): good-morning arms good-night for 22:00, with a power-wake at 21:55. The lnk plist is at 22:00 (be4f396).
- 2026-09-30 — merged kaiseki #39 (5411f72, closes #32) after round 2: `scan_activity` prints absolute paths, and a transcript cwd is printed only if it exists and isn't a duplicate, the coordinator or planning root, or an engineer worktree. A live audit of 09-24..09-30 gives 34 → 8 lines. The nightly `active_projects.py` output is byte-identical. Deployed.
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
