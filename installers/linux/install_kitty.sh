#!/usr/bin/env bash
# Re-run = no-op once kitty is on PATH. The upstream installer overwrites
# configs and the sed -i steps re-patch already-patched .desktop files,
# so we gate the whole thing behind a presence check. Set KITTY_REINSTALL=1
# to force a re-run (e.g. to pick up a new upstream version).
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

install_kitty() {
    if command -v kitty >/dev/null 2>&1 && [[ -z "${KITTY_REINSTALL:-}" ]]; then
        log "kitty already installed; skipping (set KITTY_REINSTALL=1 to force)"
        return 0
    fi
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    # Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in
    # your system-wide PATH)
    symlink_force ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
    symlink_force ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten
    # Place the kitty.desktop file somewhere it can be found by the OS
    cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
    # If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file
    cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
    # Update the paths to the kitty and its icon in the kitty desktop file(s)
    sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
    sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
    # Make xdg-terminal-exec (and hence desktop environments that support it use kitty)
    echo 'kitty.desktop' > ~/.config/xdg-terminals.list
}

install_kitty
