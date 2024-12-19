#!/bin/bash

get_gnome_mode () {
    gsettings get org.gnome.desktop.interface gtk-theme |
    grep -i light && echo "light" || echo "dark"
}

toggle_gnome_dark () {
    gsettings get org.gnome.desktop.interface gtk-theme |
    sed 's/light/dark/; s/Light/Dark/' |
    xargs gsettings set org.gnome.desktop.interface gtk-theme
}

toggle_gnome_light () {
    gsettings get org.gnome.desktop.interface gtk-theme |
    sed 's/dark/light/; s/Dark/Light/' |
    xargs gsettings set org.gnome.desktop.interface gtk-theme
}

toggle_gnome () {
    [[ "$1" == "dark" ]] && toggle_gnome_dark || toggle_gnome_light
}

toggle_i3 () {
    sed -i.bak -r 's/set \$mode = .+/set \$mode = '$1'/' \
        ~/git/dotfiles/config/i3/config
    i3 restart
}

toggle_kitten () {
    [[ "$1" == "dark" ]] && theme="Selenized Dark" || theme="Selenized Light"
    kitten themes --config-file-name=themes.conf --reload-in=all "$theme"
}

toggle_zed () {
    sed -i.bak -r 's/"mode": ".+"/"mode": "'$1'"/' \
        ~/git/dotfiles/config/zed/settings.json
}

if [[ $1 == "dark" ]]; then
    mode="dark"
elif [[ $1 == "light" ]]; then
    mode="light"
else
    [[ $(get_gnome_mode) == "light" ]] && mode="dark" || mode="light"
fi
# echo "mode: $mode"

toggle_gnome $mode
toggle_i3 $mode
toggle_kitten $mode
toggle_zed $mode
