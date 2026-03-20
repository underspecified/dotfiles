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
