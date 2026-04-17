#!/usr/bin/env bash
# Usage: sudo bash ~/.config/lnk/installers/linux/display_fix_files/install_hwe_kernel.sh
#
# Install the Ubuntu 24.04 HWE (Hardware Enablement) kernel.
#
# WHY: The base 24.04 kernel (6.8) is missing the i915 fast-wake/ALPM fix
# series that landed in mainline ~6.9 and was backported to linux-oem-6.8
# 1004.4. If Stage A of the display-fix still leaves DPMS-wake freezes
# after applying, HWE 6.11+ carries the relevant atomic-path fixes.
#
# HWE is shipped in Canonical's MAIN archive -- not a PPA. It's the
# same backport mechanism 22.04 used to get 6.8. Officially supported
# through end of 24.04 standard support.
#
# CAVEAT: linux-generic-hwe-24.04 is a META-PACKAGE that rolls forward
# to newer upstream kernels every ~6 months. For production stability
# on a compute box, consider PINNING a specific kernel image after
# install (see notes at end of script).
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[hwe-kernel] not root, re-executing under sudo..." >&2
    exec sudo -E bash "$0" "$@"
fi

log() { printf '[hwe-kernel] %s\n' "$*"; }

log "current kernel: $(uname -r)"
log "checking HWE candidate version..."
apt-cache policy linux-generic-hwe-24.04 | sed -n '1,5p'

log "updating apt package index..."
apt-get update -q

log "installing linux-generic-hwe-24.04 meta-package..."
apt-get install -y linux-generic-hwe-24.04

log "HWE kernel installed. Current installed kernels:"
dpkg --list 'linux-image-*' 2>/dev/null \
    | awk '/^ii/ && $2 ~ /linux-image-[0-9]/ {print "  " $2}' || true

cat <<'EOF'

[hwe-kernel] HWE kernel installed.

>>> REBOOT REQUIRED to boot the new kernel. <<<

After reboot, verify: uname -r  (should show the newer HWE version)

-----------------------------------------------------------------------
Pinning for stability (RECOMMENDED for a compute workstation)
-----------------------------------------------------------------------
The 'linux-generic-hwe-24.04' meta-package rolls forward automatically
every ~6 months. To pin a specific kernel and stop the rolling upgrade:

  # 1. Find the exact image you're running:
  dpkg --list 'linux-image-6*-generic' | awk '/^ii/ {print $2}'

  # 2. Add an apt hold for the meta-package and the image+headers you
  #    want to pin (example with 6.17.0-20):
  sudo apt-mark hold linux-generic-hwe-24.04 \
                     linux-image-generic-hwe-24.04 \
                     linux-headers-generic-hwe-24.04 \
                     linux-image-6.17.0-20-generic \
                     linux-headers-6.17.0-20-generic

  # 3. To release the hold later:
  sudo apt-mark unhold <package-name>

You can also pin via /etc/apt/preferences.d/ with Pin-Priority values
if you prefer apt priority policy over apt-mark holds.

-----------------------------------------------------------------------
To revert to the base GA kernel:
-----------------------------------------------------------------------
  sudo apt-get install linux-generic
  sudo apt-get autoremove --purge linux-generic-hwe-24.04 \
                                  'linux-image-6.1[0-9]*-generic' \
                                  'linux-headers-6.1[0-9]*-generic'
  # then reboot and select the GA kernel from the GRUB boot menu
EOF
