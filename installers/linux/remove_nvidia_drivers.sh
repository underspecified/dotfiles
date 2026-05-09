#!/usr/bin/env bash
# Usage: remove_nvidia_drivers.sh
# Purges every installed CUDA + NVIDIA package. Destructive -- intended for
# rebuilding the driver stack from scratch. Not auto-invoked by install.sh.
set -euo pipefail

remove_cuda() {
  local pkgs
  pkgs="$(dpkg -l | awk '/^ii/ && tolower($2) ~ /cuda/ {print $2}')"
  if [[ -n "${pkgs}" ]]; then
    # shellcheck disable=SC2086
    sudo apt-get purge -y ${pkgs}
  fi
}

remove_nvidia_driver() {
  local pkgs
  pkgs="$(dpkg -l | awk '/^ii/ && tolower($2) ~ /nvidia/ {print $2}')"
  if [[ -n "${pkgs}" ]]; then
    # shellcheck disable=SC2086
    sudo apt-get purge -y ${pkgs}
  fi
}

remove_cuda
remove_nvidia_driver
