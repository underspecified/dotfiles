#!/usr/bin/env bash
# Usage: sudo bash ~/.config/lnk/installers/linux/display_fix_files/install_slock.sh
#
# Install slock (suckless simple X display locker) from the Ubuntu
# universe archive. Slock is a ~300-line C program and the Ubuntu
# package is the unmodified upstream build.
#
# This installer does NOT modify the i3 config or remove i3lock-color.
# Activate slock by editing linux.lnk/.config/i3/conf/system.conf to
# point $screensaver and $locker at the slock scripts (see system.conf
# comments for the toggle block).
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[slock] not root, re-executing under sudo..." >&2
    exec sudo -E bash "$0" "$@"
fi

log() { printf '[slock] %s\n' "$*"; }

log "installing slock package..."
apt-get update -q
apt-get install -y slock

# xautolock is already pulled in by install_i3.sh, but make sure.
# start_screensaver_slock depends on it for idle detection.
log "ensuring xautolock is installed..."
apt-get install -y xautolock

log "installed:"
dpkg --list slock xautolock 2>/dev/null \
    | awk '/^ii/ {printf "  %s  %s\n", $2, $3}' || true

cat <<'EOF'

[slock] slock installed.

Activation steps (do these manually; the installer does not touch your
dotfiles):

  1. Edit ~/.config/i3/conf/system.conf (symlinked from
     ~/.config/lnk/linux.lnk/.config/i3/conf/system.conf).

     In the "### lock screen" section, comment out the i3lock block
     and uncomment the slock block:

         #set $screensaver $HOME/.local/bin/start_screensaver_xautolock
         #set $locker      $HOME/.local/bin/lock_screen_i3lock

         set $screensaver $HOME/.local/bin/start_screensaver_slock
         set $locker      $HOME/.local/bin/lock_screen_slock

  2. Reload i3: $mod+Shift+c

  3. Kill any running xss-lock + i3lock from the previous session:
         pkill -x xss-lock
         pkill -x i3lock

  4. The new screensaver script starts automatically on i3 reload.

  5. Test manual lock: $mod+l     (should immediately show a black screen)
     Test idle lock: wait LOCK_MIN minutes (default 5 in
     start_screensaver_slock).

To revert:
  - Flip the i3 config block back to i3lock.
  - Reload i3.
  - (Optional) sudo bash ~/.config/lnk/installers/linux/display_fix_files/remove_slock.sh

slock color customization requires recompiling config.h (suckless
convention). The Ubuntu-packaged defaults are black/blue/red, which
are sensible.
EOF
