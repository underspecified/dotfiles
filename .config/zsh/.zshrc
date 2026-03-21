#!/usr/bin/env zsh

##### ENVIRONMENT SETUP #####

if [ $(uname) = Darwin ] && [ -f "$ZDOTDIR/zshrc.osx" ]; then
    . "$ZDOTDIR/zshrc.osx"
elif [ $(uname) = Linux ] && [ -f "$ZDOTDIR/zshrc.linux" ]; then
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

# 1password
if [[ -d "/Applications/1Password.app" ]]; then
    export OP_DIR="/Applications/1Password.app/Contents/MacOS/"
elif [[ -d "/opt/1Password" ]]; then
    export OP_DIR="/opt/1Password"
fi
[[ -f $HOME/.config/op/plugins.sh ]] && source $HOME/.config/op/plugins.sh
[[ -S ~/.1password/agent.sock ]] && export SSH_AUTH_SOCK=~/.1password/agent.sock
export PATH="$OP_DIR:$PATH"

##### ZSH CONFIGURATIONS #####

setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt EXTENDED_GLOB
setopt HIST_REDUCE_BLANKS

SCREEN_NAME=$(echo $STY | awk -F. '{ print $NF }')
PROMPT="%B%n%b@%B%m%b:%~ [%B${SCREEN_NAME}%b] [%*] [%!]
%(0?.:%).:() "

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

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

# color programs
alias grep="grep --color=auto"
alias diff="diff --color=auto"

##### COMPLETIONS #####

# Docker CLI completions
fpath=("$HOME/.docker/completions" $fpath)

# Single compinit with cache (-C skips compaudit security scan)
autoload -Uz compinit
if [[ -n $ZDOTDIR/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
