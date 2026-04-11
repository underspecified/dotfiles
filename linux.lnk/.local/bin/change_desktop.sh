#!/bin/bash

set -euo pipefail

CUR_DIR=$(dirname "$0")
. "$CUR_DIR/util.sh"


toggle_mode () {
    [[ $(darkman get) = "light" ]] && echo "dark" || echo "light"
}

[[ "${1:-}" = "toggle" ]] && mode=$(toggle_mode) || mode="${1:-}"

toggle_desktop "$mode"
