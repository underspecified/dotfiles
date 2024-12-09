#!/bin/bash

dark () {
    $HOME/.local/kitty.app/bin/kitty +kitten themes --config-file-name=themes.conf --reload-in=all "Selenized Dark"

    sed -i.bak -r 's/"mode": ".+"/"mode": "dark"/' ~/.config/zed/settings.json

    gsettings get org.gnome.desktop.interface gtk-theme |
    sed 's/light/dark/; s/Light/Dark/' |
    xargs gsettings set org.gnome.desktop.interface gtk-theme

    sed -i.bak -r 's/set \$mode = .+/set \$mode = dark/' ~/.config/i3/config
    i3 restart
}

light () {
    $HOME/.local/kitty.app/bin/kitty +kitten themes --config-file-name=themes.conf --reload-in=all "Selenized Light"

    sed -i.bak -r 's/"mode": ".+"/"mode": "light"/' ~/.config/zed/settings.json

    gsettings get org.gnome.desktop.interface gtk-theme |
    sed 's/dark/light/; s/Dark/Light/' |
    xargs gsettings set org.gnome.desktop.interface gtk-theme

    sed -i.bak -r 's/set \$mode = .+/set \$mode = light/' ~/.config/i3/config
    i3 restart
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
