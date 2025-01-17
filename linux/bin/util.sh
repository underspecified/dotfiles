#!/bin/bash

CUR_DIR=$(dirname "$0")
PATH="/home/eric/.local/bin:$PATH"

get_gnome_mode () {
    (gsettings get org.gnome.desktop.interface gtk-theme |
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
    bash "$CUR_DIR/heliocron_here.sh" "$@"
}

get_sunrise () {
    heliocron_here report --json |
    jq -r '.sunrise' #|
    #xargs -I '{}' date "+%H:%M" --date='{}'
}

get_sunset () {
    heliocron_here report --json |
    jq -r '.sunset' #|
    #xargs -I '{}' date "+%H:%M" --date='{}'
}

is_day () {
    sunrise=$(get_sunrise)
    sunset=$(get_sunset)
    now=$(date -Iseconds)
    [[ $sunrise < $now ]] && [[ $now < $sunset ]]
}

is_night () {
    ! [[ is_day ]]
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

focus_window () {
    win_id=$(xwininfo -root -tree |
             grep "$@" |
             awk '{print $1}')
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
    sed -i.bak -r 's/set \$mode = .+/set \$mode = '$1'/' \
        ~/git/dotfiles/config/i3/config
    i3 restart
}

toggle_kitten () {
    [[ "$1" == "dark" ]] && theme="Selenized Dark" || theme="Selenized Light"
    kitten themes --config-file-name=themes.conf --reload-in=all "$theme"
}

toggle_regolith () {
    [[ "$1" == "dark" ]] && theme="selenized-dark" || theme="selenized-light"
    regolith-look set "$theme" &>/dev/null
}

toggle_zed () {
    sed -i.bak -r 's/"mode": ".+"/"mode": "'$1'"/' \
        ~/git/dotfiles/config/zed/settings.json
    sleep 1
    touch ~/git/dotfiles/config/zed/settings.json
}
