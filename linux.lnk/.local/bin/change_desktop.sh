#!/bin/bash

set -euo pipefail

CUR_DIR="$(dirname "$0")"
# shellcheck source=/dev/null
. "${CUR_DIR}/util.sh"


toggle_mode () {
    [[ $(darkman get) = "light" ]] && echo "dark" || echo "light"
}

[[ "${1:-}" = "toggle" ]] && mode=$(toggle_mode) || mode="${1:-}"

toggle_desktop "$mode"

# Claude Code (TUI theme + claude-limitline statusline) follows the same flip.
# Explicit mode is passed, so toggle_claude_theme never has to detect the OS.
# Best-effort: a Claude theme hiccup must not fail the desktop flip.
bash "${HOME}/.local/bin/toggle_claude_theme" "$mode" --push || true
