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
