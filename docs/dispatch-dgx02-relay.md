# dgx02 ↔ fleet dispatch relay (via llm-jp)

Companion to `tailscale-subnet-router.md`. That doc covers **fleet → dgx02**
(inbound, via llm-jp's subnet router). This one covers **dgx02 → fleet**
(outbound) — the other half of full dispatch messaging for the one box that
can't join the tailnet.

## Why a relay at all

dgx02 is permanently network-isolated and that won't change:

- **No Tailscale** — against network policy *and* the control plane is blocked
  (`controlplane/login/derp.tailscale.com:443` unreachable from dgx02).
- **No sudo** — can't `chsh`, add a route, or create a TUN device. No transparent
  routing of any kind.
- **Reaches only llm-jp** — dgx02 is on work-LAN `172.24.36`; `.36↔.40` (llm-jp) is
  open, `.36↔.53` (llm-jp-2) is firewalled, germputer is on a home net, the tailnet
  is unrouted.

llm-jp is therefore the **sole bridge**: dgx02 reaches it on the work LAN, and it
(the one node with Tailscale) reaches the whole fleet by stable MagicDNS name. We
push everything through llm-jp and address the fleet by **name**, so it survives
the fleet roaming (TANK's laptop IP changes; `tank`/its `100.x` do not).

## Architecture — two legs, both through llm-jp

```
                         ┌───────────────── llm-jp (Tailscale) ─────────────────┐
   dgx02 (work-LAN only) │  resolves tank/germputer/llm-jp-2 by MagicDNS        │
                         │  (roam-proof); is itself reached directly on the LAN  │
   autossh ssh tank ─────┼─► tank      : -L 9101 → its localhost:8765 (raw bus) │
   autossh ssh germputer ┼─► germputer : -L 9102 → its localhost:8765           │
   autossh ssh llm-jp-2 ─┼─► llm-jp-2  : -L 9103 → its localhost:8765           │
   autossh ssh llm-jp ───┼─► llm-jp    : -L 9104 → its localhost:8765 (direct)  │
   ssh ProxyJump llm-jp ─┼─► ssh <host>  (dispatch __resolve-identity + scp)    │
                         └──────────────────────────────────────────────────────┘
```

**Why forward to the receiver's `localhost:8765`, not `<host>:8765`:** the tailnet
`<host>:8765` is **Tailscale Serve (HTTPS)** in front of the raw HTTP bus, which
binds `127.0.0.1:8765`. A raw TCP forward + `http://` to `<host>:8765` hits Serve's
TLS and returns `400`. Forwarding to the receiver's loopback bus (over an
`ssh <host>` whose TCP exit *is* that host) reaches the raw bus directly — and,
being loopback on the receiver, every call is auto-promoted/tokenless
(`HTTP_ALLOW_LOCALHOST_UNAUTHENTICATED`). **No per-host tokens to manage.**

- **Leg A — HTTP buses: per-host LocalForwards** (`~/.local/bin/dispatch-tunnels`,
  one `autossh` per host, under `dispatch-tunnel.service`). NOT a SOCKS proxy with
  `ALL_PROXY` — dgx02's dispatch env is glob-sourced into the login shell, so an
  exported proxy would route *all* of dgx02's HTTP (HF pulls, pip) through llm-jp.
- **Leg B — SSH: ProxyJump.** `relay.conf` sends `tank germputer llm-jp-2` through
  `ProxyJump llm-jp`, satisfying dispatch's `ssh <host>` identity hop (and giving
  general ssh/scp for free). It also carries each Leg-A tunnel.

## Port map

All forwards target the receiver's loopback bus (`localhost:8765`); all are
tokenless. dgx02's own bus is unchanged.

| Local (dgx02) | ssh to | → its bus | dispatch env |
|---|---|---|---|
| `127.0.0.1:9101` | tank (ProxyJump) | `localhost:8765` | `AGENT_MAIL_URL_TANK=http://127.0.0.1:9101/mcp/` |
| `127.0.0.1:9102` | germputer (ProxyJump) | `localhost:8765` | `AGENT_MAIL_URL_GERMPUTER=http://127.0.0.1:9102/mcp/` |
| `127.0.0.1:9103` | llm-jp-2 (ProxyJump) | `localhost:8765` | `AGENT_MAIL_URL_LLM_JP_2=http://127.0.0.1:9103/mcp/` |
| `127.0.0.1:9104` | llm-jp (direct) | `localhost:8765` | `AGENT_MAIL_URL_LLM_JP=http://127.0.0.1:9104/mcp/` |
| (local bus) | — | `dgx02:18765` | `AGENT_MAIL_URL=http://127.0.0.1:18765/mcp/` |

These four `AGENT_MAIL_URL_<HOST>` lines live in untracked, chmod-600
`~/.config/dispatch/dgx02.env` (names + localhost ports — no secrets, no tokens).

## Tracked vs. secret

| Where | What |
|---|---|
| Public mirror (`nosudo.lnk/`, `--host nosudo`) | `relay.conf` (names + auth params, **no IPs**), `dispatch-tunnels` wrapper, `dispatch-tunnel.service`, `installers/nosudo/install_autossh.sh` |
| dgx02-local, untracked (`~/.ssh/config.d/relay-local.conf`) | `Host llm-jp` with its **work-LAN HostName** — kept off the public mirror AND off the shared honda doc (a HostName override there would force the work-LAN IP on roaming machines like tank) |
| Untracked, chmod 600 (`~/.config/dispatch/dgx02.env`) | the four loopback bus URLs (names + ports, **no tokens** — loopback forwards are auto-promoted) |

## Setup (dgx02)

1. `lnk pull --host nosudo` — lays down `relay.conf`, the `dispatch-tunnels`
   wrapper, and the tunnel unit.
2. `bash ~/.config/lnk/installers/nosudo/install_autossh.sh` (or a full nosudo
   re-run) — builds `~/.local/bin/autossh`.
3. Create the dgx02-local `~/.ssh/config.d/relay-local.conf` with
   `Host llm-jp` / `HostName <llm-jp work-LAN IP>` (chmod 600). This supplies the
   one IP the relay needs; `relay.conf` supplies User/IdentityFile.
4. Write `~/.config/dispatch/dgx02.env` with the four `AGENT_MAIL_URL_<HOST>`
   loopback URLs from the port map (no tokens).
5. Start the tunnel:
   ```
   loginctl enable-linger "$USER"
   systemctl --user daemon-reload
   systemctl --user enable --now dispatch-tunnel.service
   ```
   If lingering is denied, fall back to running the `autossh …` line from
   `dispatch-tunnel.service` inside a named tmux session.

## Verify

- `ssh -G germputer` on dgx02 → shows `proxyjump llm-jp`.
- `ssh germputer hostname` → `germputer` (ProxyJump auth chain; needs hri_jp).
- with the tunnels up, `dispatch -C germputer:<dir> new` from dgx02 round-trips
  (returns the inbox, e.g. `(empty)` for a fresh dir) — proves the loopback
  forward + ProxyJump `__resolve-identity` + tokenless bus read all work.
- `systemctl --user status dispatch-tunnel` → active; kill the autossh process and
  confirm `Restart=always` brings it back.

## Notes / gotchas

- **hri_jp must be authorized fleet-wide** (it is, verified): `relay.conf` offers it
  explicitly because non-interactive contexts have no agent.
- **Roam resilience**: when TANK moves networks, nothing on dgx02 changes — llm-jp
  re-resolves `tank` by MagicDNS at the next connect.
- **No pollution**: there is no `ALL_PROXY`; dgx02's HF/pip/curl traffic is untouched.
- **autossh upstream**: built from `www.harding.motd.ca` (reachable from dgx02). If
  ever blocked, build on llm-jp and `scp` the binary to `dgx02:~/.local/bin/`.
