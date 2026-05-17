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

### 1Password
# Single source of truth: ~/.ssh/1Password/socket (managed per-OS by lnk)
# declares the agent path via `IdentityAgent "<path>"`. Mirror it into
# SSH_AUTH_SOCK so ssh-add, ssh -A forwarding, and agent-aware tools all
# see the same agent that ssh's IdentityAgent uses for signing.
_op_path="$(sed -n 's/^[[:space:]]*IdentityAgent[[:space:]]*"\([^"]*\)".*/\1/p' ~/.ssh/1Password/socket 2>/dev/null | head -1)"
if [ -n "$_op_path" ]; then
    _op_path="${_op_path/#\~/$HOME}"
    [ -S "$_op_path" ] && export SSH_AUTH_SOCK="$_op_path"
fi
unset _op_path
