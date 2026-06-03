# Tailscale Subnet Router (work LAN bridge)

One-time setup so isolated machines on the work LAN (e.g., `dgx02`, where Tailscale can't be installed) are reachable from the rest of the Tailnet via a bridge host. Today the bridge is **llm-jp**; this doc exists so the next time it has to move (rebuild, hardware swap, new bridge host) you can recreate it without rediscovering the steps.

## Topology

```
[Mac, anywhere] ────┐
                    │ Tailscale
[germputer, home] ──┤
                    │
                    ▼
              [llm-jp]            ← subnet router
            ┌────────┴────────┐
            │ Tailscale       │ work LAN (eno2, 172.24.40.6/24)
            ▼                 ▼
         Tailnet      172.24.40.0/24  ← llm-jp's subnet
                      172.24.36.0/24  ← dgx02 lives here
```

llm-jp has one foot on Tailscale and one foot on the work LAN. It advertises the work-LAN /24s to the Tailnet so other Tailscale nodes can reach hosts on those subnets via llm-jp as the gateway.

## Prerequisites

- The bridge host (llm-jp) has Tailscale already installed and logged in
- The bridge host has L3 reachability to all target subnets (verify with `ssh <bridge> -- ping -c 2 <target-on-other-subnet>`)
- You have access to the Tailscale admin console with permission to approve subnet routes

## Recipe

### 1. Enable IP forwarding on the bridge host

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

Persists across reboot.

### 2. Advertise the work-LAN subnets to the Tailnet

```bash
# Additive — `tailscale set` does NOT replace other prefs.
# Discover the local LAN CIDR(s) first with: ip -4 -o addr show
tailscale set --advertise-routes=172.24.40.0/24,172.24.36.0/24
```

To verify:

```bash
sudo tailscale debug prefs | grep -A3 AdvertiseRoutes
```

### 3. Approve the routes in the Tailscale admin console

Routes are **advertised but ignored** until approved per-route:

```
https://login.tailscale.com/admin/machines
→ click the bridge host (llm-jp)
→ "Edit route settings" (or "Subnets" — name varies by Tailscale UI version)
→ enable each advertised CIDR
→ Save
```

There is no CLI for this step; it's intentionally a deliberate approval surface.

### 4. Have consumers accept routes

On each Tailscale node that should reach those subnets (Mac, germputer, llm-jp-2, …):

```bash
# Linux:
sudo tailscale set --accept-routes

# macOS GUI:
#   menu bar → Tailscale → Preferences → "Use Tailscale subnets" → on
# or macOS CLI (Tailscale.app):
/Applications/Tailscale.app/Contents/MacOS/Tailscale set --accept-routes
```

Verify a new entry appears in the consumer's routing table:

```bash
# Linux:
ip route get 172.24.36.28   # should show "dev tailscale0"

# macOS:
netstat -rn -f inet | grep 172.24
```

### 5. Verify end-to-end

```bash
ping -c 2 172.24.36.28                  # the target on the other subnet
ssh dgx02.jp.honda-ri.com -- hostname   # full SSH path
```

## Notes

- **SNAT is on by default.** Targets on the work LAN see traffic as originating from the bridge host's work-LAN IP, not the original Tailscale source. Fine for HTTP/SSH; only matters if a target needs the true source IP (e.g., per-client ACLs).
- **Adding a new work subnet later** is the same recipe minus IP forwarding (already done): re-run `tailscale set --advertise-routes=...` with the full comma-separated list (it replaces the route list), then approve the new one in the admin console.
- **DNS does not follow the route.** Consumer machines off the work LAN won't be able to resolve `*.jp.honda-ri.com`. Pin internal hostnames to IPs in `~/.ssh/config.d/honda` via `bash installers/all/ssh-config-honda.sh` (pulls the `ssh-config-honda` 1Password document).
- **Bridge host downtime = subnet downtime.** Keep llm-jp on UPS; or, if reliability matters more, designate a second bridge by repeating this recipe on another work-LAN Tailscale node.
