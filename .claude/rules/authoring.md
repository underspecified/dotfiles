# Authoring Conventions

## Naming

- **Skills, commands, agents, rules**: kebab-case (`research-download`, `block-force-push`)
- **Hookify rules**: `hookify.{name}.local.md` (e.g., `hookify.block-rm.local.md`)
- **Research papers**: `YEAR_FirstAuthorLastName_VENUE.{pdf,md}` -- normalize author to ASCII for filenames, keep accents in summaries. Collision handling: add co-author (`YEAR_First-Second_VENUE`), then suffix `_b` (no `_a` -- base name is implicitly first)

## Commands

Frontmatter fields: `name`, `description`, `argument-hint`, `allowed-tools`, `model`, optionally `disable-model-invocation`, `skills`.

Dynamic context injection: `` !`git status` `` embeds live command output.

Argument substitution: `$ARGUMENTS` (all args), `$1`/`$2`/`$3` (positional).

## Agents

Key fields: `name`, `description`, `tools`/`allowed-tools`, `model`, `color`, `permissionMode` (`dontAsk`/`ask`/`default`).

Description should use trigger patterns ("Use this agent when...") with `<example>` blocks showing context, user message, assistant response, and `<commentary>` explaining why the agent is appropriate.

## Hookify Rules

Frontmatter format with either `pattern` (simple regex) or `conditions` (multi-field):

```yaml
---
name: block-example
enabled: true
event: bash | file | stop | prompt | all
action: block | warn
pattern: regex-pattern
---
Block/warn message shown to user
```

Multi-field conditions use `field` + `operator` + `pattern`:
- **Operators**: `regex_match`, `contains`, `not_contains`
- **Event fields**: `bash` exposes `command`, `file` exposes `file_path`/`new_text`, `stop` exposes `transcript`, `prompt` exposes `prompt`

## Doc Updates

**Update** CLAUDE.md/README.md when changes affect: directory structure, scripts, dependencies, interfaces, how tools/skills/commands/agents function.

**Skip** updates for: prose changes, code under active development, minor/non-structural changes, internal refactoring that doesn't change interfaces.
