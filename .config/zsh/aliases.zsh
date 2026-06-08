#!/usr/bin/env zsh
# Shell aliases, sourced from .zshenv so they are available NON-INTERACTIVELY
# too (e.g. `ssh host '<alias>'`, which runs `zsh -c`). zsh — unlike bash —
# expands aliases in non-interactive shells as long as they are defined before
# the command is parsed, so defining them here (read before any command) works.
#
# OS detection uses $OSTYPE (a zsh builtin) rather than `uname` to avoid forking
# a subprocess on every shell + script invocation.
#
# Terminal-/session-gated aliases (e.g. ssh="kitten ssh", which needs KITTY_PID)
# stay in .zshrc — they are interactive-only by design.

# Cross-platform. --color=auto / BSD -G only colorize a tty, so these stay safe
# inside pipes and scripts.
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias nvtop="TERM=xterm-color nvtop"

case "$OSTYPE" in
darwin*)
    alias ls="ls -G"
    alias emacs="TERM=xterm-color /opt/homebrew/bin/emacs -nw"
    alias zcat="gzcat"
    alias safari="open -a /Applications/Safari.app"
    alias fixopenwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user'
    ;;
linux*)
    alias ls="ls --color=auto"
    alias emacs="TERM=xterm-color emacs -nw"
    alias pbcopy='xsel --clipboard --input'
    alias pbpaste='xsel --clipboard --output'
    alias pbclear='xsel --clipboard --clear'
    alias open='gio open'
    ;;
esac
