#!/usr/bin/env bash
# Usage: install_btop.sh
#
# Clone, build, and install btop to ~/.local/. Cross-platform
# (macOS/Linux). Prefers g++-14, falls back to clang++.
#
# Re-run = update: uses a persistent checkout at ~/git/btop and only
# rebuilds when upstream HEAD moved or the target binary is missing.
#
# Env overrides:
#   BTOP_REPO  -- git remote (default: upstream)
#   BTOP_REF   -- branch/tag (default: main; ignored when repo already
#                 exists -- pulls whatever branch is checked out)
#   PREFIX     -- install prefix (default: $HOME/.local)
#   BTOP_DIR   -- persistent checkout dir (default: $HOME/git/btop)
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

BTOP_REPO="${BTOP_REPO:-https://github.com/aristocratos/btop.git}"
BTOP_REF="${BTOP_REF:-main}"
PREFIX="${PREFIX:-$HOME/.local}"
BTOP_DIR="${BTOP_DIR:-$HOME/git/btop}"

pick_compiler() {
  # btop needs C++20 -- prefer g++-14 (Homebrew gcc on mac, gcc-14 pkg
  # on Linux), fall back to clang++ (Xcode CLT on mac, clang pkg on Linux).
  if command -v g++-14 >/dev/null 2>&1; then
    echo "g++-14"
  elif command -v clang++ >/dev/null 2>&1; then
    echo "clang++"
  else
    die "no suitable C++ compiler found (need g++-14 or clang++)"
  fi
}

job_count() {
  if command -v sysctl >/dev/null 2>&1 && sysctl -n hw.ncpu >/dev/null 2>&1; then
    sysctl -n hw.ncpu
  elif command -v nproc >/dev/null 2>&1; then
    nproc
  else
    echo 4
  fi
}

main() {
  command -v git >/dev/null 2>&1 || die "git is required"
  command -v make >/dev/null 2>&1 || die "make is required"

  local state
  state="$(clone_or_pull "${BTOP_REPO}" "${BTOP_DIR}")"
  log "btop: ${state}"

  # Skip rebuild only when nothing changed AND the binary is already in place.
  if [[ -x "${PREFIX}/bin/btop" && "${state}" == "unchanged" ]]; then
    log "btop ${PREFIX}/bin/btop already current, skipping build"
    return 0
  fi

  local cxx jobs
  cxx="$(pick_compiler)"
  jobs="$(job_count)"
  log "Building btop with ${cxx} (${jobs} jobs) → ${PREFIX}"

  make -C "${BTOP_DIR}" CXX="${cxx}" -j"${jobs}"
  mkdir -p "${PREFIX}"
  make -C "${BTOP_DIR}" install PREFIX="${PREFIX}"

  log "btop installed: ${PREFIX}/bin/btop"
}

main "$@"
