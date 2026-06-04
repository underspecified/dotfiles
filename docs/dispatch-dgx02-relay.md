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
   dgx02 (work-LAN only) │  resolves tank/germputer/llm-jp-2 by MagicDNS, then  │
                         │  forwards/connects over the tailnet (roam-proof)     │
   autossh -L 9101 ──────┼──► tank:8765        (MagicDNS-resolved on llm-jp)    │
   autossh -L 9102 ──────┼──► germputer:8765                                    │
   autossh -L 9103 ──────┼──► llm-jp-2:8765                                     │
   ssh ProxyJump llm-jp ─┼──► ssh <host>  (dispatch __resolve-identity + scp)   │
                         └──────────────────────────────────────────────────────┘
```

- **Leg A — HTTP buses: per-host LocalForwards.** One persistent `autossh -M0 -N
  -L …×3 llm-jp` (the `dispatch-tunnel.service` user unit). dgx02 hits
  `127.0.0.1:<port>`; llm-jp resolves the forward target by name and connects.
  NOT a SOCKS proxy with `ALL_PROXY` — dgx02's dispatch env is glob-sourced into
  the login shell, so an exported proxy would route *all* of dgx02's HTTP (HF model
  pulls, pip) through llm-jp. LocalForwards touch only the three ports.
- **Leg B — SSH: ProxyJump.** `relay.conf` sends `tank germputer llm-jp-2` through
  `ProxyJump llm-jp`, satisfying dispatch's `ssh <host>` identity hop (and giving
  general ssh/scp for free).

## Port map

| Local (dgx02) | → fleet bus | dispatch env |
|---|---|---|
| `127.0.0.1:9101` | `tank:8765` | `AGENT_MAIL_URL_TANK=http://127.0.0.1:9101/mcp/` |
| `127.0.0.1:9102` | `germputer:8765` | `AGENT_MAIL_URL_GERMPUTER=http://127.0.0.1:9102/mcp/` |
| `127.0.0.1:9103` | `llm-jp-2:8765` | `AGENT_MAIL_URL_LLM_JP_2=http://127.0.0.1:9103/mcp/` |
| (direct, no forward) | `llm-jp:8765` | `AGENT_MAIL_URL_LLM_JP=http://<llm-jp-lan-ip>:8765/mcp/` |
| (local bus) | `dgx02:18765` | `AGENT_MAIL_URL=http://127.0.0.1:18765/mcp/` |

Tokens (`AGENT_MAIL_TOKEN_<HOST>`) live beside these in untracked, chmod-600
`~/.config/dispatch/dgx02.env`, fetched per host over the ProxyJump ssh hop.

## Tracked vs. secret

| Where | What |
|---|---|
| Public mirror (`nosudo.lnk/`, `--host nosudo`) | `relay.conf` (names + auth params, **no IPs**), `dispatch-tunnel.service`, `installers/nosudo/install_autossh.sh` |
| 1Password (`ssh-config-honda` doc → `~/.ssh/config.d/honda`) | `Host llm-jp` with the secret **work-LAN HostName** |
| Untracked, chmod 600 (`~/.config/dispatch/dgx02.env`) | per-host bus URLs + **tokens** |

## Setup (dgx02)

1. `lnk pull --host nosudo` — lays down `relay.conf` + the tunnel unit.
2. `bash ~/.config/lnk/installers/nosudo/install_autossh.sh` (or a full nosudo
   re-run) — builds `~/.local/bin/autossh`.
3. Ensure the 1Password `ssh-config-honda` doc has `Host llm-jp` (HostName =
   llm-jp's work-LAN IP); re-pull: `bash ~/.config/lnk/installers/all/ssh-config-honda.sh`.
4. Write `~/.config/dispatch/dgx02.env` (URLs from the port map + a token per host).
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
- `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:9102/mcp/` → a bus
  response (e.g. 400/406), proving the forward reaches germputer's bus.
- `dispatch -C germputer:<dir> new` from dgx02 round-trips.
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
