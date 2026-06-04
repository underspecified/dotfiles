#!/usr/bin/env bash
# Usage: install_autossh.sh
#
# Build autossh from the upstream tarball into ~/.local/bin for the
# no-sudo / headless path. autossh keeps the dgx02→fleet dispatch relay
# tunnel alive (per-host LocalForwards through llm-jp; see
# docs/dispatch-dgx02-relay.md + nosudo.lnk/.config/systemd/user/
# dispatch-tunnel.service).
#
# autossh is a tiny C program (one .c + helper); `./configure && make`
# with the gcc that nosudo hosts already have. Verified at design time:
# dgx02 has make/gcc and reaches www.harding.motd.ca:443, so the upstream
# fetch + local build works without a fallback.
#
# Fallback (documented, manual): if the upstream host is ever unreachable
# from a box, build on llm-jp (has internet, same arch) and
#   scp llm-jp:~/.local/bin/autossh dgx02:~/.local/bin/
# over the already-working ssh hop.
#
# Idempotent: skips the build if ~/.local/bin/autossh already reports the
# pinned version.
#
# Env overrides:
#   AUTOSSH_VERSION  -- upstream release (default: 1.4g)
#   AUTOSSH_SHA256   -- expected sha256 of the tarball; empty = skip the
#                       integrity check (with a warning)
#   PREFIX           -- install prefix (default: $HOME/.local)
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

AUTOSSH_VERSION="${AUTOSSH_VERSION:-1.4g}"
AUTOSSH_SHA256="${AUTOSSH_SHA256:-5fc3cee3361ca1615af862364c480593171d0c54ec156de79fc421e31ae21277}"
PREFIX="${PREFIX:-${HOME}/.local}"

URL="https://www.harding.motd.ca/autossh/autossh-${AUTOSSH_VERSION}.tgz"
DEST="${PREFIX}/bin/autossh"

already_installed() {
  [[ -x "${DEST}" ]] || return 1
  # autossh prints "autossh <version>" to stderr on -V (and exits non-zero).
  "${DEST}" -V 2>&1 | grep -qF "autossh ${AUTOSSH_VERSION}"
}

verify_sha() {
  local file="$1"
  if [[ -z "${AUTOSSH_SHA256}" ]]; then
    warn "AUTOSSH_SHA256 unset; skipping integrity check for ${file}"
    return 0
  fi
  command -v sha256sum >/dev/null 2>&1 || { warn "sha256sum absent; skipping check"; return 0; }
  local got
  got="$(sha256sum "${file}" | awk '{print $1}')"
  [[ "${got}" == "${AUTOSSH_SHA256}" ]] \
    || die "sha256 mismatch for ${file}: got ${got}, expected ${AUTOSSH_SHA256}"
  log "sha256 verified: ${got}"
}

main() {
  command -v make >/dev/null 2>&1 || die "make is required"
  command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 \
    || die "a C compiler (cc/gcc) is required"
  command -v curl >/dev/null 2>&1 || die "curl is required"

  if already_installed; then
    log "autossh ${AUTOSSH_VERSION} already at ${DEST}, skipping"
    return 0
  fi

  mkdir -p "${PREFIX}/bin"
  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064  # expand $tmp now, not on signal
  trap "rm -rf '${tmp}'" EXIT

  log "downloading autossh ${AUTOSSH_VERSION} from ${URL}"
  curl -fsSL "${URL}" -o "${tmp}/autossh.tgz" || die "download failed: ${URL}"
  verify_sha "${tmp}/autossh.tgz"

  tar -xzf "${tmp}/autossh.tgz" -C "${tmp}"
  local src="${tmp}/autossh-${AUTOSSH_VERSION}"
  [[ -d "${src}" ]] || die "unexpected tarball layout (no ${src})"

  log "building autossh (./configure && make)"
  ( cd "${src}" && ./configure --prefix="${PREFIX}" >/dev/null && make >/dev/null )

  install -m 755 "${src}/autossh" "${DEST}"
  log "installed: ${DEST} ($("${DEST}" -V 2>&1 | head -1))"
}

main "$@"
