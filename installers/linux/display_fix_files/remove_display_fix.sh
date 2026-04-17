#!/usr/bin/env bash
# Usage: sudo bash ~/.config/lnk/installers/linux/display_fix_files/remove_display_fix.sh
#
# Revert install_display_fix.sh and also clean up artefacts from the
# earlier (now-withdrawn) version that touched the NVIDIA stack. Safe
# to run whether the NVIDIA-touching version was ever installed or not.
#
#   - remove all installed config files under /etc/ (current + legacy)
#   - unmask sleep/suspend/hibernate targets
#   - restore default NVIDIA service state if any was changed by the
#     older version of the installer
#   - reload sysctl, re-run update-initramfs and update-grub
#
# Idempotent -- safe to re-run. REBOOT REQUIRED after reverting.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[display-fix] not root, re-executing under sudo..." >&2
    exec sudo -E bash "$0" "$@"
fi

log() { printf '[display-fix-revert] %s\n' "$*"; }

# Files installed by the current (safe) Stage A.
FILES=(
    /etc/modprobe.d/blacklist-nouveau-display-fix.conf
    /etc/default/grub.d/99-display-fix.cfg
    /etc/X11/xorg.conf.d/10-intel-primary.conf
    /etc/X11/xorg.conf.d/00-keyboard.conf
    /etc/sysctl.d/99-sysrq.conf
    /etc/systemd/logind.conf.d/99-no-sleep.conf
)

# Legacy file from the withdrawn NVIDIA-touching version. Kept here so
# a single revert cleans machines that have either version installed.
LEGACY_NVIDIA_CONF=/etc/modprobe.d/zz-nvidia-compute.conf

log "removing installed config files..."
for f in "${FILES[@]}"; do
    if [[ -f $f ]]; then
        rm -f "$f"
        log "  removed $f"
    fi
done

if [[ -f $LEGACY_NVIDIA_CONF ]]; then
    rm -f "$LEGACY_NVIDIA_CONF"
    log "  removed legacy NVIDIA conf: $LEGACY_NVIDIA_CONF"
fi

log "unmasking system-sleep targets..."
systemctl unmask \
    sleep.target \
    suspend.target \
    hibernate.target \
    hybrid-sleep.target \
    suspend-then-hibernate.target 2>/dev/null || true

# Restore default NVIDIA service state if the older installer changed it.
# Safe no-ops if the state is already default.
log "restoring default NVIDIA service state (if previously altered)..."
systemctl disable \
    nvidia-suspend.service \
    nvidia-resume.service \
    nvidia-hibernate.service 2>/dev/null || true
systemctl unmask nvidia-powerd.service 2>/dev/null || true

log "reloading sysctl from remaining config files..."
sysctl --system >/dev/null 2>&1 || true

log "reloading systemd-logind config..."
systemctl kill -s HUP systemd-logind.service 2>/dev/null || true

log "rebuilding initramfs for all kernels..."
update-initramfs -u -k all

log "regenerating GRUB config..."
update-grub

cat <<'EOF'

[display-fix-revert] Reverted.

>>> REBOOT REQUIRED for all changes to take effect. <<<

After reboot the system returns to its pre-Stage-A state:
  - i915 PSR/FBC re-enabled (vendor defaults)
  - No XKB or primary-GPU pin
  - Suspend/hibernate re-enabled
  - SysRq bitmask restored to distro default (usually 176)
  - NVIDIA driver stack fully at vendor default

To re-apply:
  sudo bash ~/.config/lnk/installers/linux/display_fix_files/install_display_fix.sh
EOF
