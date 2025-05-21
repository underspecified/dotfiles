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

get_gnome_mode () {
    if [[ `(get_gnome_color_scheme || get_gtk_theme) | grep -i 'dark'` ]]; then
        echo "dark"
    else
        echo "light"
    fi
}

get_i3_mode () {
    grep -i 'set \$mode ' ~/git/dotfiles/config/i3/config |
    awk '{print $3}'
}

call_geoloc_api () {
    curl -s "http://ipwho.is/"
}

get_lat () {
    call_geoloc_api |
    jq -r '.latitude'
}

get_lng () {
    call_geoloc_api |
    jq -r '.longitude'
}

get_tzid () {
    call_geoloc_api |
    jq -r '.timezone.id'
}

call_sun_api_ () {
    lat=$(get_lat)
    lng=$(get_lng)
    tzid=$(get_tzid)
    curl -s "https://api.sunrise-sunset.org/json?lat=$lat&lng=$lng&tzid=$tzid&formatted=0"
}

heliocron_here () {
    lat=$(get_lat)
    lng=$(get_lng)
    $HOME/.cargo/bin/heliocron --latitude $lat --longitude $lng $@
}

get_sunrise () {
    get_sunrise_date |
    xargs -I '{}' date "+%H:%M" --date='{}'
}

get_sunset () {
    get_sunset_date |
    xargs -I '{}' date "+%H:%M" --date='{}'
}

is_day () {
    sunrise=$(get_sunrise)
    sunset=$(get_sunset)
    now=$(date -Iseconds)
    [[ $sunrise < $now && $now < $sunset ]]
}

is_night () {
    [[ ! is_day ]]
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

get_winid () {
    xwininfo -root -tree |
    grep -i "$@" |
    head -1 |
    awk '{print $1}'
}

focus_window () {
    echo "focus_window: $@"
    winid=$(get_winid "$@")
    echo "win_id: \"$winid\""
    echo_and_eval xdotool windowactivate $winid
    echo_and_eval xdotool windowfocus $winid
}

toggle_firefox () {
    echo "toggle firefox => $1"
    (pgrep -fl "firefox" >/dev/null && \
     focus_window '("Navigator" "firefox")' && \
     xdotool key "alt+shift+d")
    #focus_window '("kitty" "kitty")'
}

toggle_google_chrome () {
    echo "toggle google chrome => $1"
    (pgrep -fl "chrome" >/dev/null && \
     focus_window '("google-chrome" "Google-chrome")' && \
     xdotool key "alt+shift+d")
    #focus_window '("kitty" "kitty")'
}

toggle_browser () {
    echo "toggle browser => $1"
    toggle_color_scheme "$1" || \
    (toggle_google_chrome "$1"
     toggle_firefox "$1")
}

toggle_env () {
    source "$HOME/git/dotfiles/config/i3/themes/selenized_$1.env"
}

toggle_gnome () {
    echo_and_eval "toggle_gnome_$1"
}

toggle_i3status () {
    cp $HOME/git/dotfiles/config/i3status/themes/i3staus-selenized-$1.config \
       $HOME/git/dotfiles/config/i3status/config
}

toggle_i3 () {
    $HOME/git/dotfiles/config/i3/bin/i3_update_config $1
    #toggle_i3status
    i3 restart
}

toggle_kitty () {
    echo "toggle kitty => $1"
    [[ "$1" == "dark" ]] && theme="Selenized Dark" || theme="Selenized Light"
    echo_and_eval kitten themes --config-file-name=themes.conf --reload-in=all "$theme"
}

toggle_regolith () {
    [[ "$1" == "dark" ]] && theme="selenized-dark" || theme="selenized-light"
    regolith-look set "$theme" &>/dev/null
}

toggle_sway () {
    sed -i.bak -r 's/set \$mode .+/set \$mode '$1'/' \
        $HOME/git/dotfiles/config/sway/config
    sway reload
}

toggle_zed () {
    sed -i.bak -r 's/"mode": ".*"/"mode": "'$1'"/' \
        $HOME/git/dotfiles/config/zed/settings.json
    #sleep 1
    #zed $HOME/git/dotfiles/config/zed/settings.json
}

toggle_desktop () {
    # echo "toggle env => $1"
    # toggle_env $1
    #if [[ "$XDG_CURRENT_DESKTOP" == "ubuntu:GNOME" ]]; then
        echo "toggle gnome => $1"
        toggle_gnome $1
    if [[ "$XDG_CURRENT_DESKTOP" == "i3" ]]; then
        echo "toggle i3 => $1"
        toggle_i3 $1
    elif [[ "$XDG_CURRENT_DESKTOP" == "Regolith" ]]; then
        echo "toggle regolith => $1"
        toggle_regolith $1
    elif [[ "$XDG_CURRENT_DESKTOP" == "sway" ]]; then
        echo "toggle sway => $1"
        toggle_sway $1
    fi
}
