#!/usr/bin/env bash
# Usage: install_gh.sh
#
# Install GitHub CLI from upstream's prebuilt tarball into ${PREFIX}/bin.
# Pure user-space; no sudo, no apt. Re-run = upgrade: queries the latest
# release tag and skips the download when the installed gh already
# matches it, otherwise overwrites.
#
# Env overrides:
#   PREFIX  install prefix (default: $HOME/.local)
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

PREFIX="${PREFIX:-${HOME}/.local}"

main() {
  local arch tag tar_url current
  case "$(uname -m)" in
    x86_64|amd64) arch="linux_amd64" ;;
    aarch64|arm64) arch="linux_arm64" ;;
    *) warn "unknown arch $(uname -m) -- skipping gh install"; return 0 ;;
  esac

  tag="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest \
    | jq -r '.tag_name')" || { warn "could not query gh latest release; skipping"; return 0; }
  [[ -n "${tag}" && "${tag}" != "null" ]] \
    || { warn "gh release lookup returned no tag; skipping"; return 0; }

  if [[ -x "${PREFIX}/bin/gh" ]]; then
    current="v$("${PREFIX}/bin/gh" --version 2>/dev/null | awk 'NR==1{print $3}')"
    if [[ "${current}" == "${tag}" ]]; then
      log "gh ${tag} already installed at ${PREFIX}/bin/gh"
      return 0
    fi
  fi

  log "installing gh ${tag} → ${PREFIX}"
  tar_url="https://github.com/cli/cli/releases/download/${tag}/gh_${tag#v}_${arch}.tar.gz"
  # Subshell + EXIT trap: scopes the tempdir cleanup to this stage so it
  # cannot leak across function boundaries (RETURN traps are globally
  # scoped in Bash and would mis-fire on the caller's later returns).
  (
    local tmpdir extracted
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "${tmpdir}"' EXIT
    curl -fsSL "${tar_url}" | tar -xzf - -C "${tmpdir}"
    extracted="${tmpdir}/gh_${tag#v}_${arch}"
    mkdir -p "${PREFIX}/bin"
    install -m 755 "${extracted}/bin/gh" "${PREFIX}/bin/gh"
    if [[ -d "${extracted}/share/man/man1" ]]; then
      mkdir -p "${PREFIX}/share/man/man1"
      cp -f "${extracted}/share/man/man1/"*.1 "${PREFIX}/share/man/man1/" 2>/dev/null || true
    fi
  )
}

main "$@"
