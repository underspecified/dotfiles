# Priorities — settings

Last updated: 2026-10-06

Time-sensitive state for the settings PL. Durable facts live in `CLAUDE.md`; history lives in git and the nikki logs.

## Standing rules

- **Merge authority (Eric, 2026-09-23):** review and merge all changes under `~/.config/lnk` and Claude settings — `~/.claude/` and the skill repos under `~/.claude/skills/`. Review still gates; open findings block. Other PLs' project repos still need Eric directly.
- **Workflow:** `~/.claude/org/workflow.md` Gate 2 — assign → engineer plan → PL sign-off → PR → PL review → merge. PLs don't write product code.

## In flight

**Review rule (2026-09-26):** `/code-review` at high effort returns 15 findings (its cap) on every pass, so rounds don't converge. Block only on silent data loss, regressions the PR introduced, and the PR's own acceptance criteria. Everything else is a small fix-along, a follow-up issue, or won't-fix. Round 2 is the final round: round 3 only checks the listed items. **Merge order:** none pending.

- **Workflow friction fixes** — Eric approved all 8 on 2026-09-23. Ready-to-apply wording has been sent to the coordinator, who owns `~/.claude/org`. The fixed sign-off/review prefixes for `workflow.md` were proposed to `projects` and are pending there.
- **planning:** #16 merged (9f6914f, PR #21); tonight's good-night is the first with DATE pinning. #24 (meetings) waits on Eric.
- **dispatch queue:** #189 merged 2026-10-02 (PR #192 → 98d7288; the opt-in is off by default).
  - **#189 reopened 10/5; it's top priority (Eric, direct).** Eric's ruling: "Yes, roll out fleetwide now". The heartbeat criterion and the one-seat-at-a-time order are waived.
    - Blocker: the waiter gates on marker **and** sentinel, so `waiter on` + `monitor off` leaves a seat dark.
    - PL decision: Option 1, a decoupling PR. The waiter gates on the marker alone, and `waiter off` is its off switch. It goes ahead of #187.
    - **Rolled out 10/6.** PR #204 merged as a976fff after 2 rounds. All 7 hosts are deployed and gate-verified. 18 of 21 seats are waiter-only and woke on a probe in 10–71 s.
      - `lnk` is the canary: waiter on, Monitor kept.
      - llm-jp `lab` starts its waiter at its next turn.
      - llm-jp-2 apps and llm_eval are **logged out**; they need Eric's `/login`.
      - Reported on #189 and to the coordinator.
    - The fix-alongs merged as #206 (80db048), with follow-ups in #205. They're deployed on all 7 hosts, and a send probe per host woke its seat.
    - **New seats start with the waiter off** (`hardware` came up that way at 12:50; I switched it by hand and probed it). Filed as #208, a bug, fast lane, next after #207.
    - Next: the heartbeat, first observable around 10/7 10:40.
  - **#187 merged** (4cae04d, PR #207, 2 rounds): seven sites, and the decode fails closed. Deployed on all 7 hosts. Send probes woke their seats, including uncached resolves on germputer and dgx02.
    - Its first test version leaked a real tmux session plus a live `claude` on tank; I killed it and the isolation is fixed. The fix-alongs merged as #212 (7f6bbe0) and are deployed and probed on all 7 hosts.
  - **#208 merged** (a023752, PR #213, 1 round): every wake arms the waiter unless the seat has a `waiter off` tombstone, and `status` has 3 states. Deployed and probed on all 7 hosts.
  - **#183 merged** (fb19219, PR #214, 2 rounds): dispatch pre-approves only its own `agent-mail` entry, never overwrites or approves a foreign one, revokes on drift, respects `disabledMcpjsonServers`, and fails closed on an unparseable `.mcp.json`. Deployed and probed on all 7 hosts.
  - **#202+#177 merged** (d1ac018, PR #216, 2 rounds plus a CI fix). The ubuntu red had two dev-box-only causes: `dispatch` was installed and a bus was running. The fix is tests only. Deployed, gate-verified and send-probed on all 7 hosts. Carry-over: `_beat_lock` should `kill -0` before standing down; the engineer is filing it.
  - **#218 merged** (9820787, PR #222, 2 rounds): `wake --fresh`, and the mid-turn check is fixed for claude 2.1.291's spinner. Deployed and probed on all 7 hosts.
    - The four seats (EWC, RwB, HR, animations) were restarted fresh: no `--continue` in the argv, new transcripts, waiters running, probes woke all four, no `autoCompactWindow` key written.
    - Org step 9 now says `wake --fresh` (642ba9b, pulled on all hosts).
    - Follow-up #223: `--fresh` prints a false "resuming" cost note.
  - **#191+#201 merged** (26d6205, PR #225) and #223 merged (a1d4837, PR #226). Both deployed and probed on all 7 hosts. The dispatch engineer is idle.
  - **11 idle TANK seats shut down (Eric, 10/7):** kaiseki, planning, cambridge, EWC, dispatch, email-inbox, admin, HR, animations, hardware, haru.md.
  - **#227 merged and live** (PR #229 → b258e3a, 2 rounds): `send` wakes a stopped seat by default (`--continue`/`--fresh [--force]`/`--no-wake`), takes `--file`/`--rm`/`--json`, and rc 3 = posted, never resend. It won't start a second claude beside one running outside dispatch tmux. Installed on all 7 hosts on 10/7, ~19:00.
    - Probes, all `--no-wake`: planning, llm-jp llm_gen, haru-5090 apps and dgx02 llm_eval each read theirs (21–93 s). germputer, llm-jp-2 and haru-4090 have no live seats (the lab PL shut them down), so those were post-only.
    - planning#32 merged (PR #33 → b758d74) and fast-forwarded on TANK: `dispatch_item.sh` is gone, and good-night always passes `--no-wake`. The coordinator was told (send wakes by default; broadcasts use `--no-wake`).
    - Follow-ups: #230 (deaf seat on invalid settings, MCP modal counted as success, fd leak, stray root files).
    - **#230 merged** (PR #234 → f8127db, 2 rounds; Mac and germputer 767/767). wake fails closed on a deaf seat or either prompt, with prompt detection anchored to the dialog footer. Cold starts close inherited fds, and the stray root files are gone. Deployed on all 7 hosts on 10/8 ~12:30. Idle seats read their probes (TANK haru.md 113 s, llm-jp lab 10 s, dgx02 10 s); the 4 hosts with no seats were post-only. The dispatch seat and llm-jp llm_eval were mid-turn, so their probes wait for the turn to end. #233 (W16 on germputer) is open.
    - **Pins check (10/8 12:06):** 1 cloud-only file in 24 `.git` dirs, EWC `.git/hooks/pre-receive.sample`, which git never reads. The pins held.
    - **#235 merged** (PR #237 → ad7b4aa, 2 rounds; 802/802 on Mac and germputer). Remote seats pre-approve dispatch's own `agent-mail`, and a dispatch-recorded grant is withdrawn on drift while a human's is kept. Each host has one definition of its bus URL, from `bus.env`, and an unknown port approves nothing. One hook install per launch. Deployed on all 7 hosts on 10/8; lab and dgx02 llm_eval read their probes in 21 s, and the 4 hosts with no seats were post-only.
    - **#238 merged** (PR #241 → 5d5f16e, round 1). Eric approved the dgx02 writes in the dispatch seat on 10/9. Done there:
      - The duplicate docker bus is gone (0 agents, 0 messages, 0 recipients before removal), and llm_eval points at `:18765`.
      - The 09-21 rootless docker is fully reverted: unit, 3.7 GB of data, 11 `~/bin` files, buildx, `scripts/.env`. zsh, linger and the ghcr auth are kept. I re-verified all of it read-only.
      - `_one_bus_per_box` now refuses an install in either mode while the other mode's bus runs; U15/U16 fail on the old code.
      - Deployed on all 7 hosts (rc 0, guard passes in each mode). Probes: lab 31 s, dgx02 llm_eval 20 s, tank llm 20 s; 4 post-only.
      - The seat reported clean and was destroyed. Follow-up #240 (`bus-version` reads bus.env's ref). Non-blocking review note: `docker inspect` in the guard has no timeout.
      - The system-docker detour was dropped (Eric via the coordinator, 10/9).
    - **#233/#236 merged** (PR #242 → 3dcf917, round 1, no findings). W16 resolves hooks from the test file, the L12 lint forbids cwd-relative repo paths, and CI runs the suite off-root (809/809 on Mac, germputer and CI). Off-root, the old W16 fails and L12 flags it. Tests/CI/docs only, so the deploy trees were fast-forwarded on all 7 hosts with no install, and none drifted. The seat reported clean and was destroyed (a stray rename-only PR #243 was closed). The #233 plan moves to done in the #239 PR.
    - **#239 plan signed off** 10/9 (detect dead seats, from the 10/8 hansei digest). Gate 1 passed: Eric's 👍 verified on GitHub.
      - **Ask 1:** `send`/`peek` warn when the recipient's last turn was an API error, read from its own transcript. My sign-off adds: bound the read with `tail -c`, and cap the text.
      - **Ask 2** (measured): the waiter didn't re-arm after an API-error turn, because `StopFailure` fires instead of `Stop`. Fix: register it on `StopFailure` too.
      - **Ask 3:** `dispatch-monitor` and the SessionStart re-arm refuse on waiter seats. llm-jp's `llm_gen` Monitor was stopped.
      - Eric approved asks 2 and 3 in the seat, (a) for ask 3.
      - **Merged** (PR #244 → b6b9cf9, round 1, no findings). 219/219 on the touched files, and the new rows fail on main's code. `install.sh` rc 0 on all 7 hosts. Probes: dgx02 10 s, lab 21 s, tank llm 30 s; 4 post-only.
      - Seats woken before the deploy keep a Stop-only waiter until their next wake. The seat reported clean and was destroyed. The #239 plan moves to done in the next PR.
      - **Live-confirmed 10/9 ~20:50.** The #240 seat's turn died ("Connection lost mid-response"). `peek` and `send --json` both warned (`server_error`), and the nudge was read in 11 s, so the StopFailure re-arm works on a real failure.
    - **Assigned 10/9** (Eric: "assign both"), each to a fresh seat:
      - **dispatch#240 merged** (PR #245 → f189372, round 1, no findings; 8/8, and BV6/BV7 fail on main's code). `bus-version` reads bus.env's ref when it exists, else `scripts/.env`. dgx02 now shows `pinned ref: b13d635` (was "unknown"). `install.sh` rc 0 on all 7 hosts. Probes: tank dispatch 32 s, dgx02 21 s, lab 32 s; 4 post-only. The seat reported clean and was destroyed. The #240 plan moves to done in the next dispatch PR.
      - **kaiseki#47 merged** (PR #48 → 5edce0f, round 1, no findings; 257/257, and the 3 new tests fail on main's code). Retries need a failed run first: lnk's count goes from 209 to 2. TODOs must open a comment (lnk 4 → 1). Cache reads get their own field. The tank tree is fast-forwarded. The seat reported clean and was destroyed.
    - **dispatch#231 assigned 10/10** to a fresh seat (bug fix, no Gate 1). A remote cold start (`wake`, `wake --headless`, `send --fresh`) fails from a Linux sender, because GNU `base64` wraps the launch command. Third hit: lab reported llm_eval@llm-jp → germputer. Lab uses an ssh workaround and has been told it'll hear when the fix is live.
    - **kaiseki#45 merged** (PR #46 → 69506ed, round 1, no findings; 254/254, and the 3 new tests fail on the old analyzer). hansei counts only in-window timestamped user/assistant records, and `.json` is no longer counted as a script. dispatch's 10/8 numbers go from 21 sessions/45,908 messages to 8/12,491. The tank tree is fast-forwarded and doctor is clean. The seat reported clean (no worktrees, on main) and was destroyed. The merge closed #45, so the retry-detector, `scan_todos` tests/ and cache-token items moved to kaiseki#47 (unassigned).
    - **Exposed token (hansei digest #1):** on 10/6 my `chrome_diag.sh` printed `CLAUDE_CODE_OAUTH_TOKEN` (cut at 120 chars) into this session's transcript. Rule added to `rules/safety.md` § Secrets in Diagnostic Output.
      - **Audit (10/9, Eric via the coordinator).** It ran on all 7 hosts and matched by value fingerprint, not by variable name; the scans were self-tested with a fake token. The leaked token is ccp's **`personal`** profile (`op://Personal/claude-personal/credential`, also the active profile); `work` is a different token.
        - No live copy anywhere: none in tmux env (global or session, default or dispatch server), running processes, rc/env files, settings `env` blocks, systemd/launchd, ccp/dispatch state, temp files or shell history.
        - The only other copies are 2 transcripts on tank: this session and the 10/8 hansei subagent (`…projects/1555ba14…/subagents/agent-a7855dae….jsonl`).
        - No GitHub Actions or Dependabot secret across 72 repos. Codespaces user secrets weren't readable (gh scope).
        - Skipped 5 cloud-only settings files and 4 hansei reports, to avoid downloading them.
        - **Nothing to remove on the hosts.** 10/9: Eric dropped the Anthropic support contact, so the old token is not revoked server-side. It was exposed only locally, in 2 transcripts on tank.
        - **10/9: `personal` re-issued.** Eric ran `setup-token` and replaced the 1P item; the new fingerprint `a991be1a` differs from the leak. The profile is mapped again but deliberately not active, so ccp has no active profile and `ccp run` needs `-p`.
      - **Separate finding:** reported to Eric directly on 10/9 and recorded in this seat's private memory, not here, because this file is public. Eric decided on 10/9 to leave it; closed.
    - **1Password-locked ssh: fixed 10/9** (lnk 2049aca, Eric: "waiting for 1p is causing too much trouble"). 1Password's `agent.toml` (machine-local) now serves only `eric_nichols` and `underspecified`. Commit signing uses the `hri_jp` file via `.config/git/macos.conf` (includeIf `gitdir:/Users/`). Verified with the agent off: GitHub, germputer, llm-jp and dgx02, a signed commit, and a push.
    - **planning#34 merged** (PR #35 → 95e67cc), and TANK fast-forwarded on 10/8. good-night's unmatched recordings now take the unlisted default from `rules/meetings.md` (`en`; coordinator commit bc90491) instead of auto-detect. `/meeting`'s own default is left as-is. The seat was destroyed after `clean`.
    - **#228 merged** (PR #232 → f1f6033, 1 round): CLAUDE.md 177.6k → 7.0k chars, with 7 rules plus 3 bus invariants. The 11 rules found only in CLAUDE.md are now code comments. Deployed and probed on all 7 hosts (live seats read their probes in 10–31 s; germputer, llm-jp-2 and haru-4090 post-only).
    - **Seat cycle (org b4df768, Eric 10/7; pulled on all 7 hosts):** assign with `send --fresh "<issue URL>"`; after `clean` + deploy + `git worktree list`, run `dispatch -C <dir> destroy`. The planning seat was destroyed after its `clean` 10/7. dispatch seat destroyed after #228's `clean`; #230 assigned 10/7 with `send --fresh --file` (woke:true, no `--continue` in the argv; first real use of #227).
  - **OneDrive / git (10/7):**
    - **Packed 27 repos** (Eric paused and resumed sync), about 5,800 `.git` files down to under 800. Backups are in `~/backups/git-*20261007*`.
    - **OneDrive silently restored 2 gc-rewritten reflogs.** I restored the pruned commits from backup. All refs were verified against the backups.
    - **Settings:** every synced repo has `gc.auto 256` plus `gc.reflogExpire never`, `gc.reflogExpireUnreachable never` and `gc.packRefs false`. The local ones (lnk, haru.md, lab) have `gc.auto 256` only.
    - **Eric pinned all 24 synced `.git` folders** ("Always Keep on This Device"). The pin state isn't readable from the CLI.
    - **Check on 10/8:** `find <repo>/.git -type f -flags +dataless` should still be 0 in all 24. It was 0 at 10/7 15:53.
    - **OneDrive watchdog: dropped 10/9.** OneDrive has run continuously since 10/7 11:27, with no crash reports in 14 days, after the git packing. Revisit only if it dies again.
  - **email-inbox:**
    - #2 (replies over-quoted) is merged (PR #3) and live. It was verified with a real Apple Mail self-send.
    - #4 (`compose_email` new mail hiding the body in a cite blockquote) was closed 10/9 on Eric's confirmation that it's fixed (upstream MCP; no change here). The PR #3 test drafts in Exchange Deleted Items are harmless; Eric empties them whenever.
  - **admin:**
    - #30 (ADM manuals), the #30 follow-up (return-month deadline), #29 (B2 海外発送) and #31 (`/admin-trip-apply`) are all merged and live on tank.
    - Unverified: the B2 scan attachment and the trip-application field names. Eric 10/9: verify them the next time he runs those workflows, with no dedicated test session.
  - (History) **#218 was top priority** (Eric 10/6: "better hurry up"). It adds `wake --fresh` and writes `autoCompactWindow: 400000` into engineer seats' `settings.local.json` only if the key is absent; PL seats inherit the global 600k.
    - Plan signed off 10/6 with 2 conditions: a cold seat skips the turn check, and the `**Seat role:**` parse is anchored at line start.
    - Acceptance includes the `/autocompact` picker reading 400k in a fresh engineer seat. I measured that a project-local top-level key beats a user per-model one.
    - After merge: the coordinator updates `workflow.md` step 9 from "wakes the seat" to `wake --fresh`. Until then, `destroy` + `wake` resumes, and only `/clear` gives a fresh context.
    - **After deploy (Eric 10/6, "just those four"):** run `wake --fresh` on EWC, RwB, HR and animations. All four were switched to waiter-only on 10/6, but EWC is live without a waiter until its next turn.
    - Next: #191+#201.
  - **Compaction:**
    - The global `autoCompactWindow` is 600000 (13b1906) on all hosts.
    - The dispatch typed `/compact` is off (`dispatch autocompact off`); #218 deprecates it.
    - Running sessions didn't pick up the new key; fresh ones do. Eric set it fleetwide by hand.
    - `/autocompact` writes `modelSettings` into the tracked settings file. I reset the 5 remote hosts whose only difference was a moved key to HEAD (backups at `~/.cache/settings.json.bak-20261006`). Eric then kept `"model": "opus[1m]"`, so tank and dgx02 are back at HEAD too, and the whole fleet is clean.
  - **Branch hygiene** (org 35349e4, coordinator, approved by Eric): one worktree per issue off a fresh `origin/main`; after merge the engineer cleans up and replies `clean`. The tank skill engineers admin, kaiseki and planning confirmed, and I verified them. The coordinator is to push it and brief the PLs; then I pull `~/.claude/org` on the 6 remotes.
  - **admin#28 (`/admin-ship`) merged and deployed.** The live dry run needs Eric at Chrome.
  - **Brew upgrade, 10/6 13:50–14:40 (manual):** it removed python@3.14.6 (Python MCPs broke until reconnected), reinstalled Docker (the tank bus incident below) and reinstalled 1Password (signing failed). Mail.app: AutoReplyFormat is off and SendFormat is Plain, so replies are plain text.
  - **Tank bus incident, 10/6 14:13–14:44:** a Docker VM crash left the git archive with empty objects. Repaired and verified; follow-up #211. "Failed" sends in that window were delivered.
  - **Tank `ccp unstage`** (Eric): Claude in Chrome and computer use need the keychain login. `launch_ws` no longer stages the token (c7a6332).
    - Follow-ups filed: #209 (the ack `reply-to=` host isn't validated) and #210 (tmux `-t` without `=` matches by prefix).
  - **Phase B is live on the `projects` coordinator seat** (Eric's call): waiter on, Monitor still armed.
    - Phase C criteria met (evidence on #189, 10/3): the lapsed-Monitor wake (15 s), /compact survival, /clear survival (the waiter woke the seat 31 s after the mail), the 22:00 good-night, and no runaway wakes overnight.
    - Still open: the ~23h30m heartbeat. unread-age in good-night is merged (planning#27); its first real run is the next good-night.
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
    - **The planning step is merged** (08a489e, PR #31, 2 rounds), per Eric's 10/5 call: a monitored background runner, each transcript handled as it lands, no cap.
      - It processes recordings from 10/5 on, with a 6 h left-running guard.
      - `coordinator` and `unrouted` overviews are never dispatched at night.
      - The coordinator seat is briefed.
      - **Accepted 10/5 at good-night.** The runner started at 22:02 and ran 2 of 2, finishing at 22:16. One overview went to `coordinator` and one is `unrouted`; neither was dispatched. `due` now shows `already: 2`, so both are marked.
        - The hospital sync was detected as `nn` because of leading noise, and the transcript has loops. Added to meeting#3 as item 4.
  - Constraint: OneDrive, so in-place writes only.
  - **planning#27 merged** (e1c8f14, PR #28, 2 rounds): good-night's daily log gets a stale-seat line, report only.
    - Zero seats, or a failure, reads as `check failed`, never "none". A recovery run writes "not checked".
    - **Accepted 10/5:** the log reads "kaiseki 2.9h". kaiseki went dark from my monitor-off test, and it needs a turn to restart its waiter during the rollout.
  - **Eric 👍'd 9 open issues (10/5, verified).** The queue, one at a time:
    1. #187 dir_phys injection
    2. #183 MCP pre-approve
    3. #202 single-instance monitor
    4. #180 remote HOME
    5. #191 sentinel leak
    6. #193 unread-age vs drain
    7. #177 heartbeat
    8. #199 Dockerfile scan
    9. #201 stub port

  Not approved: #165, #130, #118, #106.
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
  - **lnk live-tree guard: landed on 10/9** (cc947a4; Eric approved directly). `git_gate.sh` section 0 blocks `gh pr checkout` and `git checkout|switch|stash|reset` whenever the target's toplevel is the live lnk tree; worktrees and other repos pass. The first install denied my own commit (a body line began "git stash"), so scanning now stops after a line that leaves a quote open or opens a heredoc. 22/22 on tank and germputer, plus a live denial on tank. **Fleet-wide since 10/9:** all 6 Linux hosts were pulled to lnk 4f56929 (along with the new `rules/questions.md`, the "questions to Eric must be self-contained" rule relayed from lab). llm-jp kept its local settings.json edit.
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
