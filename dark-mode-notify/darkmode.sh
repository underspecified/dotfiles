#!/bin/bash

CUR_DIR=$(dirname $0)
CONFIG_DIR=$(realpath "$CUR_DIR/../config")
LOG_DIR=$(realpath "$CUR_DIR/../log")

echo_and_eval () {
    echo "$@"
    eval "$@"
}

toggle_alfred () {
    osascript -l JavaScript "-" $1 <<- EOF

function run(args) {
   	const alfred = Application("Alfred 5")
    const alfredDarkTheme = "Selenized Dark"
    const alfredLightTheme = "Selenized Light"
    const alfredTheme = args == "dark" ? alfredDarkTheme : alfredLightTheme
    alfred.setTheme(alfredTheme)
}

EOF
}

toggle_borders () {
    echo_and_eval "$CONFIG_DIR/borders/bordersrc_$1"
}

toggle_kitten () {
    [[ "$1" == "dark" ]] && theme="Selenized Dark" || theme="Selenized Light"
     echo_and_eval "/opt/homebrew/bin/kitten themes \
        --config-file-name=$CONFIG_DIR/kitty/themes.conf \
        --reload-in=all \
        $theme"
    #echo_and_eval "/opt/homebrew/bin/kitten @ load-config --to unix:/tmp/mykitty"
}

toggle_pdf_expert () {
    osascript -l JavaScript "-" $1 <<- EOF >/dev/null

function run(args) {
    const se = Application("System Events")
    const process = se.processes.whose({ name: "PDF Expert" })
    if (process.length > 0) {
        const viewMenu = process[0].menuBars[0].menuBarItems.byName("View")
        const themeMenuItem = viewMenu.menus[0].menuItems.byName("Theme")
        const theme = args == "dark" ? "Night" : "Day"
        themeMenuItem.menus[0].menuItems.byName(theme).click()
    }
}

EOF
}

toggle_zed () {
    echo_and_eval sed -i.bak -r 's/"mode": ".+"/"mode": "'$1'"/' \
        "$CONFIG_DIR/zed/settings.json"
}

echo "DARKMODE: $DARKMODE"|
tee -a "$LOG_DIR/darkmode.log" 2>&1

if [[ -n ${DARKMODE+x} ]]; then
    [[ $DARKMODE == "1" ]] && mode="dark" || mode="light"
    #toggle_zed $mode
    (toggle_borders $mode
    toggle_kitten $mode
    toggle_pdf_expert $mode
    toggle_alfred $mode) |
    tee -a "$LOG_DIR/darkmode.log" 2>&1
fi
