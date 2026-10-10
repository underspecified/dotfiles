---
name: warn-argv-secrets
enabled: true
event: bash
action: warn
pattern: \bps\s+(aux|axu|-[a-zA-Z]*e[a-zA-Z]*f|[^|;&]*-[a-zA-Z]*o\s*\S*(args|command|cmd))|\bpgrep(\s+[^|;&]*)?\s-[a-zA-Z]*(a|l[a-zA-Z]*f|f[a-zA-Z]*l)|/proc/[^/\s]+/cmdline|\bsystemctl\s+(--user\s+)?(cat|status)\b|\bdocker\s+(container\s+)?inspect\b|--no-trunc
---

**This command prints full argv, and argv can hold secrets.**

On 10/10, a full `ps` on llm-jp-2 printed a cloudflared `--token` into a session log. Print the pid and the name instead (`ps -eo pid,user,comm`, `pgrep -l`), or redact the args. See `~/.claude/rules/safety.md`, § Secrets in Diagnostic Output.
