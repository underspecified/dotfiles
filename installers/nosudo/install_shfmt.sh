#!/usr/bin/env bash
# Usage: install_shfmt.sh
#
# Install shfmt (Go binary, ships per-platform on GitHub releases) into
# ${PREFIX}/bin. Required by the global PostToolUse hook (it calls
# `shfmt -w` before invoking shellcheck). No tarball, just download + chmod.
#
# Env overrides:
#   PREFIX  install prefix (default: $HOME/.local)
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

PREFIX="${PREFIX:-${HOME}/.local}"

main() {
  local arch tag bin_url current
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) warn "unknown arch $(uname -m) -- skipping shfmt install"; return 0 ;;
  esac

  tag="$(curl -fsSL https://api.github.com/repos/mvdan/sh/releases/latest \
    | jq -r '.tag_name')" || { warn "could not query shfmt latest release; skipping"; return 0; }
  [[ -n "${tag}" && "${tag}" != "null" ]] \
    || { warn "shfmt release lookup returned no tag; skipping"; return 0; }

  if [[ -x "${PREFIX}/bin/shfmt" ]]; then
    # shfmt prints just "vX.Y.Z" with no extra text -- direct compare.
    current="$("${PREFIX}/bin/shfmt" --version 2>/dev/null)"
    if [[ "${current}" == "${tag}" ]]; then
      log "shfmt ${tag} already installed at ${PREFIX}/bin/shfmt"
      return 0
    fi
  fi

  log "installing shfmt ${tag} → ${PREFIX}/bin"
  bin_url="https://github.com/mvdan/sh/releases/download/${tag}/shfmt_${tag}_linux_${arch}"
  mkdir -p "${PREFIX}/bin"
  curl -fsSL -o "${PREFIX}/bin/shfmt" "${bin_url}"
  chmod 755 "${PREFIX}/bin/shfmt"
}

main "$@"
