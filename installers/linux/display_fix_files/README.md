# display-fix — i3lock freeze fixes

Install/remove scripts and config files for the stages of the
i3lock-freeze-on-idle fix. The directory tree under `etc/` mirrors the
target layout in `/etc/`; `install_display_fix.sh` copies each file to
its matching destination.

## Layout

```
display_fix_files/
├── README.md                 (this file)
├── install_display_fix.sh    Stage A apply (display + input + logind)
├── remove_display_fix.sh     Stage A revert
├── install_slock.sh          Stage C apply (slock trial)
├── remove_slock.sh           Stage C revert
├── install_hwe_kernel.sh     Stage D (HWE kernel — last resort)
└── etc/                      config file tree mirroring /etc/
    ├── modprobe.d/blacklist-nouveau-display-fix.conf
    ├── default/grub.d/99-display-fix.cfg
    ├── X11/xorg.conf.d/
    │   ├── 10-intel-primary.conf
    │   └── 00-keyboard.conf
    ├── sysctl.d/99-sysrq.conf
    └── systemd/logind.conf.d/99-no-sleep.conf
```

## Scope of Stage A — DISPLAY AND INPUT SIDE ONLY

Stage A deliberately does **not** touch the NVIDIA driver stack.
Earlier iterations did (via a `zz-nvidia-compute.conf` modprobe file
that set `NVreg_DynamicPowerManagement=0x02`, blacklisted nvidia-drm,
and added `nvidia-drm.modeset=0 fbdev=0` to the kernel cmdline). That
version broke the GPU on this host — `nvidia-smi` failed with "Unable
to determine the device handle" and a GPU test crashed the system.
Root cause was the aggressive PCIe D3cold setting; the blacklist is
also untested on 580-open (Blackwell).

Changes the current Stage A **does** make:

| Layer | Change | Can it affect NVIDIA? |
|---|---|---|
| Intel i915 module | `i915.enable_psr=0 i915.enable_fbc=0` kernel cmdline | **No** — namespaced per module; i915 binds to Intel PCI devices only |
| Xorg userspace | `10-intel-primary.conf` pinning modesetting as PrimaryGPU | **No** — X config, no kernel impact |
| Xorg userspace | `00-keyboard.conf` pinning XKB layout | **No** — input layer |
| Kernel sysctl | `kernel.sysrq = 1` | **No** — kernel feature gate |
| systemd-logind | `99-no-sleep.conf` ignore power/suspend/lid/idle | **No** — userspace daemon |
| systemd | `mask sleep.target suspend.target ...` | **No** — systemd unit state |
| modprobe | `blacklist nouveau` | **No** — nouveau was already not loaded |

## What each failure mode this version of Stage A actually addresses

From the analysis in `../../../i3lock_troubleshooting.md`:

| Mode | Manifestation | Stage A coverage |
|---|---|---|
| F1   | Frozen screen after idle                   | Partial — disables i915 PSR/FBC wake paths. Does NOT disable nvidia-drm anymore (out of scope). If F1 persists, escalate via Stage D (HWE kernel backports) rather than touching NVIDIA. |
| F3   | Keyboard dead after wake                   | Fully — sleep targets are masked, so there's no suspend/resume path for libinput to wedge on. XKB is also pinned at the Xorg layer. |
| —    | Unrecoverable wedges defeat REISUB         | Fully — `kernel.sysrq = 1` enables the full command set. |

F2 (lock screen never draws) is handled by Stage C (slock trial).

## File inventory

| File | Purpose |
|------|---------|
| `etc/modprobe.d/blacklist-nouveau-display-fix.conf` | Defensive: pin nouveau in the unloaded state (was already not loaded pre-install). |
| `etc/default/grub.d/99-display-fix.cfg`             | GRUB drop-in appending `i915.enable_psr=0 i915.enable_fbc=0` to `GRUB_CMDLINE_LINUX_DEFAULT`. Drop-in format avoids editing the primary file. |
| `etc/X11/xorg.conf.d/10-intel-primary.conf`         | Pin Xorg's primary GPU to the Intel iGPU via modesetting. |
| `etc/X11/xorg.conf.d/00-keyboard.conf`              | Pin XKB layout (`us`, `pc105`) so it survives libinput device re-enumeration (freedesktop bug 71168). |
| `etc/sysctl.d/99-sysrq.conf`                        | `kernel.sysrq = 1` for full SysRq (Ubuntu's default 176 excludes the R/E/I bits needed for REISUB). |
| `etc/systemd/logind.conf.d/99-no-sleep.conf`        | Ignore power/suspend/hibernate keys, lid switch, and idle action. Paired with `systemctl mask` on all sleep targets by the installer. |

## Apply / revert

```bash
# apply (requires reboot)
sudo bash ~/.config/lnk/installers/linux/display_fix_files/install_display_fix.sh

# revert (requires reboot)
sudo bash ~/.config/lnk/installers/linux/display_fix_files/remove_display_fix.sh
```

Both scripts are idempotent. The revert also cleans up artefacts from
the earlier (withdrawn) NVIDIA-touching version of the installer, so a
single `remove_display_fix.sh` restores vendor-default state on
machines that had either version installed.

## Post-apply verification

After rebooting, confirm the changes landed and the GPU is healthy:

```bash
cat /proc/cmdline                   # contains i915.enable_psr=0 i915.enable_fbc=0
                                    # does NOT contain nvidia-drm.* params
cat /proc/sys/kernel/sysrq          # prints '1'
systemctl is-enabled sleep.target   # prints 'masked'
nvidia-smi                          # lists GPU normally, no errors
lsmod | grep -E '^nvidia'           # vendor default: nvidia, nvidia_uvm,
                                    # nvidia_modeset, nvidia_drm all loaded
```

The NVIDIA-G0/G1 Sink Output providers in `xrandr --listproviders`
remain visible — removing them would require NVIDIA-side changes
that are out of scope.

## Why not edit `/etc/default/grub` directly?

Ubuntu's `/etc/default/grub.d/*.cfg` is sourced by `update-grub` AFTER
`/etc/default/grub`, so appending to `GRUB_CMDLINE_LINUX_DEFAULT` in a
drop-in is cleaner than `sed`'ing the primary file. Revert is simply
`rm /etc/default/grub.d/99-display-fix.cfg && update-grub`, with zero
risk of corrupting the primary.
