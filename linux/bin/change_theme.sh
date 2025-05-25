#!/bin/bash

flip_mode () {
    [[ $(darkman get) = "light" ]] && echo "dark" || echo "light"
}
mode=${1:-$(flip_mode)}

darkman set $mode
