# Settings — System Configuration + Claude Skills

**Seat role:** PL settings

Home of the `settings` PL: `~/.config/lnk/`, the dotfiles repo managed by `lnk`. It pushes to the **public** `underspecified/dotfiles`, so never commit secrets. For role, workflow and roster see `~/.claude/org/` (`pl.md`, `workflow.md`, `responsibilities.md`). **Time-sensitive state: `priorities.md`.**

## Scope

System settings, Claude skills, hooks, hookify rules, MCP configs, dotfiles. **Lowest velocity, highest blast radius:** a broken hook affects every session, and every other PL depends on the skills and dispatch infrastructure managed here. Digest cadence: biweekly.

- **Owns:** `~/.config/lnk/`, `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.claude/hooks/` + hookify rules, MCP configs, new-machine setup scripts.
- **Engineering PL for the skill repos** under `~/.claude/skills/`: computation-graph, dispatch, email-inbox, figure, gantt-chart, kaiseki, meeting, paper, pdf-immersive-html, planning, presentation, research, travel. Each has its own engineer seat. This seat signs off plans, reviews and merges, and never implements there. Other PLs request changes by filing an issue on the skill repo or by dispatching this seat.
- **Out of scope:** per-project CLAUDE.md (owned by that PL), per-PL memory, app settings unrelated to the dev workflow.

## Blast-radius rules

- Test new hooks on one project before global rollout.
- Never disable safety rules (`block-rm`, `block-force-push`, AppleScript-send block) without Eric's explicit OK.
- When a canonical MCP is missing, ask for a `/mcp` reconnect. Don't roll out AppleScript fallbacks proactively.
- Skill deploy trees (`~/.claude/skills/<name>`) stay on `main` and clean (`rules/skill.md`). After a merge, fast-forward the tree and redeploy wherever there is a deploy step (dispatch: `install.sh`).

## Gotchas

- `~/.claude/CLAUDE.md` and `~/.claude/rules/*` are symlinks into this repo. The exception is `rules/signature.md`: untracked PII that must never be committed.
- `~/.claude/settings.json` is `.claude/settings.json` here (tracked, public). Every hook script it calls must also be listed in `.lnk`, or `lnk pull` never links it and the hook fails on every other box (f803bb6).
- The hook toolchain (ruff, rumdl, panache, shfmt, shellcheck, jq) comes from `.claude/hooks/bootstrap.sh`. Without it, the PostToolUse formatters silently do nothing.
- Default effort is set by `env.CLAUDE_CODE_EFFORT_LEVEL` in `settings.json`, not by `effortLevel` alone. Claude Code pins a launch-default effort for each newly released model, and that pin outranks the saved `effortLevel` (measured: fresh sessions ran at medium). `max` cannot be a saved default.
- `.claude/hooks/md_format.sh` skips the Obsidian vault and files with conflict markers. Its header explains why; read it before removing a guard.
- Don't use the legacy `setup.sh`; use `lnk`. The shell is zsh with `ZDOTDIR=~/.config/zsh`.

## Manifests

- `.lnk` applies to all hosts.
- `.lnk.macos` and `.lnk.linux` are selected by `uname -s`. `.lnk.linux` is pulled on **any** Linux host; its GUI helpers become dead but harmless symlinks on headless boxes.
- The host file `.lnk.nosudo` is layered **on top of** the others (lnk has no exclusion mechanism). It applies only with `--host nosudo` on `lnk pull` / `add` / `list`.

## Git

- Commit messages: `lnk: …` or `<component>: …`. Commits are SSH-signed (`gpg.format = ssh`, verified against `~/.config/git/allowed_signers`).
- Auth prefers SSH.
  - **macOS:** the 1Password agent plus an additive, passphrase-free `IdentityFile ~/.ssh/hri_jp`. A locked 1Password offers zero identities, so ssh falls through to the key and non-interactive sessions keep working.
  - **Linux:** ssh-agent via keychain.
  - **HTTPS fallback:** `gh auth git-credential` for GitHub, and the in-memory `cache` helper for Overleaf (HTTPS-only). Never the plaintext `store` helper.
- `hooks/` is every repo's hooks dir: `core.hooksPath` is set in `.config/git/config`. One script, `_chain`, is symlinked under each hook name.
  - It runs the repo's **own** `.git/hooks/<name>` first, because `core.hooksPath` replaces the hooks dir wholesale and would otherwise silently disable per-repo hooks everywhere.
  - Guard: `pre-commit` blocks an `autoMode` key in a staged `.claude/settings.json`.

## Bootstrap

`bootstrap.sh`, auto-run by `lnk init -r`, picks one installer in this order:

1. the `LNK_HOST=nosudo` override;
2. on Linux without passwordless sudo, `installers/nosudo/install.sh`;
3. otherwise the OS default: `installers/macos/bootstrap_finish.sh` or `installers/linux/install.sh`.

Both Linux paths run `~/.claude/bootstrap.sh`.

- `installers/nosudo/` is independent of `installers/linux/`. It is user-space only, with one idempotent `install_<tool>.sh` per tool. It pins btop v1.3.2 (the last C++20 release with GPU support) and builds nvtop NVIDIA-only, to avoid the libdrm dev packages.
- The dispatcher does **not** pass `--host` through (`lnk init` has no `--host`), so on a nosudo box run `lnk pull --host nosudo` once after init.
