#!/bin/bash

CUR_DIR=$(dirname $0)
LOG_DIR="$HOME/tmp/"
PATH="$HOME/.local/bin:$PATH"

echo "DARKMODE: $DARKMODE"|
tee -a "$LOG_DIR/darkmode.log" 2>&1

if [[ -n ${DARKMODE+x} ]]; then
    [[ $DARKMODE == "1" ]] && mode="dark" || mode="light"
    (
        toggle_borders $mode
        toggle_pdf_expert $mode
        #toggle_rstudio $mode
    ) |
    tee -a "$LOG_DIR/darkmode.log" 2>&1
fi
