#!/usr/bin/env bash
# Usage: install_node.sh
#
# Install Node.js (current LTS) from nodejs.org's prebuilt Linux tarball
# into ${PREFIX}. The tarball ships a clean tree of bin/include/lib/share
# that drops directly into ~/.local with no glibc surprises.
#
# Needed for the claude-limitline statusline build (`npm run build`).
# Without it, ~/.claude/statusline/bootstrap.sh fails with
# "npm: command not found".
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
    x86_64|amd64) arch="linux-x64" ;;
    aarch64|arm64) arch="linux-arm64" ;;
    *) warn "unknown arch $(uname -m) -- skipping node install"; return 0 ;;
  esac

  # nodejs.org/dist/index.json: array of releases (newest first), each
  # with .version and .lts (false or LTS codename string). First entry
  # where lts != false is the latest LTS release.
  tag="$(curl -fsSL https://nodejs.org/dist/index.json \
    | jq -r 'map(select(.lts != false)) | first.version')" \
    || { warn "could not query node LTS releases; skipping"; return 0; }
  [[ -n "${tag}" && "${tag}" != "null" ]] \
    || { warn "node release lookup returned no tag; skipping"; return 0; }

  if [[ -x "${PREFIX}/bin/node" ]]; then
    current="$("${PREFIX}/bin/node" --version 2>/dev/null)"
    if [[ "${current}" == "${tag}" ]]; then
      log "node ${tag} already installed at ${PREFIX}/bin/node"
      return 0
    fi
  fi

  log "installing node ${tag} → ${PREFIX}"
  tar_url="https://nodejs.org/dist/${tag}/node-${tag}-${arch}.tar.xz"
  (
    local tmpdir extracted d
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "${tmpdir}"' EXIT
    curl -fsSL "${tar_url}" | tar -xJf - -C "${tmpdir}"
    extracted="${tmpdir}/node-${tag}-${arch}"
    # Node tarball ships bin/, include/, lib/, share/ -- merge each
    # into ${PREFIX}. Using `cp -rf <src>/.` (trailing /.) copies the
    # *contents* of src into the existing target dir, no extra nesting.
    for d in bin include lib share; do
      [[ -d "${extracted}/${d}" ]] || continue
      mkdir -p "${PREFIX}/${d}"
      cp -rf "${extracted}/${d}/." "${PREFIX}/${d}/"
    done
  )
}

main "$@"
