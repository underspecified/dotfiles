#!/usr/bin/env bash

CUR_DIR=$(dirname $0)
CONFIG_DIR=$(realpath "$CUR_DIR/../../config")
LOG_DIR=$(realpath "$CUR_DIR/../../log")

echo_and_eval () {
    echo "$@"
    eval "$@"
}

get_macos_mode () {
    osascript -l JavaScript <<- EOF

function run(args) {
    const systemEvents = Application("System Events")
	return systemEvents.appearancePreferences.darkMode() ? "dark" : "light"
}

EOF
}

toggle_macos_mode () {
    osascript -l JavaScript "-" $1 <<- EOF

function run(args) {
	const systemEvents = Application("System Events")
	const darkMode = args == "dark" ? true : false
	systemEvents.appearancePreferences.darkMode = darkMode
}

EOF
}

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
