#!/usr/bin/env zsh

export SHELL="/bin/zsh"
export ZDOTDIR="$HOME/.config/zsh"

### locale (LC_* inherits from LANG when unset)
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"

### truecolor
# Advertise 24-bit color so TUIs -- notably Claude Code themes + statusbars --
# render their palette in truecolor instead of snapping to the nearest 256-color.
# Set in .zshenv (not .zshrc) so it survives NON-login / non-interactive launches:
# `ssh host tmux`, one-shot inline commands, and the dispatch headless wake path,
# not just interactive login shells. ssh forwards TERM but not COLORTERM, and an
# inline command skips the login rc -- so without this the remote falls back to
# 256-color. `:-` keeps a value the terminal already set (e.g. kitty's own).
export COLORTERM="${COLORTERM:-truecolor}"

##### PATH #####

# Keep PATH/MANPATH/fpath free of duplicates no matter how many times this file
# is sourced (nested zsh, re-exec, etc.). typeset -U makes the array maintain
# uniqueness, deduping existing entries and any added below.
typeset -U path PATH manpath MANPATH fpath

# local bin and manpath
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export MANPATH=/usr/local/man:/usr/local/share/man:$MANPATH

### user bin and manpath
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/sbin:$PATH"
export MANPATH="$HOME/share/man:$MANPATH"

### user's local bin and manpath
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/sbin:$PATH"
export MANPATH="$HOME/.local/man:$HOME/.local/share/man:$MANPATH"

### SSH agent socket
# macOS: ~/.ssh/config.d/agent.conf declares `IdentityAgent "<GC path>"`;
# mirror it into SSH_AUTH_SOCK so ssh-add / ssh -A see the same 1Password
# agent. Linux: agent.conf has no IdentityAgent, so this block is a no-op
# and zshrc.linux sets SSH_AUTH_SOCK via keychain instead.
_agent_path="$(sed -n 's/^[[:space:]]*IdentityAgent[[:space:]]*"\([^"]*\)".*/\1/p' ~/.ssh/config.d/agent.conf 2>/dev/null | head -1)"
if [ -n "$_agent_path" ]; then
    _agent_path="${_agent_path/#\~/$HOME}"
    [ -S "$_agent_path" ] && export SSH_AUTH_SOCK="$_agent_path"
fi
unset _agent_path

##### DISPATCH #####

# Default the interactive remote `wake` spawn to mosh — drop-proof over laptop
# sleep / Wi-Fi roam / TCP reset (UDP transport with client-side state). Auto
# falls back to `ssh -t` when mosh (local) or mosh-server (remote) is absent, so
# a non-mosh box is never broken. Force-off a host with DISPATCH_REMOTE_MOSH_<HOST>=0.
export DISPATCH_REMOTE_MOSH=1

##### ALIASES #####

# Sourced here (not .zshrc) so aliases are available non-interactively too —
# e.g. `ssh host '<alias>'`. See aliases.zsh for the rationale.
[ -f "$ZDOTDIR/aliases.zsh" ] && . "$ZDOTDIR/aliases.zsh"
