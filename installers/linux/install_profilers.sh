#!/usr/bin/env bash
# Usage: install_profilers.sh
# Installs psensor + stress, plus builds gpu-burn from source. The
# gpu-burn build needs CUDA -- skipped with a warning if absent.
# Re-run = update: rebuilds gpu-burn only when its HEAD moves.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

GIT_DIR="${HOME}/git"
GPU_BURN_DIR="${GIT_DIR}/gpu-burn"

install_apt_profilers() {
  sudo apt install -y psensor stress
}

build_gpu_burn() {
  if ! command -v nvcc &>/dev/null; then
    warn "skipping gpu-burn build: nvcc (CUDA toolkit) not on PATH"
    return 0
  fi

  local state
  state="$(clone_or_pull https://github.com/wilicc/gpu-burn.git "${GPU_BURN_DIR}")"
  log "gpu-burn: ${state}"

  if [[ -x "${GPU_BURN_DIR}/gpu_burn" && "${state}" == "unchanged" ]]; then
    log "gpu-burn binary already current, skipping build"
    return 0
  fi

  (cd "${GPU_BURN_DIR}" && make)
}

install_apt_profilers
build_gpu_burn
