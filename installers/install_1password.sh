#!/usr/bin/bash

### install 1password
install_1password () {
    # Add the key for the 1Password apt repository:
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    # Add the 1Password apt repository:
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
    # Add the debsig-verify policy:
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    # Install 1Password:
    sudo apt update && sudo apt install -y 1password 1password-cli
}

install_git_credential_1password() {
    # clone repo
    mkdir -p ~/git && \
    cd ~/git && \
    git clone https://github.com/ethrgeist/git-credential-1password.git

    # build and install
    cd ~/git/git-credential-1password && \
    go build -o git-credential-1password && \
    cp git-credential-1password ~/.local/bin
}

install_1password
install_git_credential_1password
