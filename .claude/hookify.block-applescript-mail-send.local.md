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

**Mail is saved as a draft, never sent and never opened in a window** (`~/.claude/rules/email.md`):

1. **New mail:** `mcp__apple-mail-patrickfreyer__compose_email` with `mode: "draft"`. Eric sends it from Drafts.
2. **Reply:** until email-inbox#16 lands, write the reply to a file in the seat's repo and report the path.
3. **`compose_email` not loaded:** tell the user, and write the mail to a file. No AppleScript fallback: it opens a window.

Note: this hook can only inspect the bash command string. AppleScript inside a `.applescript` file invoked as `osascript path/to/file.applescript` will not be visible to the matcher — the spirit of the rule (no programmatic `send`) still applies; do not author such files.
