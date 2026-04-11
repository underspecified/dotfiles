#!/usr/bin/env bash
# Usage: install_darkman.sh
# Installs darkman and patches i3 .desktop files for correct XDG_CURRENT_DESKTOP
set -euo pipefail

GIT_DIR="${HOME}/git"

install_darkman() {
    echo "Installing darkman..."

    # install deps
    sudo apt install -y golang

    # clone repo
    mkdir -p "${GIT_DIR}"
    cd "${GIT_DIR}"
    git clone https://gitlab.com/WhyNotHugo/darkman.git

    # build and install
    cd "${GIT_DIR}/darkman"
    make
    sudo make install PREFIX=/usr

    # enable service (started by i3 config after env import)
    systemctl --user enable darkman.service
    systemctl --user daemon-reload
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
