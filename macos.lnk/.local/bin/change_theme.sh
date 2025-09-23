#!/usr/bin/env bash

CUR_DIR=$(dirname $0)
CONFIG_DIR=$(realpath "$CUR_DIR/../../config")
LOG_DIR=$(realpath "$CUR_DIR/../../log")

curr=$(get_macos_mode)
if [[ $1 == "dark" ]]; then
    mode="dark"
elif [[ $1 == "light" ]]; then
    mode="light"
else
    [[ $curr == "light" ]] && mode="dark" || mode="light"
fi
echo "[$(date '+%Y/%m/%d %H:%M:%S')] theme: $curr => $mode" |
tee -a "$LOG_DIR/change_theme.log" 2>&1

if [[ $curr != $mode ]]; then
    toggle_macos_mode $mode | tee -a "$LOG_DIR/change_theme.log" 2>&1
fi
