#!/usr/bin/env bash
# Usage: install_nvidia_drivers.sh
# Installs the NVIDIA open driver from the official CUDA apt repo. CUDA
# toolkit install is opt-in via INSTALL_CUDA=1 (multi-GB pull).
#
# Env overrides:
#   NVIDIA_VERSION  driver version pin (e.g. "560") -- default unpinned
#   CUDA_VERSION    cuda meta pkg version pin       -- default unpinned
#   INSTALL_CUDA    "1" to also install CUDA toolkit -- default unset
set -euo pipefail

RELEASE="$(lsb_release -rs | tr -d .)"

if [[ -n "${NVIDIA_VERSION:-}" ]]; then
  NVIDIA_PACKAGE="nvidia-open-${NVIDIA_VERSION}"
else
  NVIDIA_PACKAGE="nvidia-open"
fi

if [[ -n "${CUDA_VERSION:-}" ]]; then
  CUDA_PACKAGE="cuda-${CUDA_VERSION}"
else
  CUDA_PACKAGE="cuda"
fi

install_nvidia_repo() {
  local keyring_deb="cuda-keyring_1.1-1_all.deb"
  local repo_url="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${RELEASE}/x86_64"

  if dpkg -l cuda-keyring &>/dev/null; then
    echo "cuda-keyring already installed; skipping repo setup"
    return 0
  fi

  local workdir
  workdir="$(mktemp -d)"
  trap 'rm -rf "${workdir}"' RETURN

  wget -O "${workdir}/${keyring_deb}" "${repo_url}/${keyring_deb}"
  sudo dpkg -i "${workdir}/${keyring_deb}"
  sudo apt update
}

install_nvidia_drivers() {
  sudo apt install -y "${NVIDIA_PACKAGE}"
}

install_cuda() {
  sudo apt install -y "${CUDA_PACKAGE}" nvidia-cuda-toolkit nvidia-cuda-dev
}

install_nvidia_repo
install_nvidia_drivers

if [[ "${INSTALL_CUDA:-}" == "1" ]]; then
  install_cuda
else
  echo "skipping CUDA toolkit install (set INSTALL_CUDA=1 to install)"
fi
