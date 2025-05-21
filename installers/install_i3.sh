#!/usr/bin/bash

### install i3 window manager
### https://i3wm.org/docs/repositories.html
### https://kifarunix.com/install-and-setup-i3-windows-manager-on-ubuntu-20-04/
install_i3 () {
    /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2025.03.09_all.deb keyring.deb SHA256:2c2601e6053d5c68c2c60bcd088fa9797acec5f285151d46de9c830aaba6173c
    sudo apt install ./keyring.deb
    echo "deb [signed-by=/usr/share/keyrings/sur5r-keyring.gpg] http://debian.sur5r.net/i3/ $(grep '^VERSION_CODENAME=' /etc/os-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
    sudo apt update
    sudo apt install -y dbus dbus-x11 i3 i3-wm feh gnome-shell gnome-session j4-dmenu-desktop xautolock xdg-desktop-portal-gtk xdg-desktop-portal-wlr
}

install_i3lock () {
    # remove old version
    sudo apt remove i3lock

    # install build deps
    sudo apt install -y autoconf gcc make pkg-config libpam0g-dev libcairo2-dev libfontconfig1-dev libxcb-composite0-dev libev-dev libgif-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev libxcb-image0-dev libxcb-util-dev libxcb-xrm-dev libxkbcommon-dev libxkbcommon-x11-dev libjpeg-dev

    (mkdir -p ~/git && \
     cd ~/git && \
     git clone https://github.com/Raymo111/i3lock-color.git
     cd i3lock-color && \
     sudo ./install-i3lock-color.sh)
}

install_i3
install_i3lock
