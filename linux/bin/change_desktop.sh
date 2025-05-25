#!/bin/bash

CUR_DIR=$(dirname $0)
. "$CUR_DIR/util.sh"


flip_mode () {
    [[ $(darkman get) = "light" ]] && echo "dark" || echo "light"
}
mode=${1:-$(flip_mode)}

toggle_desktop $mode
#toggle_browser $mode
#toggle_kitty $mode
#toggle_zed $mode
