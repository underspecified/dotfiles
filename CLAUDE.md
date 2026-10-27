# Settings — System Configuration + Claude Skills

**Seat role:** PL settings

Home of the `settings` PL: `~/.config/lnk/`, the dotfiles repo managed by `lnk`. It pushes to the **public** `underspecified/dotfiles`, so never commit secrets. For role, workflow and roster see `~/.claude/org/` (`pl.md`, `workflow.md`, `responsibilities.md`). **Time-sensitive state: `priorities.md`.** It is a gitignored symlink into `private/`, its own private repo (`underspecified/settings-private`), so this repo never publishes it. Edit and commit `private/priorities.md` there: an editor that writes by rename would replace the symlink with a file.

## Scope

System settings, Claude skills, hooks, hookify rules, MCP configs, dotfiles. **Lowest velocity, highest blast radius:** a broken hook affects every session, and every other PL depends on the skills and dispatch infrastructure managed here. Digest cadence: biweekly.

- **Owns:** `~/.config/lnk/`, `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.claude/hooks/` + hookify rules, MCP configs, new-machine setup scripts.
- **Engineering PL for the skill repos** under `~/.claude/skills/`: admin, computation-graph, dispatch, email-inbox, figure, gantt-chart, kaiseki, meeting, paper, pdf-immersive-html, planning, presentation, research, travel. Each has its own engineer seat. This seat signs off plans, reviews and merges, and never implements there. Other PLs request changes by filing an issue on the skill repo or by dispatching this seat.
- **Out of scope:** per-project CLAUDE.md (owned by that PL), per-PL memory, app settings unrelated to the dev workflow.

## Blast-radius rules

- Test new hooks on one project before global rollout.
- Never disable safety rules (`block-rm`, `block-force-push`, AppleScript-send block, `mail_send_gate.sh` + the Apple Mail deny rules) without Eric's explicit OK.
- When a canonical MCP is missing, ask for a `/mcp` reconnect. Don't roll out AppleScript fallbacks proactively.
- Skill deploy trees (`~/.claude/skills/<name>`) stay on `main` and clean (`rules/skill.md`). After a merge, fast-forward the tree and redeploy wherever there is a deploy step (dispatch: `install.sh`).

## Gotchas

- `~/.claude/CLAUDE.md` and `~/.claude/rules/*` are symlinks into this repo. The exception is `rules/signature.md`: untracked PII that must never be committed.
- `~/.claude/settings.json` is `.claude/settings.json` here (tracked, public). Every hook script it calls must also be listed in `.lnk`, or `lnk pull` never links it and the hook fails on every other box (f803bb6).
- `~/.claude/settings.local.json` is the **`~` project's** local file, not a user-level override: only sessions started in `~` read it (f205412 broke che-ical this way). Put tank-only plugins in the shared `settings.json` instead. On Linux such a plugin stays enabled but uninstalled, which is a no-op.
- The hook toolchain (ruff, rumdl, panache, shfmt, shellcheck, jq) comes from `.claude/hooks/bootstrap.sh`. Without it, the PostToolUse formatters silently do nothing.
- Default effort is set by `env.CLAUDE_CODE_EFFORT_LEVEL` in `settings.json`, not by `effortLevel` alone. Claude Code pins a launch-default effort for each newly released model, and that pin outranks the saved `effortLevel` (measured: fresh sessions ran at medium). `max` cannot be a saved default.
- The `~/.claude` hookify rules (`block-rm`, `block-force-push`, `block-applescript-mail-send` and the warns) are global only through `.claude/patches/hookify-global-rules.patch`. Upstream hookify reads only `$CWD/.claude/`. The SessionStart hook re-applies the patch to every installed hookify copy. Without the patch, the rules fire only in `~` and `~/.config/lnk` sessions (measured 10-10).
- security-guidance's model reviews (end-of-turn, per-commit, push) are off: `ENABLE_CODE_SECURITY_REVIEW=0` in `settings.json` `env` (Eric, 10/19). Its free pattern warnings stay on. PR reviewers run `/security-review` by hand on PRs that handle shell, ssh, credentials or outside input, in a worktree or scratch clone.
- `.claude/hooks/md_format.sh` skips the Obsidian vault and files with conflict markers. Its header explains why; read it before removing a guard.
- Don't use the legacy `setup.sh`; use `lnk`. The shell is zsh with `ZDOTDIR=~/.config/zsh`.

## Manifests

- `.lnk` applies to all hosts.
- `.lnk.macos` and `.lnk.linux` are selected by `uname -s`. `.lnk.linux` is pulled on **any** Linux host; its GUI helpers become dead but harmless symlinks on headless boxes.
- The host file `.lnk.nosudo` is layered **on top of** the others (lnk has no exclusion mechanism). It applies only with `--host nosudo` on `lnk pull` / `add` / `list`, and `lnk pull --host nosudo` links **only** that layer. So a nosudo box needs both `lnk pull` and `lnk pull --host nosudo` (dgx02, 10/16).

## Git

- Commit messages: `lnk: …` or `<component>: …`. Commits are SSH-signed (`gpg.format = ssh`, verified against `~/.config/git/allowed_signers`).
- Auth prefers SSH.
  - **git, every host:** `.config/git/config` sets `core.sshCommand` (agent off, `-i ~/.ssh/hri_jp`) and `user.signingkey = ~/.ssh/hri_jp`.
    - Transport never asks an agent. A remote that needs a key other than `hri_jp` sets a repo-local `core.sshCommand`.
    - Signing (`ssh-keygen -Y sign`) still asks the agent in `SSH_AUTH_SOCK` whether it holds `hri_jp`, then signs from the file, because 1Password doesn't serve it (`agent.toml`). If 1Password ever serves `hri_jp` again, the fallback is a `gpg.ssh.program` wrapper that runs `ssh-keygen` with `SSH_AUTH_SOCK` unset.
    - Find a signing-key override with `git config --show-origin --get user.signingkey`.
  - **Other ssh, macOS:** the 1Password agent plus an additive, passphrase-free `IdentityFile ~/.ssh/hri_jp`. 1Password does **not** serve `hri_jp` (its `agent.toml`); if it did, ssh would merge the two into one identity, and a locked 1Password would block the file.
  - **Other ssh, Linux:** ssh-agent via keychain.
  - **HTTPS fallback:** `gh auth git-credential` for GitHub, and the in-memory `cache` helper for Overleaf (HTTPS-only). Never the plaintext `store` helper.
  - **gh on Linux:** log in with `gh auth login --insecure-storage`, which keeps the token in `~/.config/gh/hosts.yml` (untracked). The desktop keyring stays locked after a reboot until someone logs into the desktop, and gh then reports the token as invalid (llm-jp-2, 10-10).
- `hooks/` is every repo's hooks dir: `core.hooksPath` is set in `.config/git/config`. One script, `_chain`, is symlinked under each hook name.
  - It runs the repo's **own** `.git/hooks/<name>` first, because `core.hooksPath` replaces the hooks dir wholesale and would otherwise silently disable per-repo hooks everywhere.
  - Guards: `pre-commit` blocks an `autoMode` key in a staged `.claude/settings.json`. `pre-commit` and `pre-merge-commit` block a repo-local `user.signingkey` in a repo that signs.
  - Tracked `pre-push`: `_chain` runs `.githooks/pre-push` from the remote's main (as of the last fetch, never the branch's copy) after the repo's own hook, for repos on `tracked_repos` in `_chain`. That list holds hashes, not names. To opt a repo in, merge its hook first, then add its id in a PR here (the recipe is in `_chain`).

## Bootstrap

`bootstrap.sh`, auto-run by `lnk init -r`, picks the installer (order in its header). Every installer runs `~/.claude/bootstrap.sh`.

- `installers/nosudo/` is independent of `installers/linux/`. It is user-space only, with one idempotent `install_<tool>.sh` per tool. It pins btop v1.3.2 (the last C++20 release with GPU support) and builds nvtop NVIDIA-only, to avoid the libdrm dev packages.
- The dispatcher does **not** pass `--host` through (`lnk init` has no `--host`), so on a nosudo box run `lnk pull --host nosudo` once after init, and run both pulls after any later update.

## Telemetry

Claude Code sends its metrics to an OpenTelemetry Collector on the same host. Logs and traces stay off.

- **On:** the `CLAUDE_CODE_ENABLE_TELEMETRY` and `OTEL_*` keys in `.claude/settings.json` `env`.
- **Collector:** `installers/all/install_otelcol.sh` installs it. Every installer runs it. To change it, edit `installers/all/otelcol/` and re-run the script.
- **File:** `~/.local/state/otelcol/metrics.jsonl`, one OTLP/JSON request per line, rotated at 50 MB. The lines carry the account email and ids, so the directory is owner-only (0700).
- **Check:** `launchctl print gui/$(id -u)/com.eric.otelcol` or `systemctl --user status otelcol`. `lsof -nP -iTCP:24318 -sTCP:LISTEN` shows only `127.0.0.1`.
- **Off on one host:** `launchctl bootout gui/$(id -u)/com.eric.otelcol` and `trash ~/Library/LaunchAgents/com.eric.otelcol.plist`, or `systemctl --user disable --now otelcol`. Sessions run fine without it. Re-running the installer turns it back on.
- **Off everywhere:** remove those `env` keys.
- **Read at launch:** a running session starts sending only after a restart.
- **Not inherited:** tool subprocesses get `CLAUDE_CODE_ENABLE_TELEMETRY` but none of the `OTEL_*` keys, so a session's Bash env never shows them, even in a session that sends (measured 10/17). Readers filter on `service.name` (`claude-code`, `claude-code-desktop`).
