#!/usr/bin/bash

CUR_DIR=$(realpath $(dirname "$0"))
GIT_DIR=$(realpath "$CUR_DIR/../..")

install_darkman() {
    echo "Installing darkman..."

    # install deps
    sudo apt install -y golang-1.18 scdoc

    # manage golang alternatives
    sudo update-alternatives --install /usr/bin/go go /usr/lib/go-1.18/bin/go 18
    sudo update-alternatives --install /usr/bin/go go /usr/lib/go-1.13/bin/go 13
    
    # clone repo
    cd "$GIT_DIR"
    git clone https://gitlab.com/WhyNotHugo/darkman.git

    # build program
    cd darkman
    make

    # install program
    sudo make install PREFIX=/usr

    sudo update-alternatives --install /usr/bin/go go /usr/lib/go-1.13/bin/go 113

    # setup service
    systemctl --user enable darkman.service
    #mkdir -p "$HOME/.config/systemd/user/darkman.service.d/"
    #cp "$GIT_DIR/dotfiles/config/darkman/override.conf" "$HOME/.config/systemd/user/darkman.service.d/override.conf"

    # start service
    systemctl --user daemon-reload
}

install_darkman
