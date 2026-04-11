#!/bin/bash

CUR_DIR=$(realpath $(dirname "$0"))

### install basic packages
install_apt () {
    sudo apt update && \
    sudo apt install -y chrome-gnome-shell curl emacs git golang jq keychain nodejs npm openssh-server psensor zsh
}

install_google_chrome() {
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
    sudo wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo apt update
    sudo apt-get install -y google-chrome-stable
}

install_gh () {
    (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
   	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
   	&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
   	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
   	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
   	&& sudo apt update \
   	&& sudo apt install gh -y
}

### install from snap
install_snap () {
    sudo snap refresh
    # install VS code
    #sudo snap install --classic code
    # install cpu/gpu monitors
    #sudo snap install htop nvtop
    # install slack
    sudo snap install slack
}

### install zed
install_zed () {
    curl -f https://zed.dev/install.sh | sh
}

### update git
update_git () {
    sudo add-apt-repository -y ppa:git-core/ppa && \
    sudo apt update && \
    sudo apt install -y git
}

update_less () {
    cd $HOME/Downloads && \
    curl -f https://www.greenwoodsoftware.com/less/less-668.tar.gz | tar -xzf - && \
    cd less-668 && \
    ./configure --prefix=$HOME/.local && \
    make install
}


# install packages
install_apt
#install_snap

# install github
install_gh

# install google chrome
install_google_chrome

# install zed
install_zed

# update utils
update_git
update_less

# install 1password
bash "$CUR_DIR/install_1password.sh"

# install darkman
bash "$CUR_DIR/install_darkman.sh"

# install i3 window manager
bash "$CUR_DIR/install_i3.sh"

# install kitty
bash "$CUR_DIR/install_kitty/install.sh"

# install nvidia drivers
bash "$CUR_DIR/install_nvidia_drivers.sh"

# install profilers
bash "$CUR_DIR/install_profilers.sh"
