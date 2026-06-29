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
setopt EXTENDED_GLOB
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INTERACTIVE_COMMENTS
setopt SHARE_HISTORY

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
# Interactive-/kitty-gated alias stays here (kitten is not present on headless
# boxes and `ssh` inside scripts must remain the real binary). Portable aliases
# live in $ZDOTDIR/aliases.zsh, sourced from .zshenv (non-interactive too).
if [[ -v KITTY_PID && ! -v ZED_TERM ]]; then
    export TERM="xterm-kitty"
    alias ssh="kitten ssh"
else
    export TERM="xterm-color"
fi

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

##### LOCAL OVERRIDES #####

# dispatch env (machine-local, untracked, chmod-600 for token-bearing files).
# Glob-source ALL of ~/.config/dispatch/*.env so one line covers every host +
# both sender files (dgx02.env: AGENT_MAIL_URL_<HOST>+token) and a box's own
# local.env (AGENT_MAIL_URL for its non-default bus port). Cross-platform —
# replaces the old linux-only, dgx02.env-specific line in zshrc.linux.
for _f in ~/.config/dispatch/*.env(N); do source "$_f"; done
unset _f

# Host-local zsh overrides (untracked $ZDOTDIR/zshrc.local). General escape
# hatch, sourced last so it wins over zshrc.{osx,linux,*}. Currently unused —
# dgx02's AGENT_MAIL_URL moved to ~/.config/dispatch/local.env (glob-sourced
# above); kept for any future genuine per-host shell override.
if [ -f "$ZDOTDIR/zshrc.local" ]; then
    . "$ZDOTDIR/zshrc.local"
fi

# Mirror the fully-assembled PATH to a kitty include (single source of truth =
# this shell's PATH). GUI-launched kitty inherits the minimal launchd PATH, so
# `kitten @ launch <cmd>` — which bypasses the shell — can't find Homebrew tools
# like mosh (dispatch's interactive spawn + the btop/nvtop launchers need it).
# kitty.conf does `globinclude env.conf`; reload picks it up. Runs last, after
# every PATH mutation above. PATH rarely changes, so the file stays current
# between sessions even though this only fires on interactive shells.
if [ -d "$HOME/.config/kitty" ]; then
    print -r -- "env PATH=$PATH" >| "$HOME/.config/kitty/env.conf" 2>/dev/null
fi
