#!/usr/bin/env bash
# Usage: install_shellcheck.sh
#
# Install shellcheck from upstream's prebuilt static tarball into
# ${PREFIX}/bin. The static binary has no runtime deps. Needed by the
# global PostToolUse hook ~/.claude/hooks/shellcheck_lint.sh; without
# it, every .sh edit produces a misleading "ShellCheck found issues"
# report (because `shellcheck` exits non-zero on command-not-found).
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
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *) warn "unknown arch $(uname -m) -- skipping shellcheck install"; return 0 ;;
  esac

  tag="$(curl -fsSL https://api.github.com/repos/koalaman/shellcheck/releases/latest \
    | jq -r '.tag_name')" || { warn "could not query shellcheck latest release; skipping"; return 0; }
  [[ -n "${tag}" && "${tag}" != "null" ]] \
    || { warn "shellcheck release lookup returned no tag; skipping"; return 0; }

  if [[ -x "${PREFIX}/bin/shellcheck" ]]; then
    current="v$("${PREFIX}/bin/shellcheck" --version 2>/dev/null | awk '/^version:/{print $2}')"
    if [[ "${current}" == "${tag}" ]]; then
      log "shellcheck ${tag} already installed at ${PREFIX}/bin/shellcheck"
      return 0
    fi
  fi

  log "installing shellcheck ${tag} → ${PREFIX}"
  tar_url="https://github.com/koalaman/shellcheck/releases/download/${tag}/shellcheck-${tag}.linux.${arch}.tar.xz"
  (
    local tmpdir
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "${tmpdir}"' EXIT
    curl -fsSL "${tar_url}" | tar -xJf - -C "${tmpdir}"
    mkdir -p "${PREFIX}/bin"
    install -m 755 "${tmpdir}/shellcheck-${tag}/shellcheck" "${PREFIX}/bin/shellcheck"
  )
}

main "$@"
