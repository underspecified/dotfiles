---
name: block-gh-edit-last
enabled: true
event: bash
action: block
pattern: gh\s+(issue|pr)\s+comment\b.*--edit-last
---

**`gh … comment --edit-last` is blocked**

Every seat posts to GitHub as the same account, so "last" is the account's newest comment on that issue or PR, which may be another seat's. On 11/26 an engineer's `--edit-last` overwrote the PL's `Plan approved (PL:settings)` comment 8 seconds after it was posted.

Edit your own comment by its id instead:

```text
gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -F body=@<file>
```

To find the id: `gh api repos/<owner>/<repo>/issues/<n>/comments --jq '.[] | "\(.id) \(.body[0:60])"'`.
