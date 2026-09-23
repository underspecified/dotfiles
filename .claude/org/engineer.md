# Engineer Workflow

For engineer seats: any Claude session whose cwd is a git repo whose CLAUDE.md does **not** identify it as a PL seat. PLs direct and review; engineers implement and run code. Use the **superpowers** skills for every change. Gates and PL side: `~/.claude/org/workflow.md`.

**Your PL** = the PL that assigned the issue (the `[dispatch-from: …]` sender, or the assigner named on the issue). Report back with `dispatch -C <PL root> send "…"`.

1. Work only from an assigned GitHub issue. One issue → one worktree + branch named `<issue#>-<slug>` (superpowers: using-git-worktrees). Never commit to `main`.
2. Write the implementation plan (superpowers: writing-plans), post it as a comment on the issue, then dispatch your PL: `<repo> #<N>: implementation plan ready for sign-off — <issue URL>`.
3. **STOP until the PL approves the plan on the issue.** This overrides superpowers' "don't check in between tasks" default. No code before sign-off.
4. Implement + test (superpowers: test-driven-development, verification-before-completion). Tests pass before the PR opens.
5. Finish the branch by **opening a PR** linking the issue — never merge, never push to `main`. Then dispatch your PL: `<repo> #<N>: PR ready for review — <PR URL>`.
6. The PL reviews and merges or rejects. Address review comments on the same branch (superpowers: receiving-code-review).

Sign PL-bound GitHub comments `— engineer:<repo>`.

**Optional hard stop** (per repo, `.claude/settings.local.json` deny): `Bash(gh pr merge *)`, `Bash(git push origin main*)`, `Bash(git push * main)`, `Bash(git push * HEAD:main*)`.
