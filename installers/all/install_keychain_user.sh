#!/usr/bin/env bash
# Usage: install_keychain_user.sh
#
# No-sudo install of `keychain` into ~/.local/bin. keychain is a single
# POSIX-sh script (no compile step), so a user-space install just means
# fetching one file from a pinned upstream tag. ~/.local/bin is already
# at the head of PATH via .zshenv, so the user-space copy wins over any
# /usr/bin/keychain that may exist.
#
# This script is platform-neutral but exists for Linux boxes where sudo
# is not available (so `installers/linux/install.sh` can't apt-install
# keychain). macOS users don't need this — they keep using the 1Password
# SSH agent. Invoke manually; not wired into install.sh.
#
# Env overrides:
#   KEYCHAIN_VERSION  -- upstream tag (default: 2.8.5)
#   KEYCHAIN_SHA256   -- expected sha256 of the keychain script; if empty
#                        the integrity check is skipped (and a warning is
#                        printed). To pin: run this script once, then
#                        `sha256sum ~/.local/bin/keychain` and paste the
#                        hash into this file's default below.
#   PREFIX            -- install prefix (default: $HOME/.local)
set -uo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

KEYCHAIN_VERSION="${KEYCHAIN_VERSION:-2.8.5}"
KEYCHAIN_SHA256="${KEYCHAIN_SHA256:-}"
PREFIX="${PREFIX:-$HOME/.local}"

KEYCHAIN_URL="https://raw.githubusercontent.com/funtoo/keychain/${KEYCHAIN_VERSION}/keychain"
DEST="${PREFIX}/bin/keychain"

already_installed() {
  # Idempotent: skip the download if the target exists and reports the
  # pinned version. `keychain --version` writes the version line to
  # stderr; grep both streams.
  [[ -x "${DEST}" ]] || return 1
  "${DEST}" --version 2>&1 | grep -qF "keychain ${KEYCHAIN_VERSION}"
}

verify_sha() {
  local file="$1"
  if [[ -z "${KEYCHAIN_SHA256}" ]]; then
    warn "KEYCHAIN_SHA256 not set; skipping integrity check for ${file}"
    warn "to pin: sha256sum ${file}  -> KEYCHAIN_SHA256 default in this script"
    return 0
  fi
  local got
  got="$(sha256sum "${file}" | awk '{print $1}')"
  if [[ "${got}" != "${KEYCHAIN_SHA256}" ]]; then
    die "sha256 mismatch for ${file}: got ${got}, expected ${KEYCHAIN_SHA256}"
  fi
  log "sha256 verified: ${got}"
}

main() {
  command -v curl >/dev/null 2>&1 || die "curl is required"
  command -v sha256sum >/dev/null 2>&1 || warn "sha256sum not on PATH; integrity check unavailable"

  if already_installed; then
    log "keychain ${KEYCHAIN_VERSION} already at ${DEST}, skipping"
    return 0
  fi

  mkdir -p "${PREFIX}/bin"
  local tmp
  tmp="$(mktemp)"
  # shellcheck disable=SC2064  # expand $tmp now, not on signal
  trap "rm -f '${tmp}'" EXIT

  log "downloading keychain ${KEYCHAIN_VERSION} from ${KEYCHAIN_URL}"
  if ! curl -fsSL "${KEYCHAIN_URL}" -o "${tmp}"; then
    die "download failed: ${KEYCHAIN_URL}"
  fi

  verify_sha "${tmp}"
  install -m 755 "${tmp}" "${DEST}"
  log "installed: ${DEST}"

  # Confirm what's on PATH points where we expect.
  hash -r 2>/dev/null || true
  local resolved
  resolved="$(command -v keychain || true)"
  if [[ "${resolved}" != "${DEST}" ]]; then
    warn "command -v keychain resolves to ${resolved:-<nothing>} (expected ${DEST})"
    warn "  ensure ${PREFIX}/bin is at the head of PATH (it is by default via .zshenv)"
  fi
}

main "$@"
