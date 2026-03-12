#!/usr/bin/env zsh

##### ENVIRONMENT SETUP #####

if [ `uname` = Darwin ] && [ -f "$ZDOTDIR/zshrc.osx" ]; then
    . "$ZDOTDIR/zshrc.osx"
elif [ `uname` = Linux ] && [ -f "$ZDOTDIR/zshrc.linux" ]; then
    . "$ZDOTDIR/zshrc.linux"
fi

if [ -n "$ROS_VERSION" ] && [ -f "$ZDOTDIR/zshrc.ros" ]; then
    . "$ZDOTDIR/zshrc.ros"
fi

if [ "$XDG_SESSION_TYPE" = x11 ] && [ -f "$ZDOTDIR/zshrc.x11" ]; then
    . "$ZDOTDIR/zshrc.x11"
elif [ "$XDG_SESSION_TYPE" = wayland ] && [ -f "$ZDOTDIR/zshrc.wayland" ]; then
    . "$ZDOTDIR/zshrc.wayland"
fi

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

# 1password
if [[ -d "/Applications/1Password.app" ]]; then
    export OP_DIR="/Applications/1Password.app/Contents/MacOS/"
elif [[ -d "/opt/1Password" ]]; then
    export OP_DIR="/opt/1Password"
fi
[[ -f $HOME/.config/op/plugins.sh ]] && source $HOME/.config/op/plugins.sh
export SSH_AUTH_SOCK=~/.1password/agent.sock
export PATH="$OP_DIR:$PATH"

##### ZSH CONFIGURATIONS #####

SCREEN_NAME=`echo $STY | awk -F. '{ print $NF }'`
PROMPT="%B%n%b@%B%m%b:%~ [%B${SCREEN_NAME}%b] [%*] [%!]
%(0?.:%).:() "

HISTFILE=$HOME/.zsh_history
HISTSIZE=2000
SAVEHIST=20000

### editor settings
export EDITOR="emacs -nw"
export VISUAL="emacs -nw"

### terminal settings
if [[ -v KITTY_PID && ! -v ZED_TERM ]]; then
    export TERM="xterm-kitty"
    alias ssh="kitten ssh"
else
    export TERM="xterm-color"
fi

# Selenized customizations
export LS_COLORS="$LS_COLORS:ow=1;7;34:st=30;44:su=30;41"

# color programs
alias ls="ls --color=auto"
alias grep="grep --color=auto"
alias diff="diff --color=auto"

##### COMPLETIONS #####

# Docker CLI completions
fpath=(/Users/eric/.docker/completions $fpath)

# Single compinit with cache (-C skips compaudit security scan)
autoload -Uz compinit
if [[ -n $ZDOTDIR/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
