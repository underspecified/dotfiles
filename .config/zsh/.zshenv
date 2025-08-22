#!/usr/bin/env zsh

export SHELL="/bin/zsh"
export ZDOTDIR="$HOME/.config/zsh"

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

### locale
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_ADDRESS="en_US.UTF-8"
#export LC_ALL="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_IDENTIFICATION="en_US.UTF-8"
export LC_MEASUREMENT="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_NAME="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"
export LC_PAPER="en_US.UTF-8"
export LC_TELEPHONE="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"

# local bin and manpath
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export MANPATH=/usr/local/man:/usr/local/share/man:$MANPATH

### Haskell cabal
export PATH="$HOME/.cabal/bin:$PATH"
export MANPATH="$HOME/.cabal/share/man:$MANPATH"

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

# OpenAI
export OPENAI_API_KEY=REDACTED

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
