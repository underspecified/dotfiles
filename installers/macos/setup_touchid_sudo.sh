#!/usr/bin/env bash
# Usage: bash setup_touchid_sudo.sh
#
# Enables TouchID for sudo — including inside tmux / non-TTY sessions, which is
# what /good-morning needs when it arms good-night (sudo pmset). Installs
# pam_reattach (Homebrew) and writes /etc/pam.d/sudo_local with pam_reattach
# ABOVE pam_tid. Idempotent — re-running is a no-op once configured.
#
# pam_reattach MUST precede pam_tid: it reattaches the auth to the GUI login
# session so the TouchID prompt can appear from a detached/tmux shell. Without
# it, TouchID only works from a foreground Terminal.
#
# Writes the pam file from a temp file via `sudo cp` (never `printf | tee` —
# that mangled the file once and broke sudo). sudo here is interactive.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

sudo_local="/etc/pam.d/sudo_local"
reattach_so=""

check_preconditions() {
  [[ "$(uname -s)" == "Darwin" ]] || die "TouchID-for-sudo setup is macOS-only"
  command -v brew >/dev/null 2>&1 || die "Homebrew required — install it first"
}

ensure_pam_reattach() {
  local prefix
  prefix="$(brew --prefix)"
  reattach_so="${prefix}/lib/pam/pam_reattach.so"
  if [[ ! -f "${reattach_so}" ]]; then
    log "installing pam-reattach"
    brew install pam-reattach
  fi
  [[ -f "${reattach_so}" ]] || die "pam_reattach.so missing at ${reattach_so} after install"
}

write_sudo_local() {
  local tmp
  tmp="$(mktemp)"
  cat > "${tmp}" <<EOF
auth optional ${reattach_so}
auth sufficient pam_tid.so
EOF
  if [[ -f "${sudo_local}" ]] && cmp -s "${tmp}" "${sudo_local}"; then
    log "${sudo_local} already configured — skipping"
    rm -f "${tmp}"
    return
  fi
  log "writing ${sudo_local} (needs sudo)"
  sudo cp "${tmp}" "${sudo_local}"
  sudo chown root:wheel "${sudo_local}"
  sudo chmod 644 "${sudo_local}"
  rm -f "${tmp}"
  log "TouchID for sudo enabled (pam_reattach + pam_tid)"
}

main() {
  check_preconditions
  ensure_pam_reattach
  write_sudo_local
}

main "$@"
