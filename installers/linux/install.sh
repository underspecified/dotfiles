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

migrate_legacy_apt_state() {
  # Earlier iterations of this script managed the google-chrome apt source
  # two different (broken) ways:
  #   1. /etc/apt/sources.list.d/google.list, no signed-by (used apt-key add)
  #   2. /etc/apt/sources.list.d/google-chrome.list, signed-by=keyrings/...
  # Neither plays well with google-chrome-stable's own postinst + daily cron
  # (/etc/cron.daily/google-chrome → /opt/google/chrome/cron/google-chrome),
  # which writes /etc/apt/sources.list.d/google-chrome.list WITHOUT signed-by
  # and overwrites manual edits. The two formats together trigger:
  #   E: Conflicting values set for option Signed-By regarding source
  #      http://dl.google.com/linux/chrome/deb/ stable
  #
  # Fix: stop managing the chrome apt source ourselves. install_google_chrome
  # below installs from the .deb directly and lets chrome's postinst own the
  # source line. This function purges our leftover artifacts BEFORE any
  # `apt update` runs (including the one inside install_apt_baseline), so the
  # bootstrap can succeed on hosts that hit the broken interim state.
  local stale
  for stale in \
      /etc/apt/sources.list.d/google.list \
      /etc/apt/keyrings/google-chrome.gpg; do
    if [[ -e "${stale}" ]]; then
      log "removing pre-refactor apt artifact: ${stale}"
      sudo rm -f "${stale}"
    fi
  done

  # google-chrome.list may legitimately exist (chrome's postinst wrote it) or
  # may be the half-refactored signed-by version that conflicts. Remove only
  # if it contains our signed-by line; chrome's cron will recreate it
  # in the correct format if google-chrome-stable is installed.
  local list=/etc/apt/sources.list.d/google-chrome.list
  if [[ -f "${list}" ]] && grep -qF "signed-by=/etc/apt/keyrings/google-chrome.gpg" "${list}"; then
    log "removing half-refactored ${list} (chrome cron will recreate)"
    sudo rm -f "${list}"
  fi
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
  # Install from the upstream .deb and let chrome's postinst configure the
  # apt source itself (it owns /etc/apt/sources.list.d/google-chrome.list and
  # refreshes it via /etc/cron.daily/google-chrome). Fighting that with our
  # own keyring-managed source caused apt "Conflicting values set for option
  # Signed-By" errors; see migrate_legacy_apt_state above.
  if dpkg -s google-chrome-stable >/dev/null 2>&1; then
    log "google-chrome-stable already installed"
    return 0
  fi
  local deb
  deb="$(mktemp --suffix=.deb)"
  trap 'rm -f "${deb}"' RETURN
  log "downloading google-chrome-stable .deb"
  wget -qO "${deb}" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y "${deb}"
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
  migrate_legacy_apt_state
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
