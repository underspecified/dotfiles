#!/usr/bin/env zsh

##### ZSH CONFIGURATIONS #####

SCREEN_NAME=`echo $STY | awk -F. '{ print $NF }'`
PROMPT="%B%n%b@%B%m%b:%~ [%B${SCREEN_NAME}%b] [%*] [%!]
%(0?.:%).:() "

HISTFILE=$HOME/.zsh_history
HISTSIZE=2000
SAVEHIST=20000

# setopt ALL_EXPORT
# setopt AUTO_LIST
# setopt AUTO_MENU
# setopt CORRECT_ALL
# setopt HASH_CMDS
# setopt HASH_DIRS
# setopt HIST_IGNORE_ALL_DUPS
# setopt HIST_REDUCE_BLANKS
# setopt HIST_SAVE_NO_DUPS
# setopt INC_APPEND_HISTORY
# setopt PRINT_EIGHT_BIT
# setopt SHARE_HISTORY

# # autocomplete
# autoload -U compinit && compinit

# xprof() {
#     JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS -Xprof" $@
# }

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
