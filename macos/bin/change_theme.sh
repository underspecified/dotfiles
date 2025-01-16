#!/bin/bash

CUR_DIR=$(dirname $0)
CONFIG_DIR="$CUR_DIR/../../config"
PATH=$CONFIG_DIR/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH

toggle_alfred () {
    osascript -l JavaScript "-" $1 <<- EOF

function run(args) {
   	const systemEvents = Application("System Events")
   	const alfred = Application("Alfred 5")
    const alfredDarkTheme = "Selenized Dark"
    const alfredLightTheme = "Selenized Light"
    const alfredTheme = args == "dark" ? alfredDarkTheme : alfredLightTheme
    alfred.setTheme(alfredTheme)
}

EOF
}

toggle_borders () {
    bash "$CONFIG_DIR/borders/bordersrc_$1"
}

toggle_kitten () {
    [[ "$1" == "dark" ]] && theme="Selenized Dark" || theme="Selenized Light"
    kitten themes --config-file-name=themes.conf --reload-in=all "$theme"
}

get_macos_mode () {
    osascript -l JavaScript <<- EOF

function run(args) {
    const systemEvents = Application("System Events")
	return systemEvents.appearancePreferences.darkMode() ? "dark" : "light"
}

EOF
}

toggle_macos () {
    osascript -l JavaScript "-" $1 <<- EOF

function run(args) {
	const systemEvents = Application("System Events")
	const darkMode = args == "dark" ? true : false
	systemEvents.appearancePreferences.darkMode = darkMode
}

EOF
}

toggle_pdf_expert () {
    osascript -l JavaScript "-" $1 <<- EOF

function run(args) {
    const se = Application("System Events")
    const process = se.processes.whose({ name: "PDF Expert" })[0]
    const viewMenu = process.menuBars[0].menuBarItems.byName("View")
    const themeMenuItem = viewMenu.menus[0].menuItems.byName("Theme")
    const theme = args == "dark" ? "Night" : "Day"
    themeMenuItem.menus[0].menuItems.byName(theme).click()
}

EOF
}

toggle_zed () {
    sed -i.bak -r 's/"mode": ".+"/"mode": "'$1'"/' \
        ~/git/dotfiles/config/zed/settings.json
}

if [[ $1 == "dark" ]]; then
    mode="dark"
elif [[ $1 == "light" ]]; then
    mode="light"
elif [[ -z "${DARKMODE+x}" ]]; then
    [ $(get_macos_mode) == "light" ] && mode="dark" || mode="light"
    toggle_macos $mode
elif [[ "$DARKMODE" == "1" ]]; then
    mode="dark"
else
    mode="light"
fi
#echo "mode: $mode"

toggle_alfred $mode
toggle_borders $mode
toggle_kitten $mode
toggle_pdf_expert $mode
#toggle_zed $mode
