#!/usr/bin/bash

CUR_DIR=$(realpath $(dirname "$0"))
GIT_DIR=$(realpath "$CUR_DIR/../..")

install_darkman() {
    echo "Installing darkman..."

    # uninstall old golang
    dpkg -l | grep golang | grep 1.13 | cut -f3 -d' ' | xargs sudo apt purge -y
    # install deps
    sudo apt install -y golang-1.18 scdoc

    # clone repo
    cd "$GIT_DIR"
    git clone https://gitlab.com/WhyNotHugo/darkman.git

    # build program
    cd darkman
    make

    # install program
    sudo make install PREFIX=/usr

    # reinstall old golang
    sudo apt install ros-noetic-strawberry-ros-asr -y

    # setup service
    systemctl --user enable darkman.service
    mkdir -p "$HOME/.config/systemd/user/darkman.service.d/"
    cp "$GIT_DIR/dotfiles/config/darkman/override.conf" "$HOME/.config/systemd/user/darkman.service.d/override.conf"

    # start service
    systemctl --user daemon-reload
}

install_darkman
