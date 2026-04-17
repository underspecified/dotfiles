#!/usr/bin/env bash
# Usage: sudo bash ~/.config/lnk/installers/linux/display_fix_files/install_display_fix.sh
#
# Apply Stage A of the i3lock-freeze fix. The scope is deliberately
# narrow: DISPLAY and INPUT side only. This script NEVER touches the
# NVIDIA driver stack, NVIDIA kernel modules, NVIDIA module parameters,
# NVIDIA systemd services, or PCIe power management.
#
# Changes made:
#   - i915.enable_psr=0 i915.enable_fbc=0 in the kernel cmdline
#     (Intel display driver only; Intel-only PCI binding).
#   - /etc/X11/xorg.conf.d entries pinning modesetting as primary
#     and pinning XKB layout (Xorg userspace config).
#   - kernel.sysrq = 1 so REISUB works if the system wedges.
#   - /etc/systemd/logind.conf.d entry ignoring power/suspend/lid/idle
#     events, plus systemctl mask on the sleep/suspend/hibernate
#     targets (no sleep allowed on this GPU-experiment host).
#   - blacklist nouveau as defense-in-depth (nouveau was already not
#     loaded pre-install; this just pins that state).
#
# NOT in scope:
#   - No modifications to nvidia-drm, nvidia, nvidia-modeset module
#     parameters.
#   - No PCIe D3cold / aggressive runtime PM changes.
#   - No NVIDIA systemd service state changes.
#   - No module blacklist of anything NVIDIA.
#
# Idempotent -- safe to re-run. Reversible via remove_display_fix.sh.
# REBOOT REQUIRED after applying.
#
# See README.md in this directory for rationale and
# i3lock_troubleshooting.md in the repo root for the full analysis.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[display-fix] not root, re-executing under sudo..." >&2
    exec sudo -E bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '[display-fix] %s\n' "$*"; }

if [[ ! -d "${SCRIPT_DIR}/etc" ]]; then
    echo "[display-fix] config files directory not found: ${SCRIPT_DIR}/etc" >&2
    exit 1
fi

log "installing /etc/modprobe.d entries..."
install -D -m 0644 \
    "${SCRIPT_DIR}/etc/modprobe.d/blacklist-nouveau-display-fix.conf" \
    /etc/modprobe.d/blacklist-nouveau-display-fix.conf

log "installing GRUB drop-in (adds i915 params on next update-grub)..."
install -D -m 0644 \
    "${SCRIPT_DIR}/etc/default/grub.d/99-display-fix.cfg" \
    /etc/default/grub.d/99-display-fix.cfg

log "installing /etc/X11/xorg.conf.d entries..."
install -D -m 0644 \
    "${SCRIPT_DIR}/etc/X11/xorg.conf.d/10-intel-primary.conf" \
    /etc/X11/xorg.conf.d/10-intel-primary.conf
install -D -m 0644 \
    "${SCRIPT_DIR}/etc/X11/xorg.conf.d/00-keyboard.conf" \
    /etc/X11/xorg.conf.d/00-keyboard.conf

log "installing /etc/sysctl.d entry..."
install -D -m 0644 \
    "${SCRIPT_DIR}/etc/sysctl.d/99-sysrq.conf" \
    /etc/sysctl.d/99-sysrq.conf

log "installing /etc/systemd/logind.conf.d entry..."
install -D -m 0644 \
    "${SCRIPT_DIR}/etc/systemd/logind.conf.d/99-no-sleep.conf" \
    /etc/systemd/logind.conf.d/99-no-sleep.conf

log "masking all system-sleep targets (no suspend/hibernate on this host)..."
systemctl mask \
    sleep.target \
    suspend.target \
    hibernate.target \
    hybrid-sleep.target \
    suspend-then-hibernate.target

log "applying new sysctl settings live..."
sysctl -p /etc/sysctl.d/99-sysrq.conf >/dev/null

log "reloading systemd-logind config..."
# SIGHUP tells logind to re-read its config files without dropping
# user sessions (unlike `systemctl restart systemd-logind`, which
# would kill the current session).
systemctl kill -s HUP systemd-logind.service 2>/dev/null || true

log "rebuilding initramfs for all kernels..."
update-initramfs -u -k all

log "regenerating GRUB config..."
update-grub

cat <<'EOF'

[display-fix] Stage A applied successfully.

>>> REBOOT REQUIRED for all changes to take effect. <<<

After reboot, verify the fix landed:

  cat /proc/cmdline            # should contain i915.enable_psr=0 i915.enable_fbc=0
                               # should NOT contain any nvidia-drm.* params
  cat /proc/sys/kernel/sysrq   # should print '1'
  systemctl is-enabled sleep.target    # should print 'masked'
  nvidia-smi                   # should work normally (GPU listed, no errors)
  lsmod | grep -E '^nvidia'    # vendor default: nvidia, nvidia_uvm,
                               # nvidia_modeset, nvidia_drm all loaded

NOTE on xrandr: the NVIDIA-G0/G1 Sink Output providers WILL still
appear -- this version of Stage A does not attempt to remove them.
Removing them requires changes to the NVIDIA stack and those are
explicitly out of scope after the D3cold incident.

To revert:
  sudo bash ~/.config/lnk/installers/linux/display_fix_files/remove_display_fix.sh
EOF
