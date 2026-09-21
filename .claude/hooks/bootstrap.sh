#!/usr/bin/env bash
# Usage: bash ~/.claude/hooks/bootstrap.sh
#
# Install every formatter/linter the global PostToolUse hooks invoke:
#   ruff (.py)   rumdl (.md)   panache (.qmd)   shfmt + shellcheck (.sh)
#   jq           (every hook parses its stdin payload with it)
#
# Called by ~/.claude/bootstrap.sh, which both installers/linux/install.sh
# and installers/nosudo/install.sh run on machine bring-up.
#
# Why this exists: every hook swallows its own errors, so a missing tool is
# not an error -- it is a hook that silently does nothing. ruff, rumdl and
# panache were absent on all six Linux hosts, so the .py/.md/.qmd formatters
# were no-ops everywhere but the Mac, and nothing ever reported it.
#
# Install channels, in preference order:
#   macOS            Homebrew
#   Ubuntu w/ sudo   apt for jq, shellcheck, shfmt -- the only three it has
#   anywhere else    uv tool (ruff, rumdl) + release tarball (panache) +
#                    the nosudo installers (shfmt, shellcheck), all into
#                    ~/.local, no root required
#
# apt is attempted only when sudo needs no password, since bootstrap runs
# unattended. No host in the current fleet has passwordless sudo, so the
# user-space path is what actually runs -- but apt is correct on a fresh
# Ubuntu desktop where it is configured, and it is cheap to prefer.
#
# No `set -e`: one unavailable tool must not abort the rest of the chain.
#
# Env overrides:
#   PREFIX   install prefix for user-space installs (default: $HOME/.local)
#   LNK_DIR  dotfiles checkout (default: $HOME/.config/lnk)
set -uo pipefail

PREFIX="${PREFIX:-${HOME}/.local}"
LNK_DIR="${LNK_DIR:-${HOME}/.config/lnk}"
PANACHE_REPO="jolars/panache"
FAILED=""

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
fail() { FAILED="${FAILED} $1"; }

# --- apt ------------------------------------------------------------------
apt_usable() { have apt-get && sudo -n true 2>/dev/null; }

apt_install() {
  # "$@" = packages, already filtered by the caller to the missing ones.
  (($#)) || return 0
  log "apt-get install $*"
  sudo -n apt-get update -qq >/dev/null 2>&1
  sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" >/dev/null 2>&1 ||
    {
      warn "apt-get install failed for: $*"
      return 1
    }
}

# --- uv_tool <pypi-pkg> <binary> ------------------------------------------
# `uv tool install --upgrade` is idempotent: installs when absent, upgrades
# in place otherwise. Used only for tools whose PyPI package IS upstream.
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
  have "${bin}" ||
    warn "${bin} installed but not on PATH -- is ${HOME}/.local/bin in \$PATH?"
}

# --- install_panache_linux ------------------------------------------------
# Tarball, NOT PyPI. The PyPI name `panache` belongs to sebogh/panache,
# "Pandoc wrapped in styles" -- an entirely unrelated project. Installing it
# would put a wrong `panache` on PATH for the .qmd hook to call.
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
    [[ "v${cur}" == "${tag}" ]] && {
      log "panache ${tag} already current"
      return 0
    }
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

# --- per-platform ---------------------------------------------------------
install_macos() {
  local missing=""
  have brew || {
    warn "Homebrew not found -- cannot install on macOS"
    return 1
  }
  for t in ruff rumdl panache shfmt shellcheck jq; do
    have "$t" || missing="${missing} $t"
  done
  if [[ -n "${missing}" ]]; then
    log "brew install${missing}"
    # shellcheck disable=SC2086  # deliberate word splitting on the package list
    brew install ${missing} || fail "brew:${missing}"
  else
    log "all hook tools already present"
  fi
  # Report staleness rather than forcing it: panache 2->3 changes formatting
  # behaviour, and this is the highest-blast-radius PL. Upgrade deliberately.
  brew outdated --formula ruff rumdl panache shfmt shellcheck jq 2>/dev/null |
    sed 's/^/  outdated (not auto-upgraded): /'
}

install_linux() {
  # 1. apt first, for the three packages it actually carries.
  if apt_usable; then
    local want=""
    for t in jq shellcheck shfmt; do
      have "$t" || want="${want} ${t}"
    done
    # shellcheck disable=SC2086  # deliberate split into separate package args
    [[ -n "${want}" ]] && { apt_install ${want} || true; }
  fi

  have jq || {
    warn "jq missing and unavailable via apt -- install it first; every hook needs it"
    fail jq
    return 1
  }

  # 2. uv for the two whose PyPI package is upstream.
  uv_tool ruff ruff || fail ruff
  uv_tool rumdl rumdl || fail rumdl

  # 3. panache: release tarball only.
  install_panache_linux || fail panache

  # 4. shfmt/shellcheck: user-space installers already in the repo.
  for t in shfmt shellcheck; do
    have "$t" && continue
    if [[ -x "${LNK_DIR}/installers/nosudo/install_${t}.sh" ]]; then
      "${LNK_DIR}/installers/nosudo/install_${t}.sh" || fail "$t"
    else
      warn "no installer for ${t} at ${LNK_DIR}/installers/nosudo/"
      fail "$t"
    fi
  done
}

main() {
  have curl || {
    warn "curl is required"
    return 1
  }

  case "$(uname -s)" in
  Darwin) install_macos ;;
  *) install_linux ;;
  esac

  echo
  log "hook toolchain:"
  for t in ruff rumdl panache shfmt shellcheck jq; do
    if have "$t"; then
      printf '  %-11s OK       %s\n' "$t" "$(command -v "$t")"
    else
      printf '  %-11s MISSING\n' "$t"
    fi
  done

  if [[ -n "${FAILED}" ]]; then
    warn "failed:${FAILED}"
    return 1
  fi
  return 0
}

main "$@"
