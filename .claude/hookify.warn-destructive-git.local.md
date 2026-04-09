---
name: warn-destructive-git
enabled: true
event: bash
action: warn
pattern: git\s+(clean|reset\s+--hard|checkout\s+\.)
---

**Destructive git command - confirm before proceeding**

This command may discard uncommitted changes:
- `git clean` - Removes untracked files
- `git reset --hard` - Discards all uncommitted changes
- `git checkout .` - Reverts all modified files

Consider: `git stash` to save changes first.
