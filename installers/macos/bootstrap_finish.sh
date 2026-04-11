#!/usr/bin/env bash
# Usage: bash bootstrap_macos_phase2.sh
#
# Phase 2 of a fresh-Mac bootstrap. Assumes phase 1 has already run
# (Xcode CLT, Homebrew, 1Password signed in with SSH agent enabled,
# lnk installed) and this repo is cloned at ~/.config/lnk with symlinks
# already restored by `lnk init -r`.
#
# Auto-invoked by repo-root bootstrap.sh when run on macOS.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/.config/lnk}"
BREWFILE="${REPO_DIR}/Brewfile"
ALL_DIR="${REPO_DIR}/installers/all"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

check_preconditions() {
  [[ "$(uname -s)" == "Darwin" ]] || die "phase 2 is macOS-only"
  command -v brew >/dev/null 2>&1 || die "Homebrew not found — run phase 1 first"
  command -v lnk >/dev/null 2>&1 || die "lnk not found — run phase 1 first"
  [[ -d "${REPO_DIR}" ]] || die "repo not found at ${REPO_DIR}"
  [[ -f "${BREWFILE}" ]] || die "Brewfile not found at ${BREWFILE}"
  if ! ssh-add -l >/dev/null 2>&1; then
    warn "ssh-add -l returned no keys — 1Password SSH agent may not be active"
    warn "continuing, but git pushes and private clones may fail"
  fi
}

install_brewfile() {
  log "Installing packages from Brewfile (this takes a while)"
  brew bundle --file="${BREWFILE}" --no-lock
}

run_all_installers() {
  log "Running cross-platform installers from ${ALL_DIR}"
  local script
  for script in \
    "${ALL_DIR}/install_claude_code.sh" \
    "${ALL_DIR}/install_btop.sh"; do
    if [[ -x "${script}" ]]; then
      log "  $(basename "${script}")"
      bash "${script}" || warn "failed: $(basename "${script}")"
    else
      warn "skipping: ${script} (missing or not executable)"
    fi
  done
}

start_services() {
  log "Starting background services"
  local svc
  for svc in yabai skhd borders darkman; do
    if brew list "${svc}" >/dev/null 2>&1; then
      log "  brew services start ${svc}"
      brew services start "${svc}" || warn "failed to start ${svc}"
    fi
  done
}

print_manual_checklist() {
  cat <<'EOF'

  ──────────────────────────────────────────────────────────────
  Phase 2 complete. Remaining manual steps:

  System Settings → Privacy & Security:
    • Accessibility:       yabai, skhd, Karabiner-Elements, Alfred/BTT
    • Input Monitoring:    skhd, Karabiner-Elements
    • Screen Recording:    yabai (for window borders), kitty (if sharing)
    • Automation:          yabai, skhd (allow control of System Events)

  yabai scripting addition (if using yabai's SA features):
    sudo yabai --install-sa
    sudo yabai --load-sa

  Karabiner-Elements:
    Approve the virtual HID driver extension in
      System Settings → Privacy & Security → allow driver from "Fumihiko Takayama"
    then reboot if prompted.

  Login Items (System Settings → General → Login Items):
    Add: 1Password, Alfred/Raycast, Karabiner-Elements, darkman

  Shell:
    chsh -s $(brew --prefix)/bin/zsh
    Confirm $ZDOTDIR points to ~/.config/zsh

  Fonts:
    Verify iMWriting* Nerd Fonts rendered in kitty + i3lock.

  Verify:
    lnk status          # symlinks healthy?
    lnk doctor          # any broken links?
    brew bundle check --file=~/.config/lnk/Brewfile
  ──────────────────────────────────────────────────────────────
EOF
}

main() {
  check_preconditions
  install_brewfile
  run_all_installers
  start_services
  print_manual_checklist
}

main "$@"
