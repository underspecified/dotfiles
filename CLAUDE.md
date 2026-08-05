# Settings — System Configuration + Claude Skills

This directory is the home of the `settings` PL. On disk it's `~/.config/lnk/` (an artifact of the dotfiles manager `lnk`), reachable as `~/projects/settings` for dispatch.

## Project Description

System settings, Claude skills, hooks, hookify rules, MCP configs, dotfiles. **Lowest velocity, highest blast radius** — a broken hook can affect every session, so changes are tested cautiously and rolled out deliberately. This is a meta-PL: every other PL depends on the skills + dispatch infrastructure managed here.

## Scope (Eric's slice)

### In scope
- Claude skill definitions (`~/.claude/skills/`)
- Hook + hookify rules (`~/.claude/hookify.*.local.md`, `~/.claude/hooks/`)
- MCP server configs
- Shell / tmux / kitty / zsh dotfiles
- Global Claude `CLAUDE.md` (`~/.claude/CLAUDE.md`)
- Development conventions (`rules/`: python, bash, skill, authoring, safety, email, markdown)
- Setup scripts for new machines

### Out of scope
- Per-project CLAUDE.md (owned by the project PL)
- Per-PL memory dirs (per-session)
- Application-level settings unrelated to dev workflow

## Owns vs Tracks

- **Owns:** `~/.config/lnk/` (linked dotfiles), `~/.claude/skills/` (custom skill definitions), `~/.claude/CLAUDE.md` (global user CLAUDE.md), `~/.claude/rules/` (convention docs), `~/.claude/hooks/` + hookify rules
- **Tracks (not owned):** upstream skill repos (`underspecified/figure`, `underspecified/presentation`, `underspecified/research`, `underspecified/dispatch`, `underspecified/kaiseki`, `underspecified/lab`) — feature requests + bug reports filed there, code lives there

## Goals

- Stable dev environment across machines (Macbook, lab machines)
- Working dispatch, `/good-morning`, `/good-night`, `/kaiseki`, `/hansei`, `/nikki` skills
- Safe defaults (block-rm, block-force-push, warn-destructive-git, AppleScript-send block)
- Memory-system templates and conventions

## Responsibilities

| Person | Role | Settings-specific responsibility |
|--------|------|-----------------------------------|
| Eric Nichols | Sole owner | All of the above. This is a one-person PL by design — settings touches everything Claude does, so single-owner discipline keeps the blast radius manageable. |

## PL Status

**Slug:** `settings`
**Type:** Claude-side coordination seat. Eric is the sole owner; lowest-velocity, highest-blast-radius PL.
**Formalized:** 2026-05-21

## Contracts with other PLs

- → All PLs: provides the skills and dispatch infrastructure everyone uses
- ← All PLs: receive feature requests for new/modified skills (e.g. `lab` files an issue against the dispatch repo)

## Blast-radius caution

Changes here affect every Claude Code session. Default discipline:

- Test new hooks on a single project before global rollout
- Never disable safety rules (`block-rm`, `block-force-push`, AppleScript-send block) without explicit user OK
- When a canonical MCP is missing, ask for `/mcp` reconnect — don't roll AppleScript fallbacks proactively (memory: `feedback_mcp_unavailable_default`)

## Cadence

**Biweekly** digest (admin-tempo). Pulled into `/hansei` retrospectives where relevant.

## Pointers

- Settings repo: `~/.config/lnk/` (managed via `lnk`)
- Global CLAUDE.md: `~/.claude/CLAUDE.md`
- Convention rules: `~/.claude/rules/` (NOT symlinked from `~/.config/lnk/.claude/rules/` — discovered 2026-05-24; they're independent directories)
- Inbox (when polling lands): `~/.claude/inbox/settings.md`
- Registry: `~/projects/CLAUDE.md` (PL table) + `rules/autonomy.md` (workflow + routing)

---

## What This Is

A dotfiles repository managed by [`lnk`](https://github.com/...), a Git-native dotfiles manager. Files live here in `~/.config/lnk/` and are symlinked back to `$HOME`. The `lnk` CLI handles add/remove/sync operations.

## Manifest System

- **`.lnk`** — cross-platform configs (zsh, kitty, git, ssh, docker, obsidian, etc.)
- **`.lnk.macos`** — macOS-only (yabai, skhd, aerospace, karabiner, borders, darkman, helper scripts in `.local/bin/`)
- **`.lnk.linux`** — Linux desktop (i3, sway, rofi, tofi, X11/Wayland configs, systemd user units, wallpapers). Pulled on **any** Linux host — the GUI helpers are dead symlinks but harmless on headless boxes.
- **`.lnk.nosudo`** *(host)* — additional files for headless / no-sudo dev boxes. Layered **on top of** `.lnk` + `.lnk.linux`; lnk has no exclusion mechanism. Pull with `lnk pull --host nosudo`.

Each file lists paths relative to `$HOME`, one per line. `lnk` reads these to know what to symlink. OS files (`.lnk.macos`, `.lnk.linux`) are selected automatically by `uname -s`; host files (`.lnk.<host>`) require the `--host <host>` flag on `lnk pull` / `lnk add` / `lnk list`.

## Common Commands

```bash
lnk status          # Show sync status (like git status for dotfiles)
lnk diff            # Show uncommitted changes
lnk add ~/.foo      # Start managing a file (moves it here, symlinks back)
lnk add --host work ~/.ssh/config  # Host-specific file
lnk rm .foo         # Stop managing a file
lnk push "message"  # Commit and push to remote
lnk pull            # Pull and restore symlinks
lnk list --all      # Show all managed files
lnk doctor          # Diagnose broken symlinks or issues
```

## Directory Layout

| Path | Contents |
|------|----------|
| `.config/` | Cross-platform app configs (zsh, kitty, zed, tmux, obsidian, etc.) |
| `macos.lnk/` | macOS-only configs and scripts (`.config/`, `.local/bin/`, `.Rprofile`) |
| `linux.lnk/` | Linux-only configs and scripts (`.config/`, `.local/`, X11 dotfiles) |
| `.docker/mcp/` | Docker MCP server configuration (markdownify, markitdown) |
| `installers/` | Setup scripts organized as `all/` (cross-platform), `linux/` (desktop with sudo+apt), `nosudo/` (headless / no-sudo: user-space tools only), and `macos/`. Linux desktop entry point is `linux/install.sh`; the nosudo path is `nosudo/install.sh`. Mac bootstrap is `macos/bootstrap_start.sh` for bare-machine bring-up + `macos/bootstrap_finish.sh` auto-run via repo-root `bootstrap.sh` dispatcher after `lnk init -r` |
| `.gnupg/`, `.ssh/` | Key material (sensitive — managed but gitignored selectively) |

## Key Conventions

- Commits follow `lnk: description` or `component: description` format (e.g., `kitty: change font`, `macos: darkmode fixes`)
- Git commits are SSH-signed (`gpg.format = ssh`, `gpg.ssh.program = ssh-keygen`, verified against `~/.config/git/allowed_signers`)
- Git auth prefers SSH; HTTPS is fallback only. **macOS:** 1Password agent (Touch ID) plus an additive passphrase-free `IdentityFile ~/.ssh/hri_jp` — a locked 1Password offers zero identities, so ssh falls through to the key and remote/non-interactive sessions keep working. **Linux/headless:** ssh-agent persisted by keychain (see `installers/linux/ssh_keys.sh`). **HTTPS fallback:** GitHub/gist via `gh auth git-credential`; Overleaf (HTTPS-only, no SSH option) via in-memory `cache`. Never the plaintext `store` helper.
- The legacy `setup.sh` is an older symlink installer; prefer `lnk` commands instead

## Bootstrap Dispatch

Repo-root `bootstrap.sh` is auto-run by `lnk init -r <url>` (and `lnk bootstrap`). It picks one installer per host:

1. **`LNK_HOST` env var** — explicit override. Currently recognizes `nosudo`; unknown values warn and fall through.
2. **Auto-detect on Linux** — when `sudo -n true` fails (no passwordless sudo, or no sudo at all), routes to `installers/nosudo/install.sh`. Override with `LNK_HOST=` (empty) and pre-cached sudo creds to force the standard path.
3. **OS default** — Darwin → `installers/macos/bootstrap_finish.sh`; Linux → `installers/linux/install.sh`.

The two Linux paths differ as follows:

| | `linux/install.sh` | `nosudo/install.sh` |
|---|---|---|
| Requires | apt + sudo | none beyond `git curl wget jq tar` |
| Installs to | system (`/usr`) | user (`~/.local`) |
| GUI stack (i3, kitty, fonts, darkman, 1Password, chrome, zed) | yes | kitty only (user-space curl-pipe), nothing else |
| Hardware (nvidia, usb autosuspend) | yes | no |
| User-space tooling (uv, gh, btop, nvtop, gpu-burn, claude, shellcheck, shfmt, node, trash-cli) | partial (via apt where possible) | yes — each tool gets its own `installers/nosudo/install_<tool>.sh` (prebuilt tarballs + curl-pipe + `uv tool`) |
| Runs `~/.claude/bootstrap.sh` | yes | yes |

`installers/nosudo/` is independent of `installers/linux/` — the nosudo path pins its own btop version (v1.3.2, last C++20 release with GPU support) and builds nvtop with NVIDIA-only backend to avoid the libdrm dev-package dependency. Each per-tool script is idempotent and individually runnable for debugging.

Adding host-specific files: `lnk add --host nosudo <file>` writes to `.lnk.nosudo`. The dispatcher does **not** pass `--host` through (lnk init has no `--host` flag), so on first restore run `lnk pull --host nosudo` manually to layer host files on top.

## Platform-Specific Notes

**macOS window management stack:** yabai (tiling WM) + skhd (hotkey daemon) + borders (window borders) + darkman (dark/light mode switching). Helper scripts in `macos.lnk/.local/bin/` handle toggling apps, theme changes, and border styling.

**Linux window management:** i3 (X11) or sway (Wayland), with rofi/tofi launchers, darkman for theme switching, and systemd user services.

**Shell:** zsh with `ZDOTDIR=~/.config/zsh`. Platform-specific config sourced conditionally from `zshrc.osx`, `zshrc.linux`, `zshrc.x11`, `zshrc.wayland`, `zshrc.ros`.
