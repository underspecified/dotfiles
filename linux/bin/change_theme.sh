#!/bin/bash

toggle_mode () {
    [[ $(darkman get) = "light" ]] && echo "dark" || echo "light"
}

[[ $1 = "toggle" ]] && mode=$(toggle_mode) || mode=$1

darkman set $mode
