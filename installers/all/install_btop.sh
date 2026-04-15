#!/usr/bin/env bash
# Usage: install_btop.sh
#
# Clone, build, and install btop to ~/.local/. Cross-platform
# (macOS/Linux). Prefers g++-14, falls back to clang++.
#
# Env overrides:
#   BTOP_REPO  -- git remote (default: upstream)
#   BTOP_REF   -- branch/tag (default: main)
#   PREFIX     -- install prefix (default: $HOME/.local)
set -euo pipefail

BTOP_REPO="${BTOP_REPO:-https://github.com/aristocratos/btop.git}"
BTOP_REF="${BTOP_REF:-main}"
PREFIX="${PREFIX:-$HOME/.local}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

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

  cxx="$(pick_compiler)"
  log "Compiler: ${cxx}"
  log "Prefix:   ${PREFIX}"

  workdir="$(mktemp -d -t btop-build.XXXXXX)"
  trap 'rm -rf "${workdir}"' EXIT

  log "Cloning ${BTOP_REPO}@${BTOP_REF}"
  git clone --depth 1 --branch "${BTOP_REF}" "${BTOP_REPO}" "${workdir}/btop"

  local jobs
  jobs="$(job_count)"
  log "Building with ${jobs} jobs"
  make -C "${workdir}/btop" \
    CXX="${cxx}" \
    -j"${jobs}"

  log "Installing to ${PREFIX}"
  mkdir -p "${PREFIX}"
  make -C "${workdir}/btop" install PREFIX="${PREFIX}"

  log "btop installed: ${PREFIX}/bin/btop"
}

main "$@"
