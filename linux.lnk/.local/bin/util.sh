#!/bin/bash

CUR_DIR=$(dirname "$0")

echo_and_eval () {
    echo "$@"
    eval "$@"
}

get_freedesktop_color_scheme () {
    gsettings get org.freedesktop.appearance color-scheme
}

set_freedesktop_color_scheme () {
    gsettings set org.freedesktop.appearance color-scheme "$1"
}

toggle_freedesktop_color_scheme () {
    [[ "$1" == "dark" ]] && scheme="prefer-dark" || scheme="prefer-light"
    set_freedesktop_color_scheme "$scheme"
}

get_gnome_color_scheme () {
    gsettings get org.gnome.desktop.interface color-scheme
}

set_gnome_color_scheme () {
    gsettings set org.gnome.desktop.interface color-scheme "$1"
}

toggle_gnome_color_scheme () {
    [[ "$1" == "dark" ]] && scheme="prefer-dark" || scheme="prefer-light"
    set_gnome_color_scheme "$scheme"
}

get_gtk_theme () {
    gsettings get org.gnome.desktop.interface gtk-theme
}

set_gtk_theme () {
    gsettings set org.gnome.desktop.interface gtk-theme "$1"
}

toggle_gtk_theme () {
    [[ "$1" == "dark" ]] && mode="prefer-dark" || mode="prefer-light"
    set_gtk_theme "$mode"
}

toggle_gnome_dark () {
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"
    gsettings set org.gnome.desktop.interface icon-theme "Yaru-dark"
}

toggle_gnome_light () {
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru-light"
    gsettings set org.gnome.desktop.interface icon-theme "Yaru-light"
}

toggle_gnome () {
    echo_and_eval "toggle_gnome_$1"
    gsettings set org.gnome.desktop.interface text-scaling-factor 1.5
    gsettings set org.gnome.desktop.interface cursor-theme "Yaru"
    gsettings set org.gnome.desktop.interface cursor-size 48
    mkdir -p "$HOME/.icons/default"
    printf '[Icon Theme]\nInherits=Yaru\n' > "$HOME/.icons/default/index.theme"
    xsetroot -xcf /usr/share/icons/Yaru/cursors/left_ptr 48 2>/dev/null
}

toggle_i3 () {
    bash "$HOME/.local/bin/i3_update_config" $1
    i3 restart
}

toggle_sway () {
    bash "$HOME/.local/bin/sway_update_config" $1
    sway reload
}

toggle_desktop () {
    if [[ "$XDG_CURRENT_DESKTOP" == "i3" ]]; then
        echo "toggle gnome => $1"
        toggle_gnome "$1"
        echo "toggle i3 => $1"
        toggle_i3 "$1"
    elif [[ "$XDG_CURRENT_DESKTOP" == "sway" ]]; then
        echo "toggle gnome => $1"
        toggle_gnome "$1"
        echo "toggle sway => $1"
        toggle_sway "$1"
    else
        echo "toggle gnome => $1"
        toggle_gnome "$1"
    fi
}
