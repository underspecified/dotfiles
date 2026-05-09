#!/usr/bin/env bash
# Usage: install_darkman.sh
# Builds darkman from source, installs to /usr, and patches i3 .desktop
# files for correct XDG_CURRENT_DESKTOP. Idempotent: re-running pulls
# upstream and rebuilds without conflict.
set -euo pipefail

GIT_DIR="${HOME}/git"
DARKMAN_DIR="${GIT_DIR}/darkman"

install_darkman() {
  echo "Installing darkman..."

  sudo apt install -y golang

  mkdir -p "${GIT_DIR}"
  if [[ -d "${DARKMAN_DIR}/.git" ]]; then
    git -C "${DARKMAN_DIR}" pull --ff-only
  else
    git clone https://gitlab.com/WhyNotHugo/darkman.git "${DARKMAN_DIR}"
  fi

  (cd "${DARKMAN_DIR}" && make && sudo make install PREFIX=/usr)

  systemctl --user daemon-reload
  systemctl --user enable darkman.service
}

patch_i3_desktop_files() {
  # i3-with-shmlog.desktop is missing DesktopNames=i3, which means
  # XDG_CURRENT_DESKTOP never gets set to "i3". Without this, the
  # XDG portal tries the GNOME backend (UseIn=gnome matches the
  # inherited ubuntu:GNOME) and times out.
  local desktop_file="/usr/share/xsessions/i3-with-shmlog.desktop"
  if [[ -f "${desktop_file}" ]]; then
    if ! grep -q '^DesktopNames=' "${desktop_file}"; then
      echo "Patching ${desktop_file} with DesktopNames=i3..."
      echo 'DesktopNames=i3' | sudo tee -a "${desktop_file}" > /dev/null
    fi
  fi
}

install_darkman
patch_i3_desktop_files
