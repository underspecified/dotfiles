#!/usr/bin/env bash
# Usage: install_gpu_burn.sh
#
# Clone, build, and install gpu-burn to ${GPU_BURN_DIR}. Pure user-space:
# no sudo, no apt. Cross-platform (Linux+CUDA; macOS unsupported by the
# tool itself). Re-run = update: rebuilds only when upstream HEAD moves
# or the target binary is missing. Skips entirely (warn, exit 0) when
# nvcc isn't on PATH, so the caller can chain this safely on hosts
# without CUDA installed.
#
# Env overrides:
#   GPU_BURN_REPO  -- git remote (default: upstream)
#   GPU_BURN_DIR   -- persistent checkout dir (default: $HOME/git/gpu-burn)
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

GPU_BURN_REPO="${GPU_BURN_REPO:-https://github.com/wilicc/gpu-burn.git}"
GPU_BURN_DIR="${GPU_BURN_DIR:-${HOME}/git/gpu-burn}"

main() {
  command -v git >/dev/null 2>&1 || die "git is required"
  command -v make >/dev/null 2>&1 || die "make is required"

  if ! command -v nvcc >/dev/null 2>&1; then
    warn "skipping gpu-burn build: nvcc (CUDA toolkit) not on PATH"
    return 0
  fi

  local state
  state="$(clone_or_pull "${GPU_BURN_REPO}" "${GPU_BURN_DIR}")"
  log "gpu-burn: ${state}"

  # Skip rebuild only when nothing changed AND the binary is already present.
  if [[ -x "${GPU_BURN_DIR}/gpu_burn" && "${state}" == "unchanged" ]]; then
    log "gpu-burn ${GPU_BURN_DIR}/gpu_burn already current, skipping build"
    return 0
  fi

  log "Building gpu-burn"
  (cd "${GPU_BURN_DIR}" && make)
  log "gpu-burn built: ${GPU_BURN_DIR}/gpu_burn"
  log "  run with: ${GPU_BURN_DIR}/gpu_burn <duration_seconds>"
}

main "$@"
