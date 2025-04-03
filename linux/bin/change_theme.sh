#!/bin/bash

CUR_DIR=$(dirname $0)
. "$CUR_DIR/util.sh"

curr=$(get_gnome_mode)
if [[ "$1" = "dark" ]]; then
    mode="dark"
elif [[ "$1" = "light" ]]; then
    mode="light"
elif [[ "$1" = "auto" ]]; then
    is_day && mode="light" || mode="dark"
else
    [[ "$curr" = "light" ]] && mode="dark" || mode="light"
fi
echo "[$(date '+%Y/%m/%d %H:%M:%S')] theme: $curr => $mode"

toggle_desktop $mode
toggle_browser $mode
toggle_kitty $mode
toggle_zed $mode
