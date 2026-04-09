---
name: block-rm-commands
enabled: true
event: bash
action: block
conditions:
  - field: command
    operator: regex_match
    pattern: \brm\s
  - field: command
    operator: not_contains
    pattern: /tmp/
  - field: command
    operator: not_contains
    pattern: /scratchpad/
---

**rm command blocked**

`rm` is only allowed in scratch directories:
- `/tmp/*` - System temp
- `/private/tmp/claude-*/scratchpad/*` - Claude scratchpad
- `~/claude/skills/research/tmp/*` - Project temp

Use `paper_manager.py cleanup` for staging directories.
Use `trash` for recoverable deletion.
