---
name: block-applescript-mail-send
enabled: true
event: bash
action: block
conditions:
  - field: command
    operator: contains
    pattern: osascript
  - field: command
    operator: contains
    pattern: tell application "Mail"
  - field: command
    operator: regex_match
    pattern: \bsend\s+\w
---

**AppleScript Mail.app `send` is blocked**

Sending mail via raw AppleScript (`tell application "Mail" ... send newMsg`) is a silent destructive action: no compose-window confirmation, no Sent-folder write race signal, indistinguishable from a silent failure. The 2026-05-20 HRI Forum dispatch incident triggered this guardrail.

**Allowed paths for outgoing mail:**

1. **Preferred — MCP**: `mcp__apple-mail-patrickfreyer__compose_email` with `mode: "open"`. Compose window appears for user review.
2. **Reply (threaded)**: `bash ~/.claude/skills/email-inbox/scripts/threaded_reply.sh ...` — opens a visible draft via `reply ... with opening window`. No `send` action.
3. **AppleScript fallback (MCP unavailable)**: use the visible-draft form — `make new outgoing message with properties {visible:true, ...}`. NEVER append a `send` action. The user clicks send in Mail.app.

**If the MCP `compose_email` tool is not loaded in this session:** surface the gap to the user BEFORE pursuing a workaround. The user decides whether to wait/restart the MCP or accept the visible-draft fallback. See `~/.claude/skills/email-inbox/CLAUDE.md` for the alert protocol.

Note: this hook can only inspect the bash command string. AppleScript inside a `.applescript` file invoked as `osascript path/to/file.applescript` will not be visible to the matcher — the spirit of the rule (no programmatic `send`) still applies; do not author such files.
