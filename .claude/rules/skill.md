# Skill Conventions

## Canonical Directory Layout

Only `SKILL.md` is required:

```
skill-name/
+-- SKILL.md          # Execution plan -- the skill definition
+-- CLAUDE.md         # Project guidance for Claude working inside this skill
+-- README.md         # User-facing docs
+-- scripts/          # Python (.py) and Bash (.sh) scripts
+-- templates/        # Output templates (reports, slides, etc.)
+-- schemas/          # JSON schemas for data validation
```

Prefer flat directories.

## Dev vs Deploy

`~/.claude/skills/<name>` is a **deploy tree**, not a workspace. Every session
reads `SKILL.md` from it and `~/.local/bin` entry points symlink into it, so
whatever is checked out is what runs, everywhere, immediately.

- **Deploy trees stay on `main`, clean, and in sync.** No feature branches, no
  in-place edits, no detached HEAD.
- **Develop in a separate checkout** (`~/git/claude/skills/<name>`), or a git
  worktree off the same repo, and land changes through `main`.
- **Never edit a script the box is currently executing.** Bash reads scripts
  incrementally by byte offset, so an in-place write to a running script can
  make it execute garbage. Write via temp-file + `mv` so the inode is replaced.
- **Check with `bash ~/.claude/skills/bootstrap.sh --doctor`.** Read-only; exits
  non-zero on drift. Drift here is silent by construction — a repo left on a
  feature branch keeps working until the branch is deleted.

## Skill Types

- **Leaf**: Execute work directly with Read/Write/Bash
- **Orchestrator**: Route to sub-skills via `Skill(sub-skill-name)`
- **Hybrid**: Both execute and orchestrate via `Skill(computation-graph)`

## SKILL.md Frontmatter

Required fields: `name`, `description`, `allowed-tools`. Optional: `argument-hint`, `clear-context`.

```yaml
---
name: skill-name
description: One-line description for the skill picker UI.
argument-hint: "<required_arg> [optional_arg] [--flag]"
clear-context: before
allowed-tools:
  - Bash(~/claude/skills/skill-name/scripts/*.py)
  - Bash(~/claude/skills/skill-name/scripts/*.py *)
  - Bash(~/claude/skills/skill-name/scripts/*.sh)
  - Bash(~/claude/skills/skill-name/scripts/*.sh *)
  - Read
  - Write
  - Skill(computation-graph)
---
```

## Dual-Variant Rule

Every script needs two `allowed-tools` entries -- one without args and one with args:

```yaml
- Bash(~/claude/skills/skill-name/scripts/run.sh)
- Bash(~/claude/skills/skill-name/scripts/run.sh *)
```

For system commands, use the colon syntax: `Bash(jq:*)`, `Bash(uv:*)`.

## Computation-Graph Parallelism

The `{parallel}` marker on a parent means its children run concurrently; the parent acts as a gate (completes when all children complete). Without the marker, children execute sequentially:

```markdown
- [ ] Sequential step
- [ ] Batch processing {parallel}
  - [ ] Child A (concurrent)
  - [ ] Child B (concurrent)
- [ ] Next step waits for batch to finish
```

Task item syntax:
- `/skill-name args` -- skill invocation
- `$ command` or `` `command` `` -- Bash execution
- Plain text -- general-purpose agent instructions
