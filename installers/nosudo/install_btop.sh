#!/usr/bin/env bash
# Usage: install_btop.sh
#
# Build btop from source for the no-sudo / headless path. Pinned to
# v1.3.2 -- the last release on the C++20 baseline that still has
# NVML-backed GPU support. v1.4.x switched to C++23 (gcc 14+ / clang
# 17+), which a nosudo host typically can't install.
#
# Compiler discovery order (any one is enough; first wins):
#   1. g++-14   (handles v1.3.x and any future C++23 builds)
#   2. clang++  (same)
#   3. g++ >= 11 (sufficient for v1.3.x's C++20 surface; the floor is
#      10 in theory but 11 is what every reasonable distro ships and
#      catches subtle <ranges>/<concepts> edge cases)
#
# Diverges from installers/all/install_btop.sh by (a) pinning a known-
# working ref instead of tracking main and (b) accepting plain g++ as
# a fallback. The sudo desktop path doesn't need either tweak because
# apt's gcc-14 / clang packages are installable there.
#
# Re-run = update: uses a persistent checkout at ~/git/btop and only
# rebuilds when the pinned ref moved or the target binary is missing.
#
# Env overrides:
#   BTOP_REPO  -- git remote (default: upstream)
#   BTOP_REF   -- branch/tag/sha to check out (default: v1.3.2)
#   BTOP_DIR   -- persistent checkout dir (default: $HOME/git/btop)
#   PREFIX     -- install prefix (default: $HOME/.local)
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

BTOP_REPO="${BTOP_REPO:-https://github.com/aristocratos/btop.git}"
BTOP_REF="${BTOP_REF:-v1.3.2}"
BTOP_DIR="${BTOP_DIR:-${HOME}/git/btop}"
PREFIX="${PREFIX:-${HOME}/.local}"

pick_compiler() {
  if command -v g++-14 >/dev/null 2>&1; then
    echo "g++-14"
    return
  fi
  if command -v clang++ >/dev/null 2>&1; then
    echo "clang++"
    return
  fi
  if command -v g++ >/dev/null 2>&1; then
    local major
    major="$(g++ -dumpversion 2>/dev/null | cut -d. -f1)"
    if [[ "${major}" =~ ^[0-9]+$ ]] && (( major >= 11 )); then
      echo "g++"
      return
    fi
  fi
  die "no suitable C++ compiler found (need g++-14, clang++, or g++ >=11)"
}

job_count() {
  if command -v nproc >/dev/null 2>&1; then
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

  # Pin to BTOP_REF. clone_or_pull leaves us on whatever branch was
  # checked out before (usually main); checking out the pin explicitly
  # here keeps the build deterministic across upstream C++ baseline drift.
  local current target
  current="$(git -C "${BTOP_DIR}" rev-parse HEAD)"
  if ! git -C "${BTOP_DIR}" rev-parse --quiet --verify "${BTOP_REF}^{commit}" >/dev/null 2>&1; then
    git -C "${BTOP_DIR}" fetch --quiet --tags origin
  fi
  target="$(git -C "${BTOP_DIR}" rev-parse --verify "${BTOP_REF}^{commit}" 2>/dev/null || true)"
  if [[ -n "${target}" && "${target}" != "${current}" ]]; then
    log "btop: checking out ${BTOP_REF} (${target:0:7})"
    git -C "${BTOP_DIR}" checkout --quiet "${BTOP_REF}"
    state="updated:${current:0:7}..${target:0:7}"
  fi

  # Skip rebuild only when nothing changed AND the binary is already in place.
  if [[ -x "${PREFIX}/bin/btop" && "${state}" == "unchanged" ]]; then
    log "btop ${PREFIX}/bin/btop already current, skipping build"
    return 0
  fi

  local cxx jobs
  cxx="$(pick_compiler)"
  jobs="$(job_count)"
  log "Building btop ${BTOP_REF} with ${cxx} (${jobs} jobs) → ${PREFIX}"

  make -C "${BTOP_DIR}" CXX="${cxx}" -j"${jobs}"
  mkdir -p "${PREFIX}"
  make -C "${BTOP_DIR}" install PREFIX="${PREFIX}"

  log "btop installed: ${PREFIX}/bin/btop"
}

main "$@"
