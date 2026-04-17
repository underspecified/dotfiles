# i3wm screen locker alternatives for Ubuntu - Claude

*Extracted from Claude AI on 4/17/2026, 3:32:28 PM*

---

# Why your lock screen wedges on a hybrid Intel-display NVIDIA-compute box

**Your failure is a three-layer stack interaction, not one bug.** The NVIDIA driver still mediates system suspend even when it isn't driving the display, the i915 PSR/FBC paths on kernel 6.8 have wake-path regressions that manifest on desktop monitors (not just laptop eDP), and i3lock-color 2.13.c.5 is missing the upstream i3lock 2.16 XKB-reconfigure crash fix (October 2025) [GitHub](https://github.com/i3/i3lock/blob/main/CHANGELOG) plus a libinput Send-Events-Mode reset after resume that has no fix outside mutter. Each of your three symptoms maps to a different layer: **frozen screen = i915 DPMS wake**, **lock never draws = i3lock-color composite/redirect regression**, **dead keyboard = libinput device re-enumeration race plus X grab held on a now-dead device node**. The minimum-disruption fix path is four surgical kernel/modprobe changes plus either a fail-closed wrapper around i3lock-color or a migration to xsecurelock; you do not need to rearchitect the GPU stack.

## What the hardware configuration actually changes

Most forum advice assumes NVIDIA drives display (Optimus laptops, or desktops with the monitor in the dGPU port). Your topology — monitor physically cabled to the motherboard iGPU, NVIDIA loaded-but-not-displaying — inherits bugs from **both** sides and adds one of its own.

From the NVIDIA side: the driver still participates in system power management (its nv_pmops_suspend callback runs on every S3/DPMS-adjacent suspend event), which means NVIDIA suspend regressions can wedge the whole kernel PM state machine and the Intel display never re-modesets on resume. Documented mechanism in NVIDIA forum thread 300380 (555.58.02 page-fault on resume), [NVIDIA Developer Forums](https://forums.developer.nvidia.com/t/device-driver-crash-unable-to-handle-page-fault-after-suspend-resume-with-version-555-58-02-on-linux-kernel-v6-9-9/300380) thread 359173 ("Pageflip timed out! This is a bug in the nvidia-drm kernel driver" [NVIDIA Developer Forums](https://forums.developer.nvidia.com/t/590-48-01-no-display-after-wake-from-suspend-pageflip-timed-out-this-is-a-bug-in-the-nvidia-drm-kernel-driver/359173) on 590.48.01, January 2025), and Ubuntu LP #2065076: nv_pmops_suspend returns -5, [GitHub](https://gist.github.com/bmcbm/375f14eaa17f88756b4bdbbebbcfd029) dpm_suspend hangs, [GitHub +2](https://gist.github.com/bmcbm/375f14eaa17f88756b4bdbbebbcfd029) kworker stalls via global DRM refcounts, and rcu_sched eventually reports a stall. **NVreg_PreserveVideoMemoryAllocations=1 and nvidia-{suspend,resume,hibernate}.service are still required** because any live CUDA context — Jupyter kernel, Ollama, vLLM — will panic on resume without vidmem preservation, and the driver prints PreserveVideoMemoryAllocations module parameter is set. System Power Management attempted without driver procfs suspend interface [GitHub +4](https://github.com/NVIDIA/open-gpu-kernel-modules/issues/922) if the services aren't active (LP #2065076, open-gpu-kernel-modules #472).

From the i915 side: kernel 6.8's flip_done timed out and commit wait timed out signatures on DPMS wake are well-documented for this series. **drm/intel issue #10284 confirms unconditional intel_psr_init_dpcd() fires on non-eDP sinks**, producing AUX C/DDI C/PHY C: timeout (status 0x7d40023f) spam and boot/resume delays [GitLab](https://gitlab.freedesktop.org/drm/i915/kernel/-/issues/10284) on desktop DP monitors — your exact topology. LP #2065096 ("Display is Laggy/Unresponsive when PSR is enabled", noble 6.8.0-31) and LP #2062951 (Gen9 flickering, cured by i915.enable_dc=0 intel_idle.max_cstate=2) [Ubuntu](https://bugs.launchpad.net/bugs/2062951) complete the picture. The fast-wake/ALPM fix series landed in linux-oem-6.8 1004.4 [Ubuntu](https://bugs.launchpad.net/ubuntu/+source/linux-oem-6.5/+bug/2046315) and mainline ~6.9; whether your current -generic point release has the SRU backport is the difference between "works" and "needs i915.enable_psr=0".

The hybrid-specific bug is **nvidia-drm registering as a DRM provider when it isn't driving display**. With nvidia-drm.modeset=1 nvidia-drm.fbdev=1 (ArchWiki's current recommendation for the NVIDIA-drives-display case), [ArchWiki](https://wiki.archlinux.org/title/NVIDIA) nvidia-drm can present a phantom connector, steal the Xorg primary-provider role from modesetting/i915, and bind its (broken-on-resume) pageflip engine to your session even though no pixel is ever scanned out through it. Hyprland #8519 documents the inverse fix on kernel 6.11+ with 560 drivers: nvidia_drm.fbdev=0 cures the freeze. [GitHub](https://github.com/hyprwm/Hyprland/issues/8519) **For your CUDA-only workload the correct setting is nvidia-drm.modeset=0 nvidia-drm.fbdev=0**, which prevents nvidia-drm from loading at all. CUDA, cuBLAS, NCCL, NVENC, and Vulkan compute work fine without nvidia-drm; you lose only PRIME render offload (prime-run), Wayland EGLStreams, and nvidia-vaapi-driver — none of which you use.

## Kernel, modprobe, and systemd configuration

Apply these as a single coordinated change set. Each piece is independently justified above; combined they close the known hybrid-resume bug classes.

**/etc/modprobe.d/nvidia.conf**

# Hybrid desktop: Intel iGPU drives display, NVIDIA for CUDA only.
# Disable nvidia-drm entirely — prevents provider conflicts with i915
# and eliminates the pageflip-timeout-on-resume hang (NVIDIA t/359173).
options nvidia-drm modeset=0 fbdev=0

# Preserve vidmem across S3 for live CUDA contexts. /var/tmp, not /tmp
# (Ubuntu 24.04 mounts /tmp as tmpfs by default).
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp

# Aggressive runtime PM — PCIe D3cold when idle, safe on desktop RTX cards.
options nvidia NVreg_DynamicPowerManagement=0x02

Add blacklist nouveau to /etc/modprobe.d/blacklist-nouveau.conf and run sudo update-initramfs -u -k all. Ubuntu's nvidia-dkms hook rebuilds initramfs on driver upgrades but not on modprobe.d edits — the manual rebuild is mandatory.

**/etc/default/grub — GRUB_CMDLINE_LINUX_DEFAULT**

quiet splash i915.enable_psr=0 i915.enable_fbc=0 nvidia-drm.modeset=0 nvidia-drm.fbdev=0

i915.enable_psr=0 is **strongly recommended** for your desktop topology — PSR is an eDP power feature with zero benefit on external DP monitors and directly cures LP #2065096 and drm/intel #10284. i915.enable_fbc=0 is defensive (FBC wake artifacts on Gen9–Gen12) with negligible power cost. If hangs persist after the first tier, escalate to adding i915.enable_dc=0 intel_idle.max_cstate=2; both have measurable desktop idle-power cost so apply only on evidence. **Do not disable GuC** (i915.enable_guc=0) — mandatory on Xe-HP from Gen12, breaks HW video decode, and is not a DPMS fix.

**systemd unit state**

sudo systemctl unmask  nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
sudo systemctl enable  nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
sudo systemctl enable  nvidia-persistenced.service   # reduces CUDA init latency, fixes udev races
sudo systemctl mask    nvidia-powerd.service          # laptop-Optimus-only, counterproductive here

**/etc/X11/xorg.conf.d/10-intel-primary.conf** pins Xorg to the Intel DDX path; with nvidia-drm.modeset=0 this is belt-and-suspenders but forecloses edge cases where a future driver update re-enables modeset:

Section "OutputClass"
Identifier  "intel"
MatchDriver "i915"
Driver      "modesetting"
Option      "PrimaryGPU" "yes"
EndSection

Post-reboot verification: xrandr --listproviders must show **only** modesetting, lsmod | grep -E '^nvidia' must show nvidia and nvidia_uvm but **not** nvidia_drm or nvidia_modeset, and sudo dmesg | grep -iE 'nvrm|psr' must not contain the PreserveVideoMemoryAllocations module parameter is set error.

### Driver version matrix for 24.04

| Driver branch | Status on noble | Suspend behavior in 2024–2026 |
| --- | --- | --- |
| **535.216+ server** | nvidia-driver-535-serverin archive | **Safest choice.**Baseline LTS; works reliably with the services+PreserveVidMem combo. |
| 550.x | Initially default on 24.04 | Multiplenv_pmops_freeze/ D3hot→D0 regressions (t/327623). Avoid below 550.107. |
| 555.x | PPA only | **Broken.**Page-fault-on-resume (t/300380). Do not install. |
| 560.x | nvidia-driver-560via PPA/24.10 | Mixed. The Hyprland #8519 fbdev-flip affects some systems. |
| **570.x / 570-open** | Current 24.04 HWE | **Recommended for current hardware.**Required (open module) for RTX 50-series Blackwell.NVIDIA Developer Forums |

## Input-layer fixes — this is where your F3 lives

**Ubuntu LP #2087831 is the critical bug for your keyboard-dead symptom.** On systems with NVIDIA loaded, libinput's Send Events Mode Enabled property flips from 0,0 to 1,0 across the wake path [Launchpad](https://bugs.launchpad.net/oem-priority/+bug/2087831) because the NVIDIA driver briefly wakes the display during the suspend preamble [Launchpad](https://bugs.launchpad.net/oem-priority/+bug/2087831) and mutter mis-handles the resulting device re-enumeration. Root-caused fix shipped in mutter 46.2-1ubuntu0 [Launchpad](https://bugs.launchpad.net/oem-priority/+bug/2087831) (January 2025 noble SRU) — **i3 users do not get this fix** because i3 does not use the mutter code paths. Hyprland #5528 (kernel 6.8.4, AMD) and the Ubuntu Discourse lid-suspend reports (threads 64070, 74946) confirm this is a stack-wide libinput+kernel-6.8 issue that manifests regardless of compositor choice.

The concrete repair chain: first, pin XKB at the Xorg layer so it survives device re-seat:

# /etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
Identifier "system-keyboard"
MatchIsKeyboard "on"
Option "XkbLayout" "us"
Option "XkbOptions" "ctrl:nocaps"
EndSection

Setting layout per-session via setxkbmap alone is insufficient — freedesktop bug 71168 (open since 2013, closed Won't Fix) documents XKB settings being lost on resume; [FreeDesktop](https://bugs.freedesktop.org/show_bug.cgi?id=71168) the Xorg config file is recreated on every device re-enumeration event, setxkbmap output is not. Second, install a user systemd sleep-hook that reasserts libinput Send-Events-Mode on wake:

# ~/.config/systemd/user/resume-input-fix.service
[Unit]
Description=Reassert libinput Send Events Mode after resume
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for id in $(xinput list --id-only); do xinput set-prop $id "libinput Send Events Mode Enabled" 0 0 2>/dev/null || true; done'
Environment=DISPLAY=:0

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

Enable with systemctl --user enable resume-input-fix.service. As a diagnostic probe — not a long-term setting — temporarily switch the keyboard (only) to the evdev driver via /etc/X11/xorg.conf.d/90-keyboard-evdev.conf with Driver "evdev"; if the F3 wedge disappears, you have positive confirmation the blame is libinput, not the X server or the locker. Do not leave evdev in production — it is minimally maintained on Ubuntu 24.04.

## The locker decision — i3lock-color versus xsecurelock

**i3lock-color is effectively stalled.** Last release 2.13.c.5 was July 2023, [GitHub](https://github.com/Raymo111/i3lock-color/releases/tag/2.13.c.5) the v2.14.0 PR (#287) has been in draft for over two years, [GitHub](https://github.com/i3/i3lock/pull/300) issue #310 ("Is it the time for a new release?") [github](https://github.com/Raymo111/i3lock-color/issues)[GitHub](https://github.com/Raymo111/i3lock-color/issues) went unanswered, and twenty-five open issues sit un-triaged. More importantly, the fork does not carry **upstream i3lock 2.16's explicit fix for the XKB reconfiguration crash** (October 2025) — the single most relevant delta for post-resume input wedges. [GitHub](https://github.com/i3/i3lock/blob/main/CHANGELOG) Upstream 2.14.1's modifier-key scrubbing [GitHub](https://github.com/i3/i3lock/pull/300) and 2.15's keyboard-layout display [GitHub](https://github.com/i3/i3lock/blob/main/CHANGELOG) are also missing. Issue #174 (regression between 2.12.c.1 and 2.12.c.2: lock screen only renders once you start typing, cured by --composite) [github](https://github.com/Raymo111/i3lock-color/issues/174) matches the Arch forum threads 272785 and 297570 and was never cleanly resolved.

Your failure mode 2 ("lock screen never appears") maps almost exactly onto #174. **The --composite flag is a genuine fix, not a placebo**, and works on both Intel and NVIDIA GPUs because the underlying regression is a composite-redirect/overlay-window issue, not a GPU driver issue. Combine it with --ignore-empty-password [Arch Linux Forums](https://bbs.archlinux.org/viewtopic.php?id=297570) (skips PAM lockout-delay when wake delivers a stray Enter keypress) [Arch Linux Forums](https://bbs.archlinux.org/viewtopic.php?id=272785)[ManKier](https://www.mankier.com/1/i3lock) and --nofork (mandatory under xss-lock). Do not combine --composite with a running picom — issue #24 (flicker) [GitHub](https://github.com/Raymo111/i3lock-color/issues/24) and #294 (extreme lag) [github](https://github.com/Raymo111/i3lock-color/issues) are the documented pathologies of double-redirect. If picom is running, drop --composite and instead set unredir-if-possible = false in picom.conf plus an i3lock class exclusion.

The silent-exit race is real and security-relevant. If i3lock-color segfaults post-grab (OOM from slideshow leak #295, [github](https://github.com/Raymo111/i3lock-color/issues) XKB reconfigure crash that upstream fixed in 2.16, or XCB connection reset during suspend), xss-lock sees the child exit 0 and releases the sleep-lock FD — **system unlocks without authentication**. Mitigation is a fail-closed wrapper:

sh#!/bin/sh
# ~/bin/lock-wrap — fail-closed locker for xss-lock
i3lock-color --nofork --composite --ignore-empty-password --indicator \
--show-failed-attempts --color=1e1e2eff "$@" \
|| { logger -t lock-wrap "i3lock-color exited $?, forcing relock"; \
loginctl lock-session; sleep 30; kill -9 -1; }

Invoked as xss-lock -l --transfer-sleep-lock -- ~/bin/lock-wrap. The -l flag is mandatory per i3lock upstream PR #207 — it locks before suspend begins rather than during, [GitHub](https://github.com/i3/i3lock/issues/207) avoiding a different race.

**xsecurelock is the cleaner path for your failure surface.** Its composite-overlay-window (COW) obscurer design [Ubuntu](https://manpages.ubuntu.com/manpages/jammy/man1/xsecurelock.1.html) eliminates the --composite redraw-regression class by construction, its separate auth-helper process [GitHub](https://github.com/google/xsecurelock) prevents PAM-blocked-main-loop hangs, it does not fork (no silent-exit window), and it inherits upstream i3lock's XKB handling hygiene. What xsecurelock does **not** fix: the libinput LP #2087831 device wedge, i915 driver freezes, or NVIDIA pageflip timeouts — those are system-layer bugs unaffected by locker choice. Minimal migration from your existing xss-lock setup:

# ~/.config/i3/config
exec --no-startup-id xss-lock --transfer-sleep-lock -l -- \
env XSECURELOCK_PAM_SERVICE=common-auth \
XSECURELOCK_SAVER=saver_blank \
XSECURELOCK_AUTH_BACKGROUND_COLOR=#1e1e2e \
XSECURELOCK_SHOW_DATETIME=1 \
XSECURELOCK_BLANK_TIMEOUT=60 \
xsecurelock
bindsym $mod+l exec --no-startup-id loginctl lock-session

Ubuntu 24.04 ships xsecurelock 1.8.0 in universe with zero open Launchpad bugs against the Noble package.

One xss-lock/xautolock edge case to resolve before any of this matters: **do not run both**. Their idle triggers conflict — xautolock fires its locker, xss-lock's subsequent XGrabKeyboard returns AlreadyGrabbed, [Arch Linux Forums](https://bbs.archlinux.org/viewtopic.php?id=208699) xss-lock's child exits in failure, and on suspend XSS_SLEEP_LOCK_FD never closes, delaying or breaking the suspend transition. xss-lock does **not** fire on DPMS timeout directly; it binds to MIT-SCREEN-SAVER and logind events. [Arch Linux Forums](https://bbs.archlinux.org/viewtopic.php?id=187424) The correct idiom for idle-lock is xset s 300 30 (which drives xss-lock) alongside xset dpms 0 0 300, or drop DPMS and use only xset s. [ArchWiki](https://wiki.archlinux.org/title/Session_lock)

## Diagnostic playbook for the next time it wedges

Before changing anything, get SSH access from a second machine and enable full SysRq. **Ubuntu's default kernel.sysrq = 176 (0xB0) excludes the R and E/I bits** — without kernel.sysrq = 1 in /etc/sysctl.d/99-sysrq.conf the REISUB sequence is incomplete, which defeats the single most useful recovery tool.

When the system is wedged, run the triage sequence from SSH. export DISPLAY=:0; export XAUTHORITY=/run/user/$(id -u)/gdm/Xauthority first (or extract via ps -C Xorg -o args= | grep -oP '(?<=-auth )\S+'). Then test X liveness with timeout 3 xset q — if it returns promptly, X is alive and the problem is in the locker or display pipeline; if it times out, X itself is wedged and a locker swap cannot help. Check X's kernel state with ps -o pid,stat,wchan:32,cmd -p $(pgrep -x Xorg) and sudo cat /proc/$(pgrep -x Xorg)/stack: a wchan of i915_*, dma_fence_*, or drm_atomic_* with state D is an i915 KMS fence wait (driver freeze, no userspace recovery); wait_for_flip_done is the classic DPMS-wake signature; do_select/poll_schedule_timeout means X is idle and the locker is the culprit.

The decision tree mapping symptoms to root cause:

| Observation from SSH | Root cause | Recovery |
| --- | --- | --- |
| xset qhangs, X stack ini915_*/dma_fence_* | i915 DRM fence wedge (F1 class) | Wait for hangcheck GPU reset, or SysRq reboot. Applyi915.enable_psr=0. |
| xset qhangs, dmesg showsrcu_sched self-detected stallornvidia-modesetin backtrace | NVIDIA driver wedged kernel PM (F1/F3) | `echo b |
| xset qOK, "Monitor is Off",xset dpms force on→ visible | Benign DPMS timing race | Addi915.enable_fbc=0; apply wake-hook script. |
| xset qOK, monitor on, screen still black | CRTC scan-out stuck | xrandr --output <name> --off; --autounsticks; root cause i915 commit-wait. |
| xset qOK,xdotool key Returnworks, i3lock running but unresponsive | i3lock-color wedge (F2) | pkill -TERM i3lock; migrate to xsecurelock or apply fail-closed wrapper. |
| xset qOK, keyboard dead at console but xdotool works over SSH | libinput Send-Events wedge (F3) | xinput set-prop <id> "libinput Send Events Mode Enabled" 0 0; install resume hook. |
| SSH itself won't connect | Full kernel hang | PhysicalAlt+SysRq+R-E-I-S-U-B. |

For dmesg triage after any hang, grep for the signatures that map to cause: flip_done timed out or commit wait timed out indicate i915 atomic-path wedge; CPU pipe A FIFO underrun [Arch Linux Forums](https://bbs.archlinux.org/viewtopic.php?id=296149) correlates with PSR/FBC glitches; NVRM: Xid with codes 13/16/31/79 are NVIDIA faults (79 = fell off bus, PCIe power); PreserveVideoMemoryAllocations module parameter is set means the nvidia-suspend service wasn't active; rcu_sched self-detected stall or INFO: task Xorg:N blocked for more than 120 seconds are full kernel/driver freezes.

**Recovery escalation with actual effectiveness per failure class** — level 1 is DISPLAY=:0 xset dpms force on from SSH (fixes F1 when X is alive); level 2 is pkill -TERM xss-lock; pkill -TERM i3lock which closes the grabbing client's X socket and force-releases X grabs (this is the canonical fix for F2 and F3; **note pkill -USR1 i3lock does NOT unlock** — SIGUSR1 is image-reload in i3lock-color); level 3 is echo r | sudo tee /proc/sysrq-trigger from SSH, which unraws the kernel keyboard driver equivalently to physical Alt+SysRq+R, then chvt 2 switches to a TTY; level 4 is sudo systemctl restart gdm (loses session); level 5 is echo b | sudo tee /proc/sysrq-trigger or physical REISUB. Levels 1–4 do not help if the root cause is a DRM fence wait — the GPU reset hangcheck or reboot are the only paths.

For faster reproduction than waiting for idle, a short DPMS cycle loop from SSH is reliable:

bashexport DISPLAY=:0
for i in $(seq 1 50); do
echo "--- cycle $i $(date +%T) ---"
xset dpms force off
sleep $((RANDOM % 20 + 5))
xset dpms force on || { echo "X died at cycle $i"; break; }
sleep 3
xset q >/dev/null || { echo "X wedged at cycle $i"; break; }
done

Run this alongside stress-ng --cpu 4 --vm 2 --vm-bytes 1G --timeout 600 & and a glxgears & in the background to stress all three paths (CPU idle states, memory pressure, GPU submission) simultaneously. If the loop completes 50 cycles clean under stress after applying the GRUB and modprobe changes, your fixes held.

## Recommended apply order and stopping conditions

Apply changes in distinct phases, retesting between each, so you can attribute improvement. **Stage A** is the kernel/modprobe/systemd changes in the first configuration section above plus the resume-input-fix user service — apply all of these together because they are interlocking (the kernel params, the nvidia-drm modeset=0, and the nvidia-suspend services all presume each other). Reboot and run the reproduction loop. If all three failure modes disappear, stop.

**Stage B**, reached only if F2 (lock-never-draws) or the silent-exit race persists, is the i3lock-color fail-closed wrapper with --composite --ignore-empty-password --indicator. Retest. If F2 persists despite --composite, the fork's missing 2.16 XKB fix is likely biting — this is the signal to move to **Stage C**, migration to xsecurelock, which removes four failure modes (--composite regression, XKB reconfigure crash, silent-exit race, PAM-blocked-main-loop) at once with ten lines of config change.

**Stage D**, reached only if xset q from SSH still hangs after all of the above, means none of this is a locker or libinput problem — it is a pure i915 or NVIDIA driver freeze. Options at that point are narrow: upgrade to HWE kernel (linux-generic-hwe-24.04 currently tracks 6.11+, which has the fast-wake/ALPM backports that 6.8 is missing), test linux-lts 6.6 as a regression bisect reference, and capture /sys/kernel/debug/dri/0/i915_error_state for a drm bug report. For a compute workstation specifically, upgrading to HWE is low-risk and resolves a meaningful backlog of i915 atomic-path fixes that 6.8 does not have.

The conclusion under all this evidence: **keep i3lock-color if the Stage A driver fixes alone clear all three symptoms**, which they will for most configurations because the dominant root cause for F1 and F3 is driver-layer, not locker-layer. **Migrate to xsecurelock if Stage B leaves F2 intermittent** — the missing upstream 2.16 XKB fix makes the fork structurally risky for DPMS-heavy workflows, and xsecurelock's design eliminates the silent-unlock security hole that the fail-closed wrapper only patches around. Either way, do not run xautolock and xss-lock concurrently, and ensure kernel.sysrq = 1 is set before the next wedge so you can diagnose rather than hard-reboot.

---

*Extracted from Claude AI • Conversation ID: `e1511626-feba-40ae-b508-61695e8f10a0` • Date: 2026-04-17 • [View original](https://claude.ai/chat/e1511626-feba-40ae-b508-61695e8f10a0)*

*Edit and convert to PDF/DOC at [markdown.vc](https://markdown.vc)*