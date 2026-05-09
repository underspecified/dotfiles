#!/usr/bin/env bash
# Usage: install_i3.sh
# Installs i3wm and the userland the rest of this dotfiles repo configures:
# notifications (dunst), compositor (picom), screenshots (flameshot),
# launcher (j4-dmenu-desktop + dmenu), polkit agent, and the slock locker.
set -euo pipefail

install_i3() {
  sudo apt update
  sudo apt install -y \
    i3 i3-wm i3status \
    dbus dbus-x11 \
    feh \
    picom \
    dunst \
    flameshot \
    dmenu j4-dmenu-desktop \
    policykit-1-gnome \
    xsettingsd \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-wlr \
    gnome-session
}

install_slock() {
  sudo apt install -y slock
}

install_i3
install_slock
