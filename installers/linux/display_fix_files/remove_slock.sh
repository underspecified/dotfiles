#!/usr/bin/env bash
# Usage: sudo bash ~/.config/lnk/installers/linux/display_fix_files/remove_slock.sh
#
# Remove the slock package. Does NOT modify the i3 config -- if slock
# is currently the active locker, switch back to i3lock-color FIRST by
# editing linux.lnk/.config/i3/conf/system.conf, then run this.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[slock-revert] not root, re-executing under sudo..." >&2
    exec sudo -E bash "$0" "$@"
fi

log() { printf '[slock-revert] %s\n' "$*"; }

log "removing slock package..."
apt-get remove -y slock

# xautolock stays installed -- it may still be wanted for other reasons
# and is pulled in by the i3 base install anyway.

cat <<'EOF'

[slock-revert] slock removed.

The slock user scripts (~/.local/bin/lock_screen_slock and
start_screensaver_slock) remain on disk -- they are lnk-managed
symlinks. They're harmless when slock is not installed (the scripts
will just fail with "slock: command not found" if invoked).

If you want to also delete the user scripts: remove the entries from
~/.config/lnk/.lnk.linux and run `lnk sync` or edit the manifest by
hand.
EOF
