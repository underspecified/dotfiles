#!/bin/bash

CUR_DIR=$(dirname $0)
. "$CUR_DIR/util.sh"

curr=$(get_gnome_mode)
if [[ $1 == "dark" ]]; then
    mode="dark"
elif [[ $1 == "light" ]]; then
    mode="light"
else
    [[ $curr == "light" ]] && mode="dark" || mode="light"
fi
echo "theme: $curr => $mode"

if [[ $curr != $mode ]]; then
    #toggle_firefox $mode
    toggle_gnome $mode
    #toggle_i3 $mode
    toggle_regolith $mode
    toggle_kitten $mode
    toggle_zed $mode
fi
