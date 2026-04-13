#!/usr/bin/env bash
# Usage: bash installers/linux/install_usb_autosuspend.sh
# Disables USB autosuspend on desktop systems to prevent keyboard/mouse freezes
# after long periods of screen-off time.
set -euo pipefail

MODPROBE_FILE="/etc/modprobe.d/usb-autosuspend.conf"
UDEV_FILE="/etc/udev/rules.d/50-usb-power.rules"

echo "Writing ${MODPROBE_FILE}..."
sudo tee "${MODPROBE_FILE}" > /dev/null << 'EOF'
# Disable USB autosuspend globally on desktop systems.
# Prevents xHCI host controllers from autosuspending and freezing
# connected keyboards and mice during long screen-off periods.
options usbcore autosuspend=-1
EOF

echo "Writing ${UDEV_FILE}..."
sudo tee "${UDEV_FILE}" > /dev/null << 'EOF'
# Explicitly set USB root hubs (Linux Foundation, vendor 1d6b) to never
# autosuspend. Complements the modprobe default — udev applies at hotplug
# time so already-connected devices are covered without a reboot.
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1d6b", ATTR{power/control}="on"
EOF

echo "Reloading udev rules..."
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=usb --action=add

echo "Done. USB autosuspend disabled for host controllers."
echo "The modprobe setting takes full effect on next boot."
