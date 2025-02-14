#!/bin/bash

CUR_DIR=$(dirname "$0")

echo_and_eval () {
    echo "$@"
    eval "$@"
}

get_gnome_mode () {
    (gsettings get org.gnome.desktop.interface color-scheme |
     grep -i dark) >/dev/null && \
    echo "dark" || echo "light"
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

call_sun_api_() {
    lat=$(get_lat)
    lng=$(get_lng)
    tzid=$(get_tzid)
    curl -s "https://api.sunrise-sunset.org/json?lat=$lat&lng=$lng&tzid=$tzid&formatted=0"
}

heliocron_here() {
    lat=$(get_lat)
    lng=$(get_lng)
    $HOME/.cargo/bin/heliocron --latitude $lat --longitude $lng $@
}

get_sunrise_date () {
    heliocron_here report --json |
    jq -r '.sunrise'
}

get_sunrise () {
    get_sunrise_date |
    xargs -I '{}' date "+%H:%M" --date='{}'
}

get_sunset_date () {
    heliocron_here report --json |
    jq -r '.sunset' #|
}

get_sunset () {
    get_sunset_date |
    xargs -I '{}' date "+%H:%M" --date='{}'
}

is_day () {
    sunrise=$(get_sunrise_date)
    sunset=$(get_sunset_date)
    now=$(date -Iseconds)
    [[ $sunrise < $now && $now < $sunset ]]
}

is_night () {
    [[ ! is_day ]]
}

toggle_gnome_dark () {
    #gsettings get org.gnome.desktop.interface gtk-theme |
    #sed 's/light/dark/; s/Light/Dark/' |
    #xargs gsettings set org.gnome.desktop.interface gtk-theme
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
}

toggle_gnome_light () {
    #gsettings get org.gnome.desktop.interface gtk-theme |
    #sed 's/dark/light/; s/Dark/Light/' |
    #xargs gsettings set org.gnome.desktop.interface gtk-theme
    gsettings set org.gnome.desktop.interface color-scheme default
}

focus_window () {
    win_id=$(xwininfo -root -tree |
             grep "$@" |
             awk '{print $1}')R
    xdotool windowactivate $win_id
    xdotool windowfocus $win_id
}

toggle_firefox () {
    focus_window '("Navigator" "firefox")'
    xdotool key "alt+shift+d"
    focus_window '("kitty" "kitty")'
}

toggle_gnome () {
    [[ "$1" == "dark" ]] && toggle_gnome_dark || toggle_gnome_light
}

toggle_i3 () {
    sed -i.bak -r 's/set \$mode .+/set \$mode '$1'/' \
        ~/git/dotfiles/config/i3/config
    i3 restart
}

toggle_kitten () {
    [[ "$1" == "dark" ]] && theme="Selenized Dark" || theme="Selenized Light"
    /home/eric/.local/bin/kitten themes \
        --config-file-name=themes.conf \
        --reload-in=all "$theme"
}

toggle_regolith () {
    [[ "$1" == "dark" ]] && theme="selenized-dark" || theme="selenized-light"
    regolith-look set "$theme" &>/dev/null
}

toggle_sway () {
    sed -i.bak -r 's/set \$mode .+/set \$mode '$1'/' \
        ~/git/dotfiles/config/sway/config
    sway reload
}

toggle_zed () {
    sed -i.bak -r 's/"mode": ".+"/"mode": "'$1'"/' \
        ~/git/dotfiles/config/zed/settings.json
    #touch ~/git/dotfiles/config/zed/settings.json
}
