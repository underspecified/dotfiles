#!/usr/bin/bash

### install i3 window manager
### https://i3wm.org/docs/repositories.html
### https://kifarunix.com/install-and-setup-i3-windows-manager-on-ubuntu-20-04/
install_i3 () {
    #/usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2025.03.09_all.deb keyring.deb SHA256:2c2601e6053d5c68c2c60bcd088fa9797acec5f285151d46de9c830aaba6173c
    #sudo apt install ./keyring.deb
    #echo "deb [signed-by=/usr/share/keyrings/sur5r-keyring.gpg] http://debian.sur5r.net/i3/ $(grep '^VERSION_CODENAME=' /etc/os-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
    sudo apt update
    sudo apt install -y dbus dbus-x11 i3 i3-wm feh gnome-shell gnome-session j4-dmenu-desktop xautolock xdg-desktop-portal-gtk xsettingsd
    sudo apt install -y xdg-desktop-portal-wlr
}

install_slock () {
    sudo apt install -y slock xautolock
}

install_i3
install_slock
