#!/usr/bin/env zsh

export SHELL="/bin/zsh"
export ZDOTDIR="$HOME/.config/zsh"

### locale (LC_* inherits from LANG when unset)
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"

##### PATH #####

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
