# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
# Shell Options
setopt nohashdirs
setopt login
# Aliases
alias -- diff='diff --color=auto'
alias -- grep='grep --color=auto'
alias -- ls='ls --color=auto'
alias -- run-help=man
alias -- ssh='kitten ssh'
alias -- which-command=whence
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg='/opt/homebrew/lib/node_modules/\@anthropic-ai/claude-code/vendor/ripgrep/arm64-darwin/rg'
fi
export PATH=/Users/eric/.cabal/bin\:/Users/eric/git/dotfiles/bin\:/Users/eric/.local/sbin\:/Users/eric/.local/bin\:/Users/eric/sbin\:/Users/eric/bin\:/Users/eric/git/dotfiles/config/yabai/scripts\:/Users/eric/git/dotfiles/macos/bin\:/opt/homebrew/anaconda3/bin\:/opt/homebrew/anaconda3/condabin\:/opt/homebrew/sbin\:/opt/homebrew/bin\:/Applications/kitty.app/Contents/MacOS\:/usr/bin\:/bin\:/usr/sbin\:/sbin\:/Library/TeX/texbin\:/Users/eric/.cache/lm-studio/bin\:/Users/eric/.cache/lm-studio/bin\:/Users/eric/.cache/lm-studio/bin\:/Users/eric/.cache/lm-studio/bin
