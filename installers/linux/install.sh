#!/usr/bin/env bash
# Usage: install.sh
# Bootstraps a fresh Ubuntu desktop into the i3 stack used by this repo,
# and also serves as the update mechanism on re-run: each function is
# idempotent and re-running brings packages, source builds, and cloned
# repos to the latest state.
#
# Auto-invoked by ../bootstrap.sh after `lnk init -r` lays down symlinks.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL_DIR="${CUR_DIR}/../all"

check_preconditions() {
  [[ "$(uname -s)" == "Linux" ]] || die "install.sh is Linux-only"
  command -v apt >/dev/null 2>&1 || die "apt not found — non-Debian/Ubuntu host?"
  command -v lnk >/dev/null 2>&1 || warn "lnk not on PATH — fine for initial bootstrap, but lnk pull / status will be unavailable"
}

### baseline apt deps
# Trimmed:
#   golang  -> installed by install_darkman.sh from source build
#   psensor -> installed by install_profilers.sh
#   emacs, keychain, chrome-gnome-shell -> unused (1Password SSH agent
#     supersedes keychain; no GNOME-Chrome shell extension flow here)
install_apt_baseline() {
  sudo apt update
  sudo apt install -y curl git jq nodejs npm openssh-server shellcheck trash-cli wget xsel zsh
}

install_google_chrome() {
  # Legacy layout used /etc/apt/sources.list.d/google.list (no signed-by) +
  # `apt-key add`. If left in place alongside the new google-chrome.list,
  # apt errors with: "Conflicting values set for option Signed-By regarding
  # source http://dl.google.com/linux/chrome/deb/ stable". Remove the
  # legacy list file; the leftover apt-key entry in /etc/apt/trusted.gpg.d/
  # is unused but harmless and we leave it alone.
  if [[ -f /etc/apt/sources.list.d/google.list ]]; then
    log "removing legacy /etc/apt/sources.list.d/google.list (replaced by google-chrome.list)"
    sudo rm /etc/apt/sources.list.d/google.list
  fi

  apt_ensure_repo \
    /etc/apt/sources.list.d/google-chrome.list \
    "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    https://dl.google.com/linux/linux_signing_key.pub \
    /etc/apt/keyrings/google-chrome.gpg
  sudo apt update
  sudo apt install -y google-chrome-stable
}

install_gh() {
  type -p wget >/dev/null || sudo apt install -y wget
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
}

install_zed() {
  curl -f https://zed.dev/install.sh | sh
}

update_git() {
  # git-core/ppa add itself is idempotent for the source line but still
  # triggers a full `apt update` every run. Guard so the refresh only
  # happens the first time the PPA is needed.
  if apt-cache policy git 2>/dev/null | grep -q git-core/ppa; then
    log "git-core PPA already configured; skipping repo refresh"
  else
    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt update
  fi
  sudo apt install -y git
}

update_less() {
  if command -v less >/dev/null 2>&1 && less --version 2>/dev/null | head -1 | grep -q ' 668'; then
    log "less 668 already installed; skipping rebuild"
    return 0
  fi
  local workdir
  workdir="$(mktemp -d)"
  trap 'rm -rf "${workdir}"' RETURN
  curl -fL https://www.greenwoodsoftware.com/less/less-668.tar.gz \
    | tar -xzf - -C "${workdir}"
  (cd "${workdir}/less-668" && ./configure --prefix="${HOME}/.local" && make install)
}

run_platform_installers() {
  log "Running Linux-specific installers"
  local script
  for script in \
    "${CUR_DIR}/install_uv.sh" \
    "${CUR_DIR}/install_fonts.sh" \
    "${CUR_DIR}/install_1password.sh" \
    "${CUR_DIR}/install_darkman.sh" \
    "${CUR_DIR}/install_i3.sh" \
    "${CUR_DIR}/install_kitty.sh" \
    "${CUR_DIR}/install_nvidia_drivers.sh" \
    "${CUR_DIR}/install_profilers.sh" \
    "${CUR_DIR}/install_usb_autosuspend.sh"; do
    if [[ -f "${script}" ]]; then
      log "  $(basename "${script}")"
      bash "${script}" || warn "failed: $(basename "${script}")"
    else
      warn "skipping: ${script} (missing)"
    fi
  done
}

run_all_installers() {
  log "Running cross-platform installers from ${ALL_DIR}"
  local script
  for script in \
    "${ALL_DIR}/install_claude_code.sh" \
    "${ALL_DIR}/install_btop.sh"; do
    if [[ -f "${script}" ]]; then
      log "  $(basename "${script}")"
      bash "${script}" || warn "failed: $(basename "${script}")"
    else
      warn "skipping: ${script} (missing)"
    fi
  done
}

run_claude_bootstrap() {
  # ~/.claude/bootstrap.sh chains the per-area scripts (statusline, skills,
  # MCP, patches). Safe to re-run -- each child handles missing-vs-existing
  # state on its own (clone-or-pull, register-if-not-registered, etc.).
  local script="${HOME}/.claude/bootstrap.sh"
  if [[ ! -e "${script}" ]]; then
    warn "skipping Claude bootstrap: ${script} not found (lnk symlinks restored?)"
    return
  fi
  log "Running Claude bootstrap (statusline, skills, MCP, patches)"
  bash "${script}" || warn "Claude bootstrap had failures (continuing)"
}

main() {
  check_preconditions
  install_apt_baseline
  install_gh
  install_google_chrome
  install_zed
  update_git
  update_less
  run_platform_installers
  run_all_installers
  run_claude_bootstrap
  # Final step: select display profile and generate i3/dunst/Xresources/kitty
  # configs. Non-interactive on re-run (skip if already linked).
  bash "${CUR_DIR}/setup_display.sh" "${DISPLAY_PROFILE:-}"
}

main "$@"
