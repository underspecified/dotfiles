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
  # slock ships in suckless-tools on Ubuntu (no standalone slock pkg).
  sudo apt install -y suckless-tools
}

release_gnome_keygrabs() {
  # gnome-settings-daemon's media-keys plugin registers exclusive X11 key
  # grabs for its default bindings. The screensaver default is <Super>l,
  # which steals i3's $mod+l before i3 sees the keypress. Releasing the
  # grab lets i3's bindsym fire as intended. Persists in dconf; gsd
  # picks it up live (no logout needed).
  gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['']"
}

install_i3
install_slock
release_gnome_keygrabs
