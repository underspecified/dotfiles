# ~/.claude

Claude Code user configuration directory. It contains settings, hooks, plugins, custom skills, agents, commands, and status line customizations. This is NOT a code project — it is the config layer that governs how Claude Code behaves across all projects.

## Directory Structure

- **`settings.json`** — Global settings: permissions, hooks, enabled plugins, env vars, status line config
- **`hooks/`** — Shell-based hooks that intercept tool usage (PreToolUse/PostToolUse)
- **`skills/`** — Symlinks to `~/claude/skills/` (research, presentation, gantt-chart, hansei, computation-graph, etc.)
- **`commands/`** — Slash command definitions (`.md` files): research workflows, grammar checker, fact checker, video captioner, etc.
- **`agents/`** — Custom agent definitions (currently `dont-ask.md` symlinked from research skills)
- **`plugins/`** — Plugin marketplace cache (`plugins/marketplaces/claude-plugins-official/`)
- **`hookify.*.local.md`** — Hookify safety rules (block force push, restrict `rm`, warn on destructive git)
- **`claude-limitline-fork/`** — Custom Node.js status line (fork of claude-limitline), configured via `claude-limitline.json`
- **`projects/`** — Per-project settings and session data (directory names are path-encoded)
- **`plans/`**, **`todos/`**, **`tasks/`**, **`teams/`** — Agent coordination state
- **`rules/`** — Convention files auto-loaded into every session (python, bash, markdown, skill, authoring, safety)

## PostToolUse Hooks

- **Python files**: Auto-formatted with `ruff format` after Write/Edit
- **Markdown/QMD files**: Auto-linted with `rumdl` after Write/Edit

## Enabled Plugins

- `pyright-lsp` and `typescript-lsp` — Language server support
- `code-simplifier` — Code simplification agent
- `hookify` — Safety rule management
- `commit-commands` — Git commit/push/PR workflows
- `security-guidance` — Security hook enforcement
- `explanatory-output-style` — Educational insight formatting

## Skills Architecture

Skills in `skills/` are symlinks to `~/claude/skills/<name>`. The research skill suite includes: research, research-download, research-summarize, research-review, research-survey, research-profile, research-queue, research-inbox, research-audit. Other skills: gantt-chart, presentation, hansei (retrospectives), computation-graph.

## Status Line

**`claude-limitline-fork/`** — Node.js-based (active via settings.json): uses selenized-light theme, tracks context window with warning/critical thresholds (60%/85%)

## Environment

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is enabled globally
- Always-thinking mode is enabled (`alwaysThinkingEnabled: true`)
