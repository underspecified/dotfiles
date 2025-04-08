#!/bin/bash

### install 1password
install_1password () {
    [[ `which op` ]] || (
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
    )
}

### install basic packages
install_apt () {
    sudo apt update && \
    sudo apt install -y chrome-gnome-shell curl emacs git golang jq keychain openssh-server psensor zsh

install_google_chrome() {
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
    sudo wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo apt update
    sudo apt-get install google-chrome-stable
}

install_gh () {
    [[ `which gh` ]] || (
        (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
    	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
    	&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    	&& sudo apt update \
    	&& sudo apt install gh -y
    )
}

install_git_credential_1password() {
    [[ -d ~/git/git-credential-1password ]] || {
        mkdir -p ~/git && \
        cd ~/git && \
        git clone https://github.com/ethrgeist/git-credential-1password.git
    }
    [[ -x ~/.local/bin/git-credential-1password ]] || {
        cd ~/git/git-credential-1password && \
        go build -o git-credential-1password && \
        cp git-credential-1password ~/.local/bin
    }
}

install_heliocron () {
    [[ `which cargo` ]] || sudo apt install cargo
    [[ `which heliocron` ]] || cargo install heliocron
    [[ -d "$HOME/git/linux/etc/crontab" ]] && \
    (cat "$HOME/git/linux/etc/crontab" | crontab -)
}

### install i3 window manager
### https://i3wm.org/docs/repositories.html
### https://kifarunix.com/install-and-setup-i3-windows-manager-on-ubuntu-20-04/
install_i3 () {
    /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2025.03.09_all.deb keyring.deb SHA256:2c2601e6053d5c68c2c60bcd088fa9797acec5f285151d46de9c830aaba6173c
    sudo apt install ./keyring.deb
    echo "deb [signed-by=/usr/share/keyrings/sur5r-keyring.gpg] http://debian.sur5r.net/i3/ $(grep '^VERSION_CODENAME=' /etc/os-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list

    sudo apt update
    sudo apt install i3
    sudo apt install feh j4-dmenu-desktop

    # sudo apt install feh fonts-font-awesome rofi pulseaudio-utils xbacklight alsa-tools clipit gcc git terminator locate pcmanfm acpi libnotify-bin htop

    # sudo add-apt-repository -y -u ppa:linuxuprising/shutter
    # sudo apt install shutter

    # (cd ~/git
    # git clone https://github.com/szekelyszilv/ybacklight.git
    # cd ybacklight/src
    # gcc src/ybacklight.c -o ~/.local/bin/ybacklight)

    # sudo apt install mlocate && sudo updatedb
}

install_i3lock () {
    # remove old version
    sudo apt remove i3lock

    # install build deps
    sudo apt install autoconf gcc make pkg-config libpam0g-dev libcairo2-dev libfontconfig1-dev libxcb-composite0-dev libev-dev libgif-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev libxcb-image0-dev libxcb-util-dev libxcb-xrm-dev libxkbcommon-dev libxkbcommon-x11-dev libjpeg-dev

    (cd ~/git
     git clone https://github.com/Raymo111/i3lock-color.git
     cd i3lock-color
     sudo ./install-i3lock-color.sh)
)
}

### install kitty
install_kitty () {
    [[ `which kitty` ]] || (
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
        # Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in
        # your system-wide PATH)
        ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
        # Place the kitty.desktop file somewhere it can be found by the OS
        cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
        # If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file
        cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
        # Update the paths to the kitty and its icon in the kitty desktop file(s)
        sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
        sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
        # Make xdg-terminal-exec (and hence desktop environments that support it use kitty)
        echo 'kitty.desktop' > ~/.config/xdg-terminals.list
    )
}

### install nvidia drivers and cuda
install_nvidia_drivers () {
    sudo apt update && \
    sudo apt install -y --allow-change-held-packages nvidia-settings=560.35.05-0ubuntu1 && \
    sudo apt install -y --allow-change-held-packages nvidia-open-560=560.35.05-0ubuntu1 nvidia-driver-560-open nvidia-compute-utils-560 nvidia-utils-560 xserver-xorg-video-nvidia-560 \
                        libnvidia-cfg1-560 libnvidia-common-560 libnvidia-compute-560 libnvidia-decode-560 libnvidia-extra-560 \
                        libnvidia-encode-560 libnvidia-gl-560 && \
    sudo apt install -y cuda-12-6 cuda-runtime-12-6 cuda-demo-suite-12-6 && \
    sudo apt-mark hold nvidia-driver-560-open nvidia-settings cuda-12-6
}

install_nvidia_repo () {
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    rm cuda-keyring_1.1-1_all.deb
    sudo apt update

    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-archive-keyring.gpg
    sudo mv cuda-archive-keyring.gpg /usr/share/keyrings/cuda-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/repos/ubuntu2004/ /" \
        | tee /etc/apt/sources.list.d/cuda-repos-ubuntu2004.list
}

install_polybar () {
    sudo apt install build-essential git cmake cmake-data pkg-config python3-sphinx python3-packaging libuv1-dev libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev
    sudo apt install libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev i3-wm libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev
    mkdir -p ~/tmp
    cd ~/tmp

    wget https://github.com/polybar/polybar/releases/download/3.7.2/polybar-3.7.2.tar.gz
    tar zxvf polybar-3.7.2.tar.gz
    cd polybar-3.7.2

    mkdir build
    cd build
    cmake ..
    make -j$(nproc)
    # Optional. This will install the polybar executable in /usr/bin
    sudo make install
}

# https://regolith-desktop.com/docs/using-regolith/install/
install_regolith () {
    [[ `which regolith-sesion` ]] || (
        wget -qO - https://regolith-desktop.org/regolith.key | \
        gpg --dearmor | sudo tee /usr/share/keyrings/regolith-archive-keyring.gpg > /dev/null

        echo deb "[arch=amd64 signed-by=/usr/share/keyrings/regolith-archive-keyring.gpg] \
        https://regolith-desktop.org/testing-ubuntu-focal-amd64 focal main" | \
        sudo tee /etc/apt/sources.list.d/regolith.list

        sudo apt update
        sudo apt install regolith-desktop regolith-session-flashback regolith-look-solarized-dark
    )
}

### install from snap
install_snap () {
    sudo snap refresh
    # install VS code
    sudo snap install --classic code
    # install cpu/gpu monitors
    sudo snap install htop nvtop
    # install slack
    sudo snap install slack
}

### install zed
install_zed () {
    [[ `which zed` ]] || curl -f https://zed.dev/install.sh | sh
}

### update git
update_git () {
    sudo add-apt-repository -y ppa:git-core/ppa && \
    sudo apt update && \
    sudo apt install -y git
}

update_less () {
    [[ -x $HOME/.local/bin/less ]] || {
        cd $HOME/Downloads && \
        curl -f https://www.greenwoodsoftware.com/less/less-668.tar.gz | tar -xzf - && \
        cd less-668 && \
        ./configure --prefix=$HOME/.local && \
        make install
    }
}

install_apt
install_snap
update_git
update_less

install_1password
install_git_credential_1password
install_gh
install_google_chrome
install_heliocron
install_i3
install_kitty
install_nvidia_drivers
#install_regolith
install_zed
