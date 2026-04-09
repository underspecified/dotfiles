---
name: block-force-push
enabled: true
event: bash
action: block
pattern: git\s+push\s+.*--force|git\s+push\s+-f
---

**Force push blocked**

`git push --force` is not allowed. Use:
- `git push --force-with-lease` (safer alternative)
- Or push normally after rebasing
