# Priorities — settings

Last updated: 2026-10-25

Time-sensitive state for the settings PL. Durable facts live in `CLAUDE.md`; history lives in git and the nikki logs.

## Standing rules

- **Merge authority (Eric, 2026-09-23):** review and merge all changes under `~/.config/lnk` and Claude settings — `~/.claude/` and the skill repos under `~/.claude/skills/`. Review still gates; open findings block. Other PLs' project repos still need Eric directly.
- **Workflow (Hou-Ren-Sou, org 314e2e9):** I approve issue plans (`Plan approved (PL:settings)`), sign off implementation plans (`Signed off (PL:settings)`) and review (`PL review (settings)`). Eric signs off only on external communication and spending. Report in `## Recent`.
- **Review rule (2026-09-26):** block only on silent data loss, regressions the PR introduced, and the PR's own acceptance criteria. Everything else is a fix-along, a follow-up, or won't-fix. Round 2 is final; round 3 only checks the listed items.
- **Tests:** run every PR's suite myself in a scratch clone (cd in first), on the repo's locked runner. Never `uv run --with`.
- **dispatch PRs:** the pre-push hook replaced Actions (#261). Before each merge, I run `tests/pre_push.sh` on germputer from a scratch clone of the PR head, with the Mac's bats-core copied to a temp dir (no Linux host has bats).
- **Tracked pre-push hooks (dotfiles #26):** a repo opts in by merging `.githooks/pre-push`, and then I add the `git hash-object` id of its lowercased `owner/repo` to `tracked_repos` in `hooks/_chain`. Listed today: lab_runs.

## In flight

- **Eric's 10/25 time and decisions talk (coordinator's brief), one planning issue at a time:** #53 (weekly Check-in), #54 (Your time) and #55 (Eric's asks) are merged. #56 (good-morning: 3 decisions, 14-day flags, focus block) has its plan signed off and is being built. #57 (no blank pages) is next.
- **kaiseki queue:** #67 (nikki narrates waiter mail) has its plan signed off and is being built. #3 is next.
- **Supply chain (lab#112):** the first round is complete, and so is the codex updater. The monthly audit and the upgrade YES/NO list are lab's.
- **claude-limitline:** revisit removing the OAuth fallback after a week on stdin (about 10/29). #8 (trend arrow on an old snapshot) is low priority.
- **Workflow prefixes (proposed to the coordinator 9/23):** the fixed sign-off and review prefixes for `workflow.md`. hansei's audit already matches them; check whether the coordinator still wants them in `workflow.md`.
- **Unassigned follow-ups:**
  - dotfiles: #9, #12 (one host's personal-identity bootstrap branch), #21 (pin uv), #22 (shfmt/shellcheck), #23 (paper search).
  - dispatch: #263 (move its checks to `.githooks/pre-push`; at that merge I add its id and trash TANK's shim), #260, #257, #255, #254, #252, #251, #247, #224, #211, #210, #209, #199.
  - research #36 (title extractor quality). travel #4. meeting #3. kaiseki: none beyond the queue.
  - admin: #13, #16 and #25 (review follow-ups); #10 item 3 is a live check on the next receipt run.
- **lnk backlog:** bootstrap never prunes sub-skill links whose target is gone. The shfmt PostToolUse hook reformats the whole file on any shell edit; fix it by formatting only files that were shfmt-clean before, or only the changed hunk.
- **Unverified until Eric next runs them (Eric 10/9):** admin's B2 scan attachment, the trip-application field names, `/admin-ship`'s live run and admin #20's receipt-picker test (both need Eric at Chrome).

## Waiting on Eric

- ppm-application PDF attach (Eric, via `projects`): the auto-mode classifier blocked my edit as self-modification. It adds `file_upload` and `cp` to the allowed-tools and drops the "can't attach" hard rule. The full change is in this session's scratchpad `ppm_attach_pdf_proposal.md`. Eric applies it himself, or OKs it here.
- Report the Apple Mail MCP Sent Items bug upstream (imdinu)? That's outward-facing, so it needs Eric's yes. Under Hou-Ren-Sou I bring the ready issue text, not a bare question; not drafted yet. The workaround is planning #12.
- Low priority (Eric, 2026-09-23):
  - `sudo powermetrics` for the WindowServer load;
  - the kanban's 16 angle-bracket URLs;
  - Delete `planning/logs/.conflict-stubs-2026-09-24/` from Finder (110 OneDrive placeholder stubs from the #23 incident; Finder sends them to the OneDrive recycle bin). Trash and `rm` both fail on the OneDrive volume.
  - Overleaf token rotation (moved from Eric's TODO, 2026-09-24). `~/.git-credentials` is a stale plaintext file (0600) holding an Overleaf token; no `store` helper reads it anymore. Eric revokes the old token in Overleaf and confirms the new one is in 1Password, then I trash the file.

## Recent

Rolling 1-week window: one short line per entry. Details are in In flight, and history is in git.

- 2026-10-25 — Decision: In flight pruned to open items only (297 → 69 lines), before planning #56 starts flagging untouched priorities. Durable procedures moved to Standing rules.
- 2026-10-25 — Result: lab confirmed dotfiles #26 live. The two hand-installed hooks on llm-jp are trashed, and a real push from llm-jp-2 ran lab_runs's checker from main (2/2 pass). lab#106 item 12 is closed.
- 2026-10-25 — Signed off kaiseki #67's plan: nikki narrates a waiter wake's or kickoff's mail through shared pairing code, with seat_time byte-identical.
- 2026-10-25 — Merged planning #60 (846df1d; on 7 hosts): good-night finds Eric's "I want…" asks, good-morning asks once, and tracked ones become Owes lines, flagged after 14 quiet days. Live find on 10/23: 4 candidates, 1 already tracked. planning #56 is next.
- 2026-10-25 — Merged kaiseki #69 (caa159f; on 7 hosts): nikki and seat_time share one prompt filter (nikki-only prompts 220 → 0; seat_time unchanged on all 666 TANK transcripts). kaiseki #67 (narrate waiter mail) is next.
- 2026-10-25 — Signed off planning #55's plan: Eric's "I want…" asks come from the time ledger's own-prompt tasks (every seat and host; the 120-char cut accepted), and good-morning asks once, then dispatches the Owes line.
- 2026-10-25 — Merged planning #59 (acb397e; on 7 hosts) after 2 rounds: the weekly review shows "Your time" (calendar plus logged), and Tasks is agent-only (10/23: 107.7 h = 80.5 h agent + 27.2 h Eric). Round 1 blocked silent loss on llm-jp's stray logs dir; checked live that it now refuses. Added the global "Eric's Time" rule (lnk 5332ef3). planning #55 is next.
- 2026-10-25 — Merged kaiseki #68 (locked test runner; on 7 hosts) and admin #40 (locked test env; TANK only). All three unpinned installs found today are fixed; noted on lab#112.
- 2026-10-25 — Merged travel #6 (5e53d9f; on 7 hosts): install.sh installs chromium from a locked playwright 1.64.0, matching the scripts' locks. A no-op on TANK.
- 2026-10-25 — Signed off planning #54's plan: Eric's calendar and logged time move out of the agent Tasks table into "Your time" (they were counted twice), and `log_time.py` takes a tag and refuses on hosts without the ledger.
- 2026-10-25 — Merged planning #58 (7ec825e; on 7 hosts): the weekly review opens with the Check-in of every PL's Recent. planning #54 is next.
- 2026-10-25 — Result: three more unpinned `uv run --with` installs found, which my 10/24 search missed. Assigned travel #5 (playwright in install.sh) and admin #39 (test deps); widened kaiseki #66. Correction posted on lab#112.
- 2026-10-25 — Signed off kaiseki #63's plan (one shared prompt filter). #66 goes first so its tests run on a locked pytest.
- 2026-10-25 — Merged kaiseki #65 (46758cf; on 7 hosts): hansei's audit accepts `Plan approved (PL:<slug>)` for Gate 1. Filed kaiseki #66 (lock the test runner; `uv run --with pytest` is unpinned).
- 2026-10-25 — Signed off planning #53's implementation plan: the weekly Check-in reads every PL's Recent, Direction items first.
- 2026-10-25 — Plans approved: planning #53–#57 (the weekly check-in, Eric's time, Eric's asks, good-morning, no blank pages) and kaiseki #64 (fast lane). Assigned #53 and #64; the rest are queued.
- 2026-10-25 — Decision: Waiting on Eric holds only external communication, spending, and things only he can do. Two stale items dropped: dispatch #183 (merged 10/7 as PR #214) and the 9/25 superpowers restarts.
- 2026-10-25 — Decision: PL comments open with hansei's prefixes (`Plan approved (PL:settings)`, `Signed off (PL:settings)`, `PL review (settings)`).
- 2026-10-25 — Org docs pushed and pulled on all 7 hosts (314e2e9, Hou-Ren-Sou).
- 2026-10-25 — codex's self-updater is off on all 7 hosts (Eric's "yes"; table on lab#112).
- 2026-10-25 — dotfiles #26 merged: listed repos' `.githooks/pre-push` runs from main on every host. Decision: a hashed per-repo list, because an owner-wide rule let forks run upstream hooks.
- 2026-10-25 — dispatch #261 merged: tests run in a local pre-push hook, and Actions is off. Decision: Linux coverage is my pre-merge run on germputer.
- 2026-10-25 — dotfiles #24 merged: repo hooks also run from linked worktrees, which re-enables llm_eval's empty-file guard in 33 worktrees.
- 2026-10-24 — Supply-chain first round complete: script locks in 11 repos, MCP and hook pins, bus pins, and the bus rebuilt on 7 hosts.
- 2026-10-24 — Merged research #35 and #38 (library checks live again) and planning #51 (Papers table) and #52 (weekend nikki).
- 2026-10-23 — Merged (10/22–23) dotfiles #16 and #18 (tint), kaiseki #57, #59 and #62 (nikki counts), and claude-limitline #7.
- 2026-10-19 — Merged dispatch #256 (deaf seats restart in place) and planning #44 (remote PLs in good-night).
