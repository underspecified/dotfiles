#!/usr/bin/env bash
# Usage: install_hook_tools.sh
#
# Install every formatter/linter the global Claude Code PostToolUse hooks
# invoke: ruff (.py), rumdl (.md), panache (.qmd), shfmt + shellcheck (.sh),
# and jq (every hook parses its stdin payload with it). Cross-platform:
# Homebrew on macOS, uv + prebuilt release tarballs on Linux.
#
# Why this exists: every hook swallows its own errors, so a missing tool is
# not an error -- it is a hook that silently does nothing. ruff, rumdl and
# panache were absent on all six Linux hosts, which meant the .py/.md/.qmd
# formatters were no-ops everywhere except the Mac. Nothing reported it.
#
# No `set -e`: one unavailable tool must not abort the rest of the toolchain.
# Each installer warns and returns non-zero; main() tallies and reports.
#
# Env overrides:
#   PREFIX  install prefix for tarball installs (default: $HOME/.local)
set -uo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib.sh"

PREFIX="${PREFIX:-${HOME}/.local}"
PANACHE_REPO="jolars/panache"

have() { command -v "$1" >/dev/null 2>&1; }

# --- uv_tool <pypi-pkg> <binary> ------------------------------------------
# `uv tool install --upgrade` is idempotent: installs when absent, upgrades
# in place otherwise. Used for the two tools whose PyPI package IS upstream.
uv_tool() {
  local pkg="$1" bin="$2"
  have uv || {
    warn "uv not found -- cannot install ${pkg}"
    return 1
  }
  log "uv tool install --upgrade ${pkg}"
  uv tool install --upgrade "${pkg}" >/dev/null 2>&1 ||
    {
      warn "uv tool install ${pkg} failed"
      return 1
    }
  have "${bin}" || warn "${bin} installed but not on PATH -- is ${HOME}/.local/bin in \$PATH?"
}

# --- install_panache_linux -------------------------------------------------
# Tarball, NOT PyPI. The PyPI name `panache` is sebogh/panache ("Pandoc
# wrapped in styles") -- a completely unrelated project. Installing it would
# put a wrong `panache` on PATH that the .qmd hook would then call.
install_panache_linux() {
  local arch tag cur tmp url
  case "$(uname -m)" in
  x86_64 | amd64) arch="x86_64" ;;
  aarch64 | arm64) arch="aarch64" ;;
  *)
    warn "unknown arch $(uname -m) -- skipping panache"
    return 1
    ;;
  esac

  tag="$(curl -fsSL "https://api.github.com/repos/${PANACHE_REPO}/releases/latest" 2>/dev/null | jq -r '.tag_name')"
  [[ -n "${tag}" && "${tag}" != "null" ]] ||
    {
      warn "panache release lookup failed -- skipping"
      return 1
    }

  if have panache; then
    cur="$(panache --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    if [[ "v${cur}" == "${tag}" ]]; then
      log "panache ${tag} already current"
      return 0
    fi
  fi

  url="https://github.com/${PANACHE_REPO}/releases/download/${tag}/panache-${arch}-unknown-linux-gnu.tar.gz"
  tmp="$(mktemp -d)"
  log "installing panache ${tag} -> ${PREFIX}/bin"
  if curl -fsSL -o "${tmp}/p.tgz" "${url}" && tar -xzf "${tmp}/p.tgz" -C "${tmp}"; then
    mkdir -p "${PREFIX}/bin"
    install -m 755 "${tmp}/panache" "${PREFIX}/bin/panache"
    rm -rf "${tmp}"
  else
    warn "panache download/extract failed"
    rm -rf "${tmp}"
    return 1
  fi
}

main() {
  have jq || die "jq is required (every hook parses its payload with it)"
  have curl || die "curl is required"

  local failed=()

  if [[ "$(uname -s)" == "Darwin" ]]; then
    have brew || die "Homebrew is required on macOS"
    local missing=()
    for t in ruff rumdl panache shfmt shellcheck; do
      have "$t" || missing+=("$t")
    done
    if ((${#missing[@]})); then
      log "brew install ${missing[*]}"
      brew install "${missing[@]}" || failed+=("${missing[@]}")
    else
      log "all hook tools already present"
    fi
    # Report staleness without forcing a major-version bump: panache 2->3
    # changes formatting behavior, and this is the highest-blast-radius PL.
    brew outdated --formula ruff rumdl panache shfmt shellcheck 2>/dev/null |
      sed 's/^/  outdated: /'
  else
    uv_tool ruff ruff || failed+=(ruff)
    uv_tool rumdl rumdl || failed+=(rumdl)
    install_panache_linux || failed+=(panache)
    for t in shfmt shellcheck; do
      have "$t" && continue
      if [[ -x "${SCRIPT_DIR}/../nosudo/install_${t}.sh" ]]; then
        "${SCRIPT_DIR}/../nosudo/install_${t}.sh" || failed+=("$t")
      else
        warn "no installer for ${t}"
        failed+=("$t")
      fi
    done
  fi

  echo
  log "hook toolchain status:"
  for t in ruff rumdl panache shfmt shellcheck jq; do
    if have "$t"; then
      printf '  %-11s OK  %s\n' "$t" "$(command -v "$t")"
    else printf '  %-11s MISSING\n' "$t"; fi
  done

  ((${#failed[@]})) && {
    warn "failed: ${failed[*]}"
    return 1
  }
  return 0
}

main "$@"
