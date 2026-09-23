# Workflow

How a change goes from idea to merge. Two gates: Eric approves the **issue plan** (what + why); the PL approves the **implementation plan** (how) and the code. PLs direct; engineers implement and run code — **PLs never implement or run code themselves.**

Engineer-side steps: `~/.claude/org/engineer.md`.

## Issue plan

Every change goes through a plan. Eric reads every plan. The constraint that makes this work: **plans are ≤2 pages, scannable in ~60 seconds**, landing at _approach + acceptance criteria_ (not implementation specifics).

- **Problem** — what, why now
- **Approach** — the load-bearing decision
- **Alternatives considered** — briefly
- **Risks**
- **Success criteria**
- **Test plan**
- **Interested parties** — who consulted + their feedback

## Gate 1 — issue plan (Eric)

1. PL drafts the plan as a GitHub issue with the `plan` label in the implementing repo (cross-repo plans: markdown in the PL's planning hub).
2. PL dispatches to interested parties. IPs respond within 24h or PL ships with "no IP feedback received."
3. PL pings Eric with the plan-issue link.
4. Eric reacts 👍 to approve, or comments to revise.

## Gate 2 — implementation (PL)

| Step | Who | What |
|------|-----|------|
| 1. Assign | PL | dispatch the repo's engineer seat the issue URL |
| 2. Worktree + branch | Engineer | `<issue#>-<slug>`, never `main` |
| 3. Implementation plan | Engineer | superpowers plan posted on the issue; dispatches PL |
| 4. **Sign-off** | PL | 👍 or revise comment on the issue — no code before this |
| 5. Implement + test | Engineer | TDD; tests pass before the PR opens |
| 6. PR | Engineer | links the issue; never merges; dispatches PL |
| 7. **Code review** | PL | `/code-review --comment` against the plan's success criteria |
| 8. Merge or reject | PL | merge, or close with the reason on the issue |

Eric occasionally spot-checks one merged PR per PL per week to calibrate trust.

## Escalation

Engineer disagrees with PL → revise. Engineer thinks PL is wrong → escalate to Eric.
