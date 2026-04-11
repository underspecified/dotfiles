# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A dotfiles repository managed by [`lnk`](https://github.com/...), a Git-native dotfiles manager. Files live here in `~/.config/lnk/` and are symlinked back to `$HOME`. The `lnk` CLI handles add/remove/sync operations.

## Three-Tier Manifest System

- **`.lnk`** — cross-platform configs (zsh, kitty, git, ssh, docker, obsidian, etc.)
- **`.lnk.macos`** — macOS-only (yabai, skhd, aerospace, karabiner, borders, darkman, helper scripts in `.local/bin/`)
- **`.lnk.linux`** — Linux-only (i3, sway, rofi, tofi, X11/Wayland configs, systemd user units, wallpapers)

Each file lists paths relative to `$HOME`, one per line. `lnk` reads these to know what to symlink.

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
| `installers/` | Setup scripts organized as `all/` (cross-platform), `linux/`, `macos/` (mac bootstrap is `macos/bootstrap_phase1.sh` + `bootstrap_phase2.sh`, auto-run via `bootstrap.sh` dispatcher at repo root) |
| `.gnupg/`, `.ssh/` | Key material (sensitive — managed but gitignored selectively) |

## Key Conventions

- Commits follow `lnk: description` or `component: description` format (e.g., `kitty: change font`, `macos: darkmode fixes`)
- Git commits are GPG-signed via 1Password SSH agent (`op-ssh-sign`)
- Git auth standardizes on SSH (no HTTPS credential helper) — the 1Password SSH agent handles all git auth
- The legacy `setup.sh` is an older symlink installer; prefer `lnk` commands instead

## Platform-Specific Notes

**macOS window management stack:** yabai (tiling WM) + skhd (hotkey daemon) + borders (window borders) + darkman (dark/light mode switching). Helper scripts in `macos.lnk/.local/bin/` handle toggling apps, theme changes, and border styling.

**Linux window management:** i3 (X11) or sway (Wayland), with rofi/tofi launchers, darkman for theme switching, and systemd user services.

**Shell:** zsh with `ZDOTDIR=~/.config/zsh`. Platform-specific config sourced conditionally from `zshrc.osx`, `zshrc.linux`, `zshrc.x11`, `zshrc.wayland`, `zshrc.ros`.
