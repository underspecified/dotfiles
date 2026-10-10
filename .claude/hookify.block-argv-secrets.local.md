---
name: block-argv-secrets
enabled: true
event: bash
action: block
conditions:
  - field: command
    operator: regex_match
    pattern: \bps\s+(aux|axu|-[a-zA-Z]*e[a-zA-Z]*f|[^|;&]*-[a-zA-Z]*o\s*\S*(args|command|cmd))|\bpgrep(\s+[^|;&]*)?\s-[a-zA-Z]*(a|l[a-zA-Z]*f|f[a-zA-Z]*l)|/proc/[^/\s]+/cmdline|\bsystemctl\s+(--user\s+)?(cat|status)\b|\bsystemctl\s+(--user\s+)?show\b(?![^|;&]*\s(-p|--property)[=\s])|\bdocker\s+(container\s+)?inspect\b(?![^|;&]*\s(--format|-f)[=\s])|\bdocker\s+(container\s+)?inspect\b[^|;&]*\.(Config|Env|Cmd|Args|Entrypoint|Path)\b|--no-trunc
  - field: command
    operator: not_contains
    pattern: argv-ok
---

**Blocked: this command prints full argv, and argv can hold secrets.**

On 10/10, a full `ps` on llm-jp-2 printed a cloudflared `--token` into a session log, and session logs are plaintext on disk.

Use a safe form instead:

- pid and name only: `ps -eo pid,user,comm`, `pgrep -l <name>`
- or redact the args: `... | sed -E 's/(--?(token|password|secret|api[-_]?key)[= ])[^ ]+/\1<redacted>/g'`
- for `docker inspect`, ask for the field you need: `--format '{{.State.Status}}'` (not `Config`, `Env`, `Cmd` or `Args`)
- for a unit: `systemctl is-active <unit>`, `systemctl show -p ActiveState,MainPID <unit>`

If you've checked that the full output holds no secret, re-run the same command with `# argv-ok` appended. See `~/.claude/rules/safety.md`, § Secrets in Diagnostic Output.
