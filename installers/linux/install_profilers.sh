#!/usr/bin/env bash
# Usage: install_profilers.sh
# Installs psensor + stress, plus builds gpu-burn from source. The
# gpu-burn build needs CUDA -- skipped with a warning if absent.
set -euo pipefail

GIT_DIR="${HOME}/git"
GPU_BURN_DIR="${GIT_DIR}/gpu-burn"

install_apt_profilers() {
  sudo apt install -y psensor stress
}

build_gpu_burn() {
  if ! command -v nvcc &>/dev/null; then
    echo "skipping gpu-burn build: nvcc (CUDA toolkit) not on PATH" >&2
    return 0
  fi

  mkdir -p "${GIT_DIR}"
  if [[ -d "${GPU_BURN_DIR}/.git" ]]; then
    git -C "${GPU_BURN_DIR}" pull --ff-only
  else
    git clone https://github.com/wilicc/gpu-burn.git "${GPU_BURN_DIR}"
  fi

  (cd "${GPU_BURN_DIR}" && make)
}

install_apt_profilers
build_gpu_burn
