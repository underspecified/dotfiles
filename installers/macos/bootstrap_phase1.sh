#!/usr/bin/env bash
# Usage: bash bootstrap_macos_phase1.sh
#
# Phase 1 of a fresh-Mac bootstrap. Brings the machine from zero up to
# the point where 1Password is installed and the user can sign in and
# enable the SSH agent. After signing in, run phase 2.
#
# Self-contained: safe to curl | bash on a machine that has no git, no
# Homebrew, and no dotfiles repo.
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

ensure_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "phase 1 is macOS-only"
}

ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
    return
  fi
  log "Installing Xcode Command Line Tools (GUI prompt will appear)"
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
    warn "waiting for Xcode CLT install to finish..."
  done
  log "Xcode CLT installed"
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew already installed"
    return
  fi
  log "Installing Homebrew"
  export NONINTERACTIVE=1
  /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

activate_brew_shellenv() {
  local brew_bin
  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin=/usr/local/bin/brew
  else
    die "brew binary not found after install"
  fi
  eval "$("${brew_bin}" shellenv)"
}

install_1password() {
  if [[ -d "/Applications/1Password.app" ]]; then
    log "1Password already installed"
  else
    log "Installing 1Password (cask)"
    brew install --cask 1password
  fi
  if brew list 1password-cli >/dev/null 2>&1; then
    log "1Password CLI already installed"
  else
    log "Installing 1Password CLI"
    brew install 1password-cli
  fi
}

install_lnk() {
  if command -v lnk >/dev/null 2>&1; then
    log "lnk already installed"
  else
    log "Installing lnk"
    brew install lnk
  fi
}

open_1password() {
  log "Opening 1Password — sign in and enable the SSH agent"
  open -a "1Password" || true
}

print_next_steps() {
  cat <<'EOF'

  ──────────────────────────────────────────────────────────────
  Phase 1 complete.

  Now, in 1Password:
    1. Sign in to your account.
    2. Settings → Developer → "Use the SSH agent"
       (and "Integrate with 1Password CLI" if you want `op` commands).
    3. Settings → Developer → Git commit signing (if you sign commits).
    4. Make sure your SSH key item exists in the vault.

  Verify the SSH agent is live:
      ssh-add -l

  Then clone the dotfiles — lnk will auto-run bootstrap.sh, which
  dispatches to phase 2 on macOS:
      lnk init -r git@github.com:<you>/lnk.git
  ──────────────────────────────────────────────────────────────
EOF
}

main() {
  ensure_macos
  ensure_xcode_clt
  ensure_homebrew
  activate_brew_shellenv
  install_1password
  install_lnk
  open_1password
  print_next_steps
}

main "$@"
