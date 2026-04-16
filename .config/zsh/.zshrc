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

# nvtop
alias nvtop="TERM=xterm-color nvtop"

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

# cargo
test -e "$HOME/.cargo/env" && source "$HOME/.cargo/env"

# bun completions (added to fpath; compinit in .zshrc handles loading)
[[ -d "$HOME/.bun" ]] && fpath=("$HOME/.bun" $fpath)

# LM Studio CLI
export PATH="$PATH:$HOME/.cache/lm-studio/bin"
