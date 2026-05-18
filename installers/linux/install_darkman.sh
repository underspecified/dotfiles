#!/usr/bin/env bash
# Usage: install_darkman.sh
# Builds darkman from source, installs to /usr, and patches i3 .desktop
# files for correct XDG_CURRENT_DESKTOP. Re-run = update: pulls upstream
# and rebuilds only when HEAD moves; .desktop patch is content-guarded.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

GIT_DIR="${HOME}/git"
DARKMAN_DIR="${GIT_DIR}/darkman"

install_darkman() {
  log "Installing darkman..."

  sudo apt install -y golang

  local state
  state="$(clone_or_pull https://gitlab.com/WhyNotHugo/darkman.git "${DARKMAN_DIR}")"
  log "darkman: ${state}"

  if [[ -x /usr/bin/darkman && "${state}" == "unchanged" ]]; then
    log "darkman /usr/bin/darkman already current, skipping build"
  else
    (cd "${DARKMAN_DIR}" && make && sudo make install PREFIX=/usr)
  fi

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
      log "Patching ${desktop_file} with DesktopNames=i3..."
      echo 'DesktopNames=i3' | sudo tee -a "${desktop_file}" > /dev/null
    fi
  fi
}

install_darkman
patch_i3_desktop_files
