# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
- Git commits are GPG-signed via 1Password SSH agent (`op-ssh-sign`)
- Git auth standardizes on SSH (no HTTPS credential helper) — the 1Password SSH agent handles all git auth
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
