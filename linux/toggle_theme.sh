#!/bin/bash

dark () {
    /home/eric/.local/kitty.app/bin/kitty +kitten themes --config-file-name=themes.conf --reload-in=all "Selenized Dark"
    sed -i.bak -r 's/"mode": ".+"/"mode": "dark"/' ~/.config/zed/settings.json
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"
}

light () {
    /home/eric/.local/kitty.app/bin/kitty +kitten themes --config-file-name=themes.conf --reload-in=all "Selenized Light"
    sed -i.bak -r 's/"mode": ".+"/"mode": "light"/' ~/.config/zed/settings.json
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru-light"
}

toggle () {
    mode=$(gsettings get org.gnome.desktop.interface gtk-theme)
    echo "mode: $mode"
    if [ $(echo $mode | grep -i dark) ]; then
        light
    else
        dark
    fi
}

if [ "$1" == "dark" ]; then
    dark
elif [ "$1" == "light" ]; then
    light
else
    toggle
fi
