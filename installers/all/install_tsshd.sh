#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/installers/all/install_tsshd.sh
#
# Pinned tsshd, the server side of trzsz-ssh (`tssh`), into ~/.local/bin on a
# Linux host. tank reaches the hosts with `tssh <host>` (CLAUDE.md, Gotchas);
# tssh starts one tsshd per session over ssh, so there is no service and no sudo.
# Idempotent: a re-run at the pinned version downloads and writes nothing.
#
# VERSION must work with tank's Homebrew trzsz-ssh. To bump it, take both sums
# from the asset digests of the GitHub release.
#
# Offline host: copy tsshd_<VERSION>_linux_<arch>.tar.gz into ~/.cache/tsshd/
# from a host that has it, then re-run; the sha256 check still applies.
set -uo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

VERSION="0.1.10"
URL="https://github.com/trzsz/tsshd/releases/download"
BIN="${HOME}/.local/bin/tsshd"
CACHE="${HOME}/.cache/tsshd"
work=""
trap '[[ -n "${work}" ]] && rm -rf "${work}"' EXIT

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | awk '{print $1}'
}

is_pinned() { [[ "$("${BIN}" -v 2>/dev/null)" == "trzsz sshd ${VERSION}" ]]; }

main() {
  # A Linux binary in ~/.local/bin would shadow Homebrew's tsshd on a Mac.
  [[ "$(uname -s)" == "Linux" ]] || die "tsshd installer is Linux only (macOS: brew install tsshd)"
  if is_pinned; then
    log "unchanged: ${BIN} ${VERSION}"
    return 0
  fi
  local arch sum name tgz old
  case "$(uname -m)" in
  x86_64) arch=x86_64 sum=2a37ed82f5882171704cbac9580264e8e7847318be26fdae410c725cf38bb337 ;;
  aarch64) arch=aarch64 sum=6113239b26f5a070c8978f94a34d6dc8e33e3cb9e0dd078b512c65978fa551b6 ;;
  *) die "unsupported arch: $(uname -m)" ;;
  esac
  name="tsshd_${VERSION}_linux_${arch}"
  tgz="${CACHE}/${name}.tar.gz"
  mkdir -p "${CACHE}" "$(dirname "${BIN}")" || die "cannot create ${CACHE}"
  if [[ ! -f "${tgz}" ]]; then
    log "downloading tsshd ${VERSION} (${arch})"
    curl -fsSL --connect-timeout 10 --max-time 300 -o "${tgz}.part" \
      "${URL}/v${VERSION}/${name}.tar.gz" || die "download failed: ${URL}/v${VERSION}/${name}.tar.gz"
    # Verify before caching: a 200 with the wrong body must not poison the cache.
    if [[ "$(sha256_of "${tgz}.part")" != "${sum}" ]]; then
      rm -f "${tgz}.part"
      die "sha256 mismatch on download of ${tgz}"
    fi
    mv -f "${tgz}.part" "${tgz}" || die "cannot write ${tgz}"
  fi
  [[ "$(sha256_of "${tgz}")" == "${sum}" ]] || die "sha256 mismatch: ${tgz} (delete it and re-run)"
  work="$(mktemp -d)" || die "mktemp failed"
  tar -xzf "${tgz}" -C "${work}" "${name}/tsshd" || die "cannot extract ${tgz}"
  # temp + mv gives a new inode: sessions running the old binary are untouched.
  install -m 755 "${work}/${name}/tsshd" "${BIN}.tmp" || die "cannot write ${BIN}.tmp"
  mv -f "${BIN}.tmp" "${BIN}" || die "cannot replace ${BIN}"
  is_pinned || die "post-install check failed: ${BIN} -v does not report ${VERSION}"
  log "installed: ${BIN} ${VERSION}"
  # Keep this version's tarball (it seeds offline hosts); drop older ones.
  for old in "${CACHE}"/tsshd_*.tar.gz; do
    if [[ -e "${old}" && "${old}" != "${tgz}" ]]; then
      rm -f "${old}" && log "removed: ${old}"
    fi
  done
}

main "$@"
