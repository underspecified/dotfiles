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
- **dispatch queue:** #189 merged 2026-10-02 (PR #192 → 98d7288; the opt-in is off by default).
  - **Phase B is live on the `projects` coordinator seat** (Eric's call): waiter on, Monitor still armed.
    - Phase C criteria met (evidence on #189, 10/3): the lapsed-Monitor wake (15 s), /compact survival, /clear survival (the waiter woke the seat 31 s after the mail), the 22:00 good-night, and no runaway wakes overnight.
    - Still open: the ~23h30m heartbeat; unread-age in good-night (planning#27, report only, waits on Eric's 👍).
    - Corrected: /clear did not kill the Monitor; SKILL.md #176 holds. What did happen: after /clear the agent couldn't see its running Monitor and armed a second one. That's low harm; it's filed as #202 (single-instance `dispatch-monitor`), unassigned.
  - **#197 gate-before-swap merged** (010fd35, PR #198, 2 rounds). **The fleet is at 010fd35 on all 7 hosts.** Each docker host built a `:candidate`, gated it, and promoted it. On each, the running image ID equals `dispatch-agent-mail:latest`, and `:prev` holds the old image. The orphaned `scripts-agent-mail:latest` tag is removed. dgx02 is userspace (the gate passed). tank's stale May override (`image: scripts-agent-mail:latest`) was trashed first: it would have kept production off the gated image. The other hosts had no override.
  - Follow-ups are in #199: the per-command scan, skipping when the image is unchanged, a production override bypassing the gate, and the first-run failure message overclaiming.
  - haru-5090: install can't re-publish Tailscale Serve (it needs `sudo tailscale set --operator=eric`, which needs a TTY). The existing Serve config still proxies :8765, so it's harmless.
  - #194 merged (39f9bb2, PR #200, 2 rounds), tests and docs only.
    - W14d now covers `waiter off` stopping a live waiter, and mail sent after `off` not waking the seat.
    - The mutation harness now fails on passenger rows; the audit was otherwise clean.
    - SKILL.md has the send-quoting note.
    - Fleet deploy trees are at 39f9bb2 on all 7 hosts; nothing to reinstall.
    - Follow-ups #199 and #201.
  - **planning#24** (overnight `/meeting` on the day's recordings, routed to PLs): Eric 👍'd it on 10/3. Defaults: `SPEAKER_XX` overnight, a 4 h cap, PLs receive overviews as dispatch mail without being woken. Split three ways:
    - `projects`: the rules-file columns, done (029af31).
    - meeting#1 merged (38aff46, PR #2, 2 rounds), with two entry points:
      - `headless.py prep`: background-only, prints one JSON line.
      - `/meeting --headless <dir>`: phases 2–3 + `finish`.
      - Also: whisply pinned to 0.14.0; timeouts kill the process group and scale with duration.
      - Throughput is about 0.2× realtime normally (the 2.3–3× was machine load on 10/4).
      - Follow-ups: meeting#3.
    - The runner must give `prep` stdin from `/dev/null`, and match the calendar event by **most overlap**. Both are relayed to planning.
    - The planning step is PR #31, in round 2 (final). Blockers:
      - unique dirs within a batch;
      - no night routing to the coordinator seat itself, and a failed route is a ⚠️ line;
      - one log per run;
      - the same key for `mark` and `due`;
      - `watch` armed as good-night's last step.

  The fix-alongs include a 6 h left-running guard.
  - **Eric (10/5): run transcription as a monitored background process, handling each transcript as it lands.** This replaces the 4 h cap. The planning engineer is revising its plan: a single-instance runner the seat Monitors.
  - Constraint: OneDrive, so in-place writes only.
  - **planning#27 merged** (e1c8f14, PR #28, 2 rounds): good-night's daily log gets a stale-seat line, report only.
    - Zero seats, or a failure, reads as `check failed`, never "none". A recovery run writes "not checked".
    - Acceptance (and the last #189 criterion but the heartbeat) is the next real good-night. Fleet rollout of the waiter waits on Phase C and on `unread-age` in good-night (planning).
  - After #189: #180 (remote `${HOME}`), #177 (heartbeat) and #187 (dir_phys quoting, low priority). #183 waits on Eric.
- **kaiseki:**
  - #2 (symlinks): merged (8983b6f, PR #41); cambridge is followed. #36 closed (already fixed by #37). #31 merged (54cb813, PR #43): live local branches show as labeled unmerged work, so merged branches must be deleted.
  - #38: merged (33e40ee, PR #42).
  - Queue empty: #33 merged (a28203c, PR #44), #34 closed as not occurring. The fast-lane and plan labels now exist on all 13 skill repos.
- **admin** (new private repo underspecified/admin, 2026-10-02; engineer seat at `~/.claude/skills/admin`): 10/1 receipt-run lessons from `projects`.
  - **New admin PL** (Eric, 10/5) at `~/projects/admin`, which owns non-HR paperwork. It's the repo's main user, filing issues; settings stays the repo's lead (agreed with the coordinator). The `@admin` todo slug is merged (planning PR #30, d4f6b53). Its first wake should be windowed, with Eric present (trust prompt + MCP modal).
  - #1 merged (abcac18, PR #4); deploy links repointed. #5 merged (2c9fa85, PR #7); `admin` is in bootstrap `COMPOSITES` (f1a06f9), and doctor reports ok.
  - Merged 10/2, 2 rounds each: #2 (PR #8), #6 (PR #11), #9 (PR #12), #3 `/admin-expense-reimburse` (PR #14, linked), #10 items 1/2/4 (PR #15, `rakuraku-widgets.md`).
  - #17 merged (0a55059, PR #18): personal charges get classified, never receipt-gathered (Eric's design correction to PR #14).
  - Open: #10 item 3 is a live check on the next receipt run (the coordinator was asked to schedule it). #13 and #16 are review follow-ups, unassigned.
  - lnk backlog: bootstrap never prunes sub-skill links whose target has vanished (PR #4 review item 6). Engineer seats run in the deploy trees (fleet-wide question, PR #7 review).
  - lnk backlog (needs Eric's OK, global hook): **guard `~/.config/lnk` against checkout and switch.**
    - On 10/5 a forked `/code-review` of planning PR #31 inherited the lnk cwd and ran `gh pr checkout` there. The dotfiles tree was swapped for about a minute: every linked file vanished, and Karabiner regenerated a blank config.
    - Restored and verified clean.
    - Proposed: a PreToolUse block on `gh pr checkout` / `git checkout|switch <branch>` when the git toplevel is `~/.config/lnk`. Until then, reviews from this seat are told to use a scratch clone (memory).
  - lnk backlog: the **shfmt PostToolUse hook reformats the whole file** on any shell edit. On 10/2 it reflowed about 90 untouched lines of dispatch `install.sh` and broke deploy.bats D20 (`> "$tmp"` → `>"$tmp"`); it also reflowed `bootstrap.sh` (f1a06f9). Fix: only format a file that was already shfmt-clean before the edit, or format just the changed hunk.
  - #21 merged, 2 rounds each: Part A (0055b46, PR #22: category 128, route-search fares, 60-char comments, row-count guard) and Part B (e6aedb5, PR #23: preflight cross-check, Nissin itinerary, booking.com receipt rule). Open on #21: record the Kokura early-checkout ruling as a rule once admin rules (until then, "ask the user").
  - #19 merged (91b0bd0, PR #24, 2 rounds): `/admin-reimburse-trip-domestic` is linked under `~/.claude/skills/` and listed in the bootstrap `COMPOSITES` comment; doctor reports ok. The shared Denpyo mechanics now live in `rakuraku-widgets.md`, and expense-reimburse routes domestic trips to the new skill. Not run live yet: the field test is the next domestic trip, or #20's session.
    - Follow-up #25 (unassigned): the shared ≤ 60-character JS check names `meisaiContents12`, but the domestic comment field is `meisaiFreeText1`.
  - #20 (receipt-picker live test): signed off; waits on Eric at Chrome (the engineer asked `projects` to schedule it).
  - #26 closed as not planned. Eric (10/5, via the coordinator): "no more exceptions" (apply in advance, keep reservations changeable). It's a rule in the admin PL's CLAUDE.md, and no skill change is wanted. The skills keep "early checkout → ask".

## Waiting on Eric

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
