#!/usr/bin/env bash
# Usage: install_nvtop.sh
#
# Clone, build, and install nvtop to ${PREFIX}/bin. Pure user-space:
# no sudo, no apt. NVIDIA-only build by default -- skips libdrm and the
# AMDGPU/INTEL/MSM backends, which is the right trade-off on no-sudo
# headless hosts where libdrm-dev typically isn't installed (the
# /usr/include/drm/ headers are usually present but the libdrm.pc file
# isn't, which would otherwise fail pkg_check_modules(libdrm)).
#
# Re-run = update: uses a persistent checkout at ~/git/nvtop and only
# rebuilds when upstream HEAD moved or the target binary is missing.
#
# Skips entirely (warn, exit 0) when nvidia-smi isn't on PATH -- nvtop
# without an NVIDIA driver is useless and the caller (install_nosudo.sh)
# should chain this safely on non-GPU hosts.
#
# Env overrides:
#   NVTOP_REPO   -- git remote (default: upstream)
#   NVTOP_REF    -- branch/tag/sha to check out (default: keep current)
#   NVTOP_DIR    -- persistent checkout dir (default: $HOME/git/nvtop)
#   PREFIX       -- install prefix (default: $HOME/.local)
#   NVTOP_FLAGS  -- extra CMake -D flags (advanced; e.g. enable AMDGPU)
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

NVTOP_REPO="${NVTOP_REPO:-https://github.com/Syllo/nvtop.git}"
NVTOP_REF="${NVTOP_REF:-}"
NVTOP_DIR="${NVTOP_DIR:-${HOME}/git/nvtop}"
PREFIX="${PREFIX:-${HOME}/.local}"
NVTOP_FLAGS="${NVTOP_FLAGS:-}"

check_build_deps() {
  local missing=()
  local tool
  for tool in git cmake make pkg-config; do
    command -v "${tool}" >/dev/null 2>&1 || missing+=("${tool}")
  done
  # Prefer cc/c++ over picking specific names -- nvtop is plain C and
  # any modern compiler works (no C++23 drama like btop).
  command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 \
    || missing+=("gcc")
  if (( ${#missing[@]} > 0 )); then
    warn "missing build deps for nvtop: ${missing[*]}"
    warn "  Debian/Ubuntu:  sudo apt install ${missing[*]}"
    return 1
  fi

  # ncurses + udev (or systemd) headers are required by every nvtop
  # build, NVIDIA-only or not. pkg-config is the canonical check.
  local missing_pc=()
  local pc
  for pc in ncursesw libudev; do
    pkg-config --exists "${pc}" 2>/dev/null || missing_pc+=("${pc}-dev")
  done
  if (( ${#missing_pc[@]} > 0 )); then
    warn "missing pkg-config modules for nvtop: ${missing_pc[*]}"
    warn "  Debian/Ubuntu:  sudo apt install ${missing_pc[*]}"
    return 1
  fi
  return 0
}

main() {
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    warn "skipping nvtop build: nvidia-smi not on PATH (no NVIDIA driver)"
    return 0
  fi

  check_build_deps || {
    warn "skipping nvtop build: missing build dependencies (see warnings above)"
    return 0
  }

  local state
  state="$(clone_or_pull "${NVTOP_REPO}" "${NVTOP_DIR}")"
  log "nvtop: ${state}"

  # Optional ref pin -- mirrors install_btop.sh's BTOP_REF logic.
  if [[ -n "${NVTOP_REF}" ]]; then
    local current target
    current="$(git -C "${NVTOP_DIR}" rev-parse HEAD)"
    if ! git -C "${NVTOP_DIR}" rev-parse --quiet --verify "${NVTOP_REF}^{commit}" >/dev/null 2>&1; then
      git -C "${NVTOP_DIR}" fetch --quiet --tags origin
    fi
    target="$(git -C "${NVTOP_DIR}" rev-parse --verify "${NVTOP_REF}^{commit}" 2>/dev/null || true)"
    if [[ -n "${target}" && "${target}" != "${current}" ]]; then
      log "nvtop: checking out ${NVTOP_REF} (${target:0:7})"
      git -C "${NVTOP_DIR}" checkout --quiet "${NVTOP_REF}"
      state="updated:${current:0:7}..${target:0:7}"
    fi
  fi

  if [[ -x "${PREFIX}/bin/nvtop" && "${state}" == "unchanged" ]]; then
    log "nvtop ${PREFIX}/bin/nvtop already current, skipping build"
    return 0
  fi

  log "Configuring nvtop (NVIDIA-only) → ${PREFIX}"
  local build_dir="${NVTOP_DIR}/build"
  rm -rf "${build_dir}"
  mkdir -p "${build_dir}"

  # Word-split NVTOP_FLAGS deliberately so callers can pass multiple -D
  # flags as a single env var. Empty string expands to nothing.
  # shellcheck disable=SC2086
  (
    cd "${build_dir}"
    cmake \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DNVIDIA_SUPPORT=ON \
      -DAMDGPU_SUPPORT=OFF \
      -DRADEON_SUPPORT=OFF \
      -DINTEL_SUPPORT=OFF \
      -DMSM_SUPPORT=OFF \
      -DPANFROST_SUPPORT=OFF \
      -DPANTHOR_SUPPORT=OFF \
      -DV3D_SUPPORT=OFF \
      -DAPPLE_SUPPORT=OFF \
      -DASCEND_SUPPORT=OFF \
      ${NVTOP_FLAGS} \
      ..
  )

  local jobs
  if command -v nproc >/dev/null 2>&1; then
    jobs="$(nproc)"
  else
    jobs=4
  fi
  log "Building nvtop with ${jobs} jobs"
  make -C "${build_dir}" -j"${jobs}"
  install -m 755 "${build_dir}/src/nvtop" "${PREFIX}/bin/nvtop"
  log "nvtop installed: ${PREFIX}/bin/nvtop"
}

main "$@"
